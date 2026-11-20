"""Check annotated image/polygon pairs and split by room to avoid data leakage.

Naming rule: room001__view01.jpg and room001__view01.txt are one pair.
Images with the same prefix before '__' stay in the same split.
Run from any directory with: python scripts/prepare_dataset.py
"""
from pathlib import Path
from collections import defaultdict
import random
import shutil

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'datasets' / 'furniture_seg'
RAW_IMAGES = BASE / 'raw' / 'images'
RAW_LABELS = BASE / 'raw' / 'labels'
CLASSES = ['sofa', 'table', 'chair', 'bed']
EXTENSIONS = {'.jpg', '.jpeg', '.png', '.webp'}


def validate_label(path: Path) -> None:
    for line_no, line in enumerate(path.read_text(encoding='utf-8-sig').splitlines(), 1):
        if not line.strip():
            continue
        parts = line.split()
        try:
            cls = int(parts[0])
            coords = [float(x) for x in parts[1:]]
        except (ValueError, IndexError) as ex:
            raise ValueError(f'{path.name}:{line_no} has invalid numbers') from ex
        if cls not in range(len(CLASSES)):
            raise ValueError(f'{path.name}:{line_no} invalid class {cls}')
        if len(coords) < 6 or len(coords) % 2:
            raise ValueError(f'{path.name}:{line_no} requires at least 3 polygon points')
        if any(not 0 <= x <= 1 for x in coords):
            raise ValueError(f'{path.name}:{line_no} coordinates must be normalized to 0..1')


def main() -> None:
    images = sorted(p for p in RAW_IMAGES.iterdir() if p.is_file() and p.suffix.lower() in EXTENSIONS)
    if len(images) < 15:
        raise SystemExit(f'Need at least 15 annotated images for a first experiment; found {len(images)}.')

    by_room = defaultdict(list)
    for img in images:
        lbl = RAW_LABELS / f'{img.stem}.txt'
        if not lbl.is_file():
            raise SystemExit(f'Missing annotation for {img.name}: expected {lbl}')
        validate_label(lbl)
        room_key = img.stem.split('__', 1)[0]
        by_room[room_key].append((img, lbl))

    rooms = list(by_room)
    if len(rooms) < 8:
        raise SystemExit(f'Use >=8 independent room IDs for a valid room-level split; found {len(rooms)}.')
    random.Random(42).shuffle(rooms)
    n_val = max(1, round(len(rooms) * 0.10))
    n_test = max(1, round(len(rooms) * 0.10))
    assignments = {
        'val': rooms[:n_val],
        'test': rooms[n_val:n_val + n_test],
        'train': rooms[n_val + n_test:],
    }
    for split in ('train', 'val', 'test'):
        dst_img = BASE / 'images' / split
        dst_lbl = BASE / 'labels' / split
        dst_img.mkdir(parents=True, exist_ok=True)
        dst_lbl.mkdir(parents=True, exist_ok=True)
        # Output is regenerated, so outdated files do not contaminate the dataset.
        for folder in (dst_img, dst_lbl):
            for p in folder.iterdir():
                if p.is_file():
                    p.unlink()
        pairs = [pair for room in assignments[split] for pair in by_room[room]]
        for img, lbl in pairs:
            shutil.copy2(img, dst_img / img.name)
            shutil.copy2(lbl, dst_lbl / lbl.name)
        print(f'{split}: {len(pairs)} images from {len(assignments[split])} rooms')

    yaml_path = BASE / 'data.yaml'
    root = BASE.resolve().as_posix().replace("'", "''")
    lines = [f"path: '{root}'", 'train: images/train', 'val: images/val', 'test: images/test', 'names:']
    lines.extend(f'  {i}: {name}' for i, name in enumerate(CLASSES))
    yaml_path.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('Dataset configuration:', yaml_path)
    print('Reminder: check the exported labels visually, not just numerically.')


if __name__ == '__main__':
    main()
