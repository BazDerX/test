"""Runs actual configured models; records no sample/fake inference result."""
import argparse
import hashlib
import json
import sys
import time
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import cv2
import numpy as np
from PIL import Image
from app.core.config import Settings
from app.services.model_runtime import ModelRuntime
from app.services.segmentation_service import ObjectSegmentationService
from app.services.interior_generation_service import InteriorGenerationService
from app.models.schemas import GenerateRequest

parser = argparse.ArgumentParser()
parser.add_argument('--input', required=True)
parser.add_argument('--point', nargs=2, type=float)
parser.add_argument('--ground-truth-mask')
parser.add_argument('--generate', action='store_true')
parser.add_argument('--seed', type=int, default=42)
parser.add_argument('--output', default='data/experiments')
args = parser.parse_args()
root = Path(args.output); root.mkdir(parents=True, exist_ok=True)
image = Image.open(args.input).convert('RGB')
runtime = ModelRuntime(Settings())
report = {'source_sha256': hashlib.sha256(Path(args.input).read_bytes()).hexdigest(), 'size': image.size, 'seed': args.seed, 'pretrained_not_trained_from_scratch': True}
if args.point:
    start = time.perf_counter()
    mask, score = ObjectSegmentationService(runtime).segment(image, point=args.point)
    mask.save(root / 'sam2-mask.png')
    report.update(segmentation_seconds=time.perf_counter() - start, sam_score=score, selected_pixels=int((np.asarray(mask) > 127).sum()), point=args.point)
    overlay = Image.new('RGBA', image.size, (49, 92, 71, 0)); overlay.putalpha(mask.point(lambda p: int(p * .45)))
    Image.alpha_composite(image.convert('RGBA'), overlay).save(root / 'segmentation-overlay.png')
    if args.ground_truth_mask:
        truth = np.asarray(Image.open(args.ground_truth_mask).convert('L')) > 127
        predicted = np.asarray(mask) > 127
        if truth.shape != predicted.shape: raise ValueError('Ground truth dimensions differ')
        report['mask_iou'] = float(np.logical_and(truth, predicted).sum() / max(1, np.logical_or(truth, predicted).sum()))
if args.generate:
    start = time.perf_counter()
    request = GenerateRequest(room_id='experiment', prompt='Bright comfortable living room with a simple sofa, round oak coffee table and plants. Preserve windows and floor.', seed=args.seed)
    output, parameters = InteriorGenerationService(runtime).generate(image, request, lambda value, message: print(message, value))
    output.save(root / 'generated.png')
    original = np.asarray(image.resize(output.size), dtype=np.float32)
    report.update(generation_seconds=time.perf_counter() - start, parameters=parameters, pixel_mae=float(np.abs(original - np.asarray(output)).mean()))
report_path = root / 'metrics.json'
report_path.write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps(report, indent=2))
