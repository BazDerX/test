import numpy as np
from PIL import Image
from ..core.errors import ServiceError


class ObjectSegmentationService:
    def __init__(self, runtime):
        self.runtime = runtime

    def segment(self, image, point=None, box=None):
        width, height = image.size
        if point is not None and not (0 <= point[0] < width and 0 <= point[1] < height):
            raise ServiceError(422, 'invalid_point', 'Сонгосон цэг зургийн гадна байна.')
        if box is not None and not (0 <= box[0] < box[2] <= width and 0 <= box[1] < box[3] <= height):
            raise ServiceError(422, 'invalid_box', 'Сонгосон хүрээ зургийн гадна байна.')
        self.runtime.require('segmentation')
        with self.runtime.lock:
            import torch
            from sam2.build_sam import build_sam2
            from sam2.sam2_image_predictor import SAM2ImagePredictor
            cfg = self.runtime.settings
            if self.runtime.predictor is None:
                model = build_sam2(cfg.sam_config, cfg.sam_checkpoint, device=cfg.sam_device, apply_postprocessing=False)
                self.runtime.predictor = SAM2ImagePredictor(model)
            predictor = self.runtime.predictor
            with torch.inference_mode():
                predictor.set_image(np.array(image.convert('RGB'), copy=True))
                masks, scores, _ = predictor.predict(
                    point_coords=None if point is None else np.array([point], dtype=np.float32),
                    point_labels=None if point is None else np.array([1], dtype=np.int32),
                    box=None if box is None else np.array(box, dtype=np.float32),
                    multimask_output=True,
                )
            index = int(np.argmax(scores))
            mask = masks[index]
            if mask.shape != (height, width) or not mask.any():
                raise ServiceError(422, 'empty_segmentation', 'Объектын маск үүссэнгүй. Өөр цэг эсвэл гараар сонгоно уу.')
            return Image.fromarray(mask.astype(np.uint8) * 255), float(scores[index])
