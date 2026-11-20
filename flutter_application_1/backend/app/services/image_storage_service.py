import io
import warnings
import numpy as np
import cv2
from PIL import Image, ImageOps, UnidentifiedImageError
from ..core.errors import ServiceError


class ImageStorageService:
    def __init__(self, settings, db):
        self.settings, self.db = settings, db
        self.root = settings.data_dir / 'images'
        self.root.mkdir(parents=True, exist_ok=True)

    def decode(self, raw: bytes, mask=False):
        if not raw or len(raw) > self.settings.max_upload_bytes:
            raise ServiceError(413, 'file_size', 'Зургийн хэмжээ 30 МБ-аас бага байх ёстой.')
        try:
            with warnings.catch_warnings():
                warnings.simplefilter('error', Image.DecompressionBombWarning)
                with Image.open(io.BytesIO(raw)) as opened:
                    if opened.format not in {'JPEG', 'PNG', 'WEBP', 'HEIF', 'HEIC'}:
                        raise ValueError('Unsupported image format')
                    if opened.width * opened.height > self.settings.max_pixels:
                        raise ValueError('Too many pixels')
                    opened.load()
                    return ImageOps.exif_transpose(opened).convert('L' if mask else 'RGB')
        except (UnidentifiedImageError, ValueError, OSError, Image.DecompressionBombError, Image.DecompressionBombWarning) as error:
            raise ServiceError(422, 'invalid_image', 'Зураг гэмтсэн эсвэл формат, хэмжээ нь дэмжигдээгүй.') from error

    def save(self, owner, image, kind, room_id, metadata=None):
        import uuid
        image_id = uuid.uuid4().hex
        path = self.root / f'{image_id}.png'
        image.save(path, format='PNG')
        return self.db.put(owner, 'image', dict(room_id=room_id, kind=kind, width=image.width, height=image.height, metadata=metadata or {}), image_id)

    def load(self, image_id, owner, room_id=None, kinds=None):
        record = self.db.get(image_id, owner, 'image')
        if room_id and record['room_id'] != room_id or kinds and record['kind'] not in kinds:
            raise ServiceError(422, 'asset_mismatch', 'Зураг эсвэл маск энэ өрөөнд хамаарахгүй байна.')
        path = self.path(image_id, owner)
        with Image.open(path) as image:
            return record, image.copy()

    def path(self, image_id, owner):
        self.db.get(image_id, owner, 'image')
        # IDs come from the database, never directly from filesystem paths.
        if len(image_id) != 32 or any(c not in '0123456789abcdef' for c in image_id):
            raise ServiceError(404, 'not_found', 'Зураг олдсонгүй.')
        path = self.root / f'{image_id}.png'
        if not path.is_file():
            raise ServiceError(404, 'image_missing', 'Зургийн файл олдсонгүй.')
        return path

    def source(self, room_id, owner, image_id=None):
        room = self.db.get(room_id, owner, 'room')
        return self.load(image_id or room['image_id'], owner, room_id, {'source', 'cleaned'})

    def combine_masks(self, room_id, owner, image_record, mask_ids, dilation=0):
        combined = np.zeros((image_record['height'], image_record['width']), dtype=np.uint8)
        for mask_id in mask_ids:
            record, image = self.load(mask_id, owner, room_id, {'mask'})
            if record['metadata'].get('image_id') != image_record['id'] or image.size != (image_record['width'], image_record['height']):
                raise ServiceError(422, 'mask_mismatch', 'Маск сонгосон зургийн хэмжээтэй тохирохгүй байна.')
            combined = np.maximum(combined, np.where(np.asarray(image.convert('L')) > 127, 255, 0).astype(np.uint8))
        if not combined.any():
            raise ServiceError(422, 'empty_mask', 'Арилгах хэсгээ сонгоно уу.')
        if dilation:
            combined = cv2.dilate(combined, np.ones((dilation * 2 + 1, dilation * 2 + 1), np.uint8))
        return Image.fromarray(combined)

    @staticmethod
    def quality(image):
        gray = cv2.cvtColor(np.asarray(image), cv2.COLOR_RGB2GRAY)
        return dict(width=image.width, height=image.height, brightness=round(float(gray.mean()), 2), sharpness=round(float(cv2.Laplacian(gray, cv2.CV_64F).var()), 2), geometry_detected=False)
