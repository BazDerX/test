"""Fine-tune YOLO11 nano instance segmentation on furniture polygons.

For GTX 1650 4GB, start at 416px and batch 1. Increase only after it works.
"""
from pathlib import Path


def main():
    root = Path(__file__).resolve().parents[1]
    dataset = root / 'datasets' / 'furniture_seg' / 'data.yaml'
    if not dataset.exists():
        raise SystemExit('Dataset not ready. First run: python scripts/prepare_dataset.py')
    import torch
    from ultralytics import YOLO
    if not torch.cuda.is_available():
        raise SystemExit('CUDA is not available. Check the current .venv_gpu environment.')
    print('Using', torch.cuda.get_device_name(0))
    model = YOLO('yolo11n-seg.pt')  # downloads small pretrained weights on first use
    model.train(
        data=str(dataset),
        epochs=40,
        imgsz=416,
        batch=1,
        device=0,
        workers=0,  # safest for Windows
        amp=True,
        cache=False,
        patience=10,
        seed=42,
        project=str(root / 'runs' / 'segmentation'),
        name='sanaa_furniture',
        exist_ok=False,
    )


if __name__ == '__main__':
    main()
