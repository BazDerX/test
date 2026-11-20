import asyncio
import logging
from ..models.schemas import GenerateRequest
from ..core.errors import ServiceError, JobCancelled

logger = logging.getLogger(__name__)


class JobService:
    def __init__(self, db, images, generation, removal):
        self.db, self.images, self.generation, self.removal = db, images, generation, removal

    async def run(self):
        # Development: a single durable SQLite queue and one inference worker.
        # Running work is marked interrupted, never falsely completed on restart.
        for job in self.db.all('job'):
            if job['status'] == 'running':
                self.db.update(job['id'], job['owner'], status='failed', error='Сервер дахин ассан тул ажил тасарсан. Дахин оролдоно уу.')
        while True:
            queued = [j for j in self.db.all('job') if j['status'] == 'queued']
            if not queued:
                await asyncio.sleep(.25)
                continue
            await asyncio.to_thread(self.execute, queued[0])

    def execute(self, job):
        owner, job_id = job['owner'], job['id']
        def progress(value, message):
            if self.db.get(job_id, owner, 'job')['status'] == 'cancelled':
                raise JobCancelled()
            self.db.update(job_id, owner, progress=value, message=message)
        try:
            progress(None, 'Зургийг бэлдэж байна.')
            self.db.update(job_id, owner, status='running')
            request = GenerateRequest(**job['request'])
            record, image = self.images.source(request.room_id, owner, request.image_id)
            if request.mask_ids:
                mask = self.images.combine_masks(request.room_id, owner, record, request.mask_ids, dilation=5)
                image, _ = self.removal.remove(image, mask, request.seed)
            result, parameters = self.generation.generate(image, request, progress)
            progress(None, 'Үр дүнг хадгалж байна.')
            asset = self.images.save(owner, result, 'generated', request.room_id, parameters)
            self.db.update(job_id, owner, status='completed', progress=1.0, output_image_id=asset['id'], parameters=parameters, message='Тохижуулалт бэлэн боллоо.')
        except JobCancelled:
            pass
        except ServiceError as error:
            self.db.update(job_id, owner, status='failed', error=error.message, error_code=error.code, progress=None)
        except Exception:
            logger.exception('Inference job failed: %s', job_id)
            self.db.update(job_id, owner, status='failed', error='AI ажиллуулалт амжилтгүй боллоо. Серверийн загвар, санах ой болон бүртгэлийг шалгана уу.', progress=None)
