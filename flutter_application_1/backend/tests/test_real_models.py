import os
import importlib.util
from pathlib import Path
import pytest
from PIL import Image
from app.core.config import Settings
from app.services.model_runtime import ModelRuntime
from app.services.segmentation_service import ObjectSegmentationService


@pytest.mark.skipif(os.environ.get('SANAA_TEST_MODELS') != '1', reason='Explicit opt-in required for actual model inference')
def test_real_sam_preserves_mask_dimensions():
    cfg = Settings(segmentation_enabled=True)
    if not Path(cfg.sam_checkpoint).is_file() or importlib.util.find_spec('sam2') is None:
        pytest.skip('SAM 2 checkpoint/package missing')
    image = Image.open('../assets/images/room_input.png').convert('RGB')
    runtime = ModelRuntime(cfg)
    service = ObjectSegmentationService(runtime)
    mask, score = service.segment(image, point=(180, 145))
    assert mask.size == image.size
    assert mask.getbbox() is not None
    assert set(mask.getdata()) <= {0, 255}
    # This is a model confidence, not a measured ground-truth accuracy score.
    assert 0 <= score <= 1
    predictor = runtime.predictor
    service.segment(image, box=(105, 110, 250, 195))
    assert runtime.predictor is predictor
