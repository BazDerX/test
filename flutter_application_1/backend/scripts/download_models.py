"""Explicit model download; inference never downloads weights automatically."""
import argparse
import hashlib
import json
import urllib.request
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('models', nargs='+', choices=['sam2', 'base', 'controlnet', 'inpainting'])
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / 'models.lock.json').read_text())
target = root / 'models'; target.mkdir(exist_ok=True)
for name in args.models:
    model = manifest[name]
    if name == 'sam2':
        file = target / 'sam2.1_hiera_tiny.pt'
        if not file.exists(): urllib.request.urlretrieve(model['checkpoint_url'], file)
        if hashlib.sha256(file.read_bytes()).hexdigest() != model['checkpoint_sha256']:
            raise RuntimeError('SAM 2 checkpoint checksum mismatch; remove the incomplete file and retry')
    else:
        from huggingface_hub import snapshot_download
        snapshot_download(repo_id=model['repo'], revision=model['revision'], local_dir=target / model['directory'], ignore_patterns=['*.bin', '*.msgpack', '*.onnx', '*.h5', '*.ckpt'])
    print(name, 'downloaded and pinned')
