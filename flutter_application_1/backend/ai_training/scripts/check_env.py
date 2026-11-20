import sys
print('Python:', sys.version.split()[0])
try:
    import torch
    print('PyTorch:', torch.__version__)
    print('CUDA available:', torch.cuda.is_available())
    if torch.cuda.is_available():
        print('GPU:', torch.cuda.get_device_name(0))
        print('VRAM (GB):', round(torch.cuda.get_device_properties(0).total_memory / (1024**3), 2))
except ImportError:
    print('PyTorch not installed in the active environment.')
try:
    import sam2
    print('SAM2 import: OK')
except Exception as exc:
    print('SAM2 import: unavailable:', str(exc)[:160])
try:
    from ultralytics import YOLO
    print('Ultralytics import: OK')
except Exception as exc:
    print('Ultralytics import: unavailable:', str(exc)[:160])
