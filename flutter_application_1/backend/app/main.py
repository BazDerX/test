import asyncio
import contextlib
import hashlib
import io
import secrets
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends, File, Form, UploadFile, Header, Request
from fastapi.responses import JSONResponse, FileResponse, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException
from PIL import Image
from .core.config import Settings
from .core.database import Database
from .core.errors import ServiceError
from .models.schemas import SegmentRequest, RemovalRequest, GenerateRequest, ProjectRequest, ImageMetadata, RoomUploadResponse, JobResponse, ProjectResponse
from .services.image_storage_service import ImageStorageService
from .services.model_runtime import ModelRuntime
from .services.segmentation_service import ObjectSegmentationService
from .services.furniture_removal_service import FurnitureRemovalService
from .services.interior_generation_service import InteriorGenerationService
from .services.job_service import JobService


def create_app(settings=None):
    cfg = settings or Settings()
    db = Database(cfg.data_dir)
    tokens = cfg.tokens()
    images = ImageStorageService(cfg, db)
    runtime = ModelRuntime(cfg)
    segmentation = ObjectSegmentationService(runtime)
    removal = FurnitureRemovalService(runtime)
    generation = InteriorGenerationService(runtime)
    jobs = JobService(db, images, generation, removal)

    @asynccontextmanager
    async def lifespan(app):
        task = asyncio.create_task(jobs.run())
        yield
        task.cancel()
        with contextlib.suppress(asyncio.CancelledError):
            await task

    app = FastAPI(title='SANAA Interior Design', version='1.0.0', lifespan=lifespan)
    app.state.db, app.state.images, app.state.runtime = db, images, runtime
    app.state.jobs = jobs
    app.add_middleware(CORSMiddleware, allow_origins=cfg.cors_origins.split(','), allow_methods=['GET', 'POST'], allow_headers=['Authorization', 'Content-Type'])

    @app.exception_handler(ServiceError)
    async def service_error(request, error):
        return JSONResponse(status_code=error.status, content={'error': {'code': error.code, 'message': error.message}})

    @app.exception_handler(RequestValidationError)
    async def validation_error(request, error):
        return JSONResponse(status_code=422, content={'error': {'code': 'validation_error', 'message': 'Хүсэлтийн утгуудыг шалгана уу.', 'fields': [dict(location=list(e['loc']), message=e['msg']) for e in error.errors()]}})

    @app.exception_handler(HTTPException)
    async def http_error(request, error):
        return JSONResponse(status_code=error.status_code, content={'error': {'code': 'http_error', 'message': error.detail if isinstance(error.detail, str) else 'Хүсэлтийг гүйцэтгэж чадсангүй.'}})

    @app.exception_handler(Exception)
    async def unexpected_error(request, error):
        logging.getLogger(__name__).error('Unhandled backend error', exc_info=error)
        return JSONResponse(status_code=500, content={'error': {'code': 'server_error', 'message': 'Серверт алдаа гарлаа. Дахин оролдоно уу.'}})

    @app.middleware('http')
    async def limit_body(request: Request, call_next):
        maximum = cfg.max_upload_bytes + 1024 * 1024
        content_length = request.headers.get('content-length')
        if content_length and (not content_length.isdigit() or int(content_length) > maximum):
            return JSONResponse(status_code=413, content={'error': {'code': 'body_too_large', 'message': 'Хүсэлтийн хэмжээ хэтэрсэн.'}})
        receive = request._receive
        total = 0
        async def limited_receive():
            nonlocal total
            message = await receive()
            total += len(message.get('body', b''))
            if total > maximum:
                raise HTTPException(413, 'Хүсэлтийн хэмжээ хэтэрсэн.')
            return message
        request._receive = limited_receive
        try:
            return await call_next(request)
        except ServiceError as error:
            return await service_error(request, error)

    def owner(authorization: str | None = Header(default=None)):
        token = authorization[7:] if authorization and authorization.startswith('Bearer ') else ''
        if not token or not any(secrets.compare_digest(token, allowed) for allowed in tokens):
            raise ServiceError(401, 'unauthorized', 'Серверийн хандалтын түлхүүр шаардлагатай.')
        return hashlib.sha256(token.encode()).hexdigest()

    async def upload_bytes(file):
        raw = await file.read(cfg.max_upload_bytes + 1)
        await file.close()
        return raw

    @app.get('/health')
    def health():
        return {'status': 'ok', 'capabilities': runtime.capabilities(), 'job_execution': 'sqlite_single_worker', 'automatic_upload': False}

    @app.post('/api/rooms', status_code=201, response_model=RoomUploadResponse)
    async def upload_room(file: UploadFile = File(...), user=Depends(owner)):
        image = images.decode(await upload_bytes(file))
        room = db.put(user, 'room', {})
        asset = images.save(user, image, 'source', room['id'])
        quality = images.quality(image)
        db.update(room['id'], user, image_id=asset['id'], quality=quality)
        return dict(room_id=room['id'], image=asset, quality=quality)

    @app.post('/api/masks', status_code=201, response_model=ImageMetadata)
    async def manual_mask(room_id: str = Form(...), image_id: str = Form(...), file: UploadFile = File(...), user=Depends(owner)):
        record, source = images.source(room_id, user, image_id)
        mask = images.decode(await upload_bytes(file), mask=True)
        if source.size != mask.size:
            raise ServiceError(422, 'mask_dimensions', 'Маск эх зургийн хэмжээтэй ижил байх ёстой.')
        mask = mask.point(lambda value: 255 if value > 127 else 0)
        if not mask.getbbox():
            raise ServiceError(422, 'empty_mask', 'Маск хоосон байна.')
        return images.save(user, mask, 'mask', room_id, {'image_id': record['id'], 'method': 'manual'})

    @app.post('/api/segment', status_code=201, response_model=ImageMetadata)
    def segment(request: SegmentRequest, user=Depends(owner)):
        record, source = images.source(request.room_id, user, request.image_id)
        try:
            mask, score = segmentation.segment(source, request.point, request.box)
        except ServiceError:
            raise
        except Exception as error:
            raise ServiceError(503, 'segmentation_failed', 'SAM 2 загвар ажилласангүй. Жин, тохиргоо болон санах ойг шалгана уу.') from error
        return images.save(user, mask, 'mask', request.room_id, {'image_id': record['id'], 'method': 'sam2', 'score': score})

    @app.post('/api/remove-furniture', status_code=201, response_model=ImageMetadata)
    def remove_furniture(request: RemovalRequest, user=Depends(owner)):
        record, source = images.source(request.room_id, user, request.image_id)
        mask = images.combine_masks(request.room_id, user, record, request.mask_ids, request.dilation)
        runtime.require('removal')
        try:
            cleaned, parameters = removal.remove(source, mask, request.seed)
        except ServiceError:
            raise
        except Exception as error:
            raise ServiceError(503, 'inpainting_failed', 'Тавилга арилгах загвар ажилласангүй. Загварын тохиргоо болон санах ойг шалгана уу.') from error
        parameters.update(source_image_id=record['id'], mask_ids=request.mask_ids, dilation=request.dilation)
        return images.save(user, cleaned, 'cleaned', request.room_id, parameters)

    @app.post('/api/generate', status_code=202, response_model=JobResponse)
    def generate(request: GenerateRequest, user=Depends(owner)):
        record, _ = images.source(request.room_id, user, request.image_id)
        if request.mask_ids:
            images.combine_masks(request.room_id, user, record, request.mask_ids)
            runtime.require('removal')
        runtime.require('generation')
        runtime.diffusion_device()
        active = [j for j in db.list(user, 'job') if j['status'] in {'queued', 'running'}]
        if len(active) >= 2:
            raise ServiceError(429, 'queue_limit', 'Өмнөх ажлаа дуусахыг хүлээнэ үү.')
        return db.put(user, 'job', dict(status='queued', progress=None, request=request.model_dump(), output_image_id=None, error=None, message='Дараалалд байна.'))

    @app.get('/api/jobs/{job_id}', response_model=JobResponse)
    def get_job(job_id: str, user=Depends(owner)):
        return db.get(job_id, user, 'job')

    @app.post('/api/jobs/{job_id}/cancel', response_model=JobResponse)
    def cancel_job(job_id: str, user=Depends(owner)):
        job = db.get(job_id, user, 'job')
        if job['status'] in {'queued', 'running'}:
            db.update(job_id, user, status='cancelled', progress=None, message='Цуцалсан.')
        return db.get(job_id, user, 'job')

    @app.get('/api/images/{image_id}')
    def get_image(image_id: str, overlay: bool = False, user=Depends(owner)):
        record = db.get(image_id, user, 'image')
        if overlay and record['kind'] == 'mask':
            _, mask = images.load(image_id, user)
            rgba = Image.new('RGBA', mask.size, (49, 92, 71, 0))
            rgba.putalpha(mask.convert('L').point(lambda v: int(v * .45)))
            output = io.BytesIO()
            rgba.save(output, 'PNG')
            return Response(output.getvalue(), media_type='image/png', headers={'Cache-Control': 'no-store'})
        return FileResponse(images.path(image_id, user), media_type='image/png', filename=f'sanaa-{image_id}.png', headers={'Cache-Control': 'no-store'})

    @app.post('/api/projects', status_code=201, response_model=ProjectResponse)
    def save_project(request: ProjectRequest, user=Depends(owner)):
        job = db.get(request.job_id, user, 'job')
        if job['status'] != 'completed' or not job['output_image_id']:
            raise ServiceError(409, 'job_not_complete', 'Дууссан AI үр дүнг хадгална уу.')
        room = db.get(job['request']['room_id'], user, 'room')
        return db.put(user, 'project', dict(name=request.name, job_id=job['id'], room_id=room['id'], source_image_id=room['image_id'], output_image_id=job['output_image_id'], preferences=job['request'], parameters=job.get('parameters', {})))

    @app.get('/api/projects')
    def list_projects(user=Depends(owner)):
        return {'projects': db.list(user, 'project')[:200]}

    @app.get('/api/projects/{project_id}', response_model=ProjectResponse)
    def get_project(project_id: str, user=Depends(owner)):
        return db.get(project_id, user, 'project')

    return app


app = create_app()
