"""Example: python scripts/predict_yolo.py path/to/new_room.jpg"""
import argparse
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('image', help='Input room JPG or PNG image')
    parser.add_argument('--weights', help='Path to trained best.pt (optional)')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    image = Path(args.image).resolve()
    if not image.is_file():
        raise SystemExit(f'Image not found: {image}')
    if args.weights:
        weights = Path(args.weights).resolve()
    else:
        candidates = sorted((root / 'runs' / 'segmentation').glob('sanaa_furniture*/weights/best.pt'), key=lambda p: p.stat().st_mtime)
        if not candidates:
            raise SystemExit('No trained best.pt. Train first or pass --weights.')
        weights = candidates[-1]
    from ultralytics import YOLO
    model = YOLO(str(weights))
    model.predict(source=str(image), imgsz=416, conf=0.25, save=True,
                  project=str(root / 'runs' / 'predictions'), name='room', exist_ok=True)
    print('Output in runs/predictions/room')


if __name__ == '__main__':
    main()
