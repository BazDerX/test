# Verified CPU segmentation

Input: `assets/images/room_input.png` (340 × 216). The manually specified positive point `(180, 145)` selected a sofa cushion. `sam2-mask.png` is the actual binary SAM 2 output and `segmentation-overlay.png` visualizes that mask. It is not a hardcoded rectangle and does not claim to identify every part of the sofa.

Model: Meta SAM 2.1 Hiera tiny, checkpoint SHA-256 `7402e0d864fa82708a20fbd15bc84245c2f26dff0eb43a4b5b93452deb34be69`, source revision recorded in `models.lock.json`. Torch 2.6.0+cpu was used. The first call, including model loading, took about 5.86 seconds on this laptop. The model's confidence was about 0.951; without ground-truth annotations this is not a segmentation accuracy measurement. No SDXL image was generated in this experiment.

Reproduce from `backend/`: set `SANAA_SEGMENTATION_ENABLED=true`, then run `.venv/Scripts/python scripts/experiment.py --input ../assets/images/room_input.png --point 180 145 --output data/experiments/sam2-room`.
