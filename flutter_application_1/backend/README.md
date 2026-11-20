# SANAA local-model backend

This implementation uses actual uploaded photos and local pretrained models. It has no commercial image-API fallback and never returns reference screenshots as generated output. Core API operations work without model weights; inference endpoints return structured HTTP 503 errors when their configured model is missing.

## Setup

Use Python 3.11. From `backend/`:

```powershell
python -m venv .venv
.venv/Scripts/python -m pip install -r requirements.txt
Copy-Item .env.example .env
.venv/Scripts/python -m uvicorn main:app --host 127.0.0.1 --port 8000 --workers 1
```

On Linux use `.venv/bin/python`. On this workspace Python was installed into `../.tools/python/`, and `.venv` has already been created. First startup generates `data/.dev-token` if `SANAA_API_TOKENS` is empty. Treat this file as a credential; do not commit it. Supply `Authorization: Bearer <token>` on every `/api/` request. `/health` and `/docs` are public. Multiple comma-separated tokens create separate asset/project namespaces. The existing Flutter mock login is **not** production authentication. For deployment use proper short-lived user authentication and map identities to namespaces.

## Flutter connection

Create an ignored local JSON file, for example `.tools/flutter-local.json`, containing `SANAA_API_URL` and `SANAA_API_TOKEN`; use `flutter run --dart-define-from-file=.tools/flutter-local.json`. Never add AI-provider credentials to Flutter. This token is a development backend credential, not a private provider API key.

- Chrome on the server machine: `http://127.0.0.1:8000`; allow its exact origin in `SANAA_CORS_ORIGINS` (default app port 5188).
- Android emulator: `http://10.0.2.2:8000`. Android debug builds allow cleartext HTTP; release builds should use HTTPS.
- Physical Android: bind the server to `0.0.0.0`, use its LAN hostname/IP, and explicitly allow the local port in the host firewall. No firewall rules are changed by this project.
- iOS simulator: `http://localhost:8000`. A physical iPhone needs a reachable local `.local` hostname with local-network permission or a valid HTTPS endpoint. ATS local-network access is configured, not unrestricted HTTP access. Prefer HTTPS for remote hosts.

The app sends photos when the user enters AI editing, with an on-screen notice. Camera capture itself remains local. Source photos, cleaned images and masks stay distinct. Accepted mask IDs are validated against both the owning room and exact source image revision. Native drafts persist image paths and typed settings; web drafts also store image bytes and are subject to browser storage quota. Missing local images produce a replacement prompt rather than a generic photo.

## Model installation and compatibility

The exact source/checkpoint revisions and licenses are in `models.lock.json`. The CPU-only libraries installed here are Torch 2.6.0+cpu, torchvision 0.21.0+cpu, Diffusers 0.35.1 and Transformers 4.56.2. Their SDXL pipeline imports were checked. `requirements-resolved.txt` records the complete tested environment.

```powershell
# CPU SAM test environment; use the CUDA Torch wheel on a GPU server instead.
.venv/Scripts/python -m pip install torch==2.6.0 torchvision==0.21.0 --index-url https://download.pytorch.org/whl/cpu
.venv/Scripts/python -m pip install -r requirements-ai.txt
.venv/Scripts/python -m pip install wheel
$env:SAM2_BUILD_CUDA='0'
.venv/Scripts/python -m pip install --no-build-isolation 'git+https://github.com/facebookresearch/sam2.git@2b90b9f5ceec907a1c18123530e92e794ad901a4'
.venv/Scripts/python scripts/download_models.py sam2
```

Set `SANAA_SEGMENTATION_ENABLED=true`. SAM 2.1 Hiera tiny must use `configs/sam2.1/sam2.1_hiera_t.yaml`, not an unrelated SAM/SAM 2 configuration. It is cached once per worker. CPU is the default SAM device to avoid competing with diffusion VRAM. The optional CUDA postprocessing extension is disabled; the real image-predictor inference still runs.

For diffusion, review the model licenses, then explicitly download the large checkpoints:

```powershell
.venv/Scripts/python scripts/download_models.py base controlnet inpainting
```

The SDXL base and `diffusers/controlnet-canny-sdxl-1.0` are paired using `StableDiffusionXLControlNetImg2ImgPipeline`. SD 1.x ControlNet weights are incompatible. Removal uses `StableDiffusionXLInpaintPipeline` with `diffusers/stable-diffusion-xl-1.0-inpainting-0.1`, not a text-to-image checkpoint repurposed as an inpainting model. Inference is local-files-only. Set the corresponding enabled flags and `SANAA_DEVICE=cuda` only on a correctly configured GPU host. Torch CUDA wheels must match that host; this workspace's installed Torch is CPU-only.

References and licenses:

- [Meta SAM 2 source and Apache 2.0 checkpoint licensing](https://github.com/facebookresearch/sam2).
- [SDXL base model card and Open RAIL++ terms](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0).
- [SDXL Canny ControlNet, trained against SDXL base](https://huggingface.co/diffusers/controlnet-canny-sdxl-1.0).
- [SDXL inpainting checkpoint and its model card](https://huggingface.co/diffusers/stable-diffusion-xl-1.0-inpainting-0.1).
- [Diffusers SDXL ControlNet pipeline documentation](https://huggingface.co/docs/diffusers/api/pipelines/controlnet_sdxl).

Open RAIL licenses include use restrictions; they are not interchangeable with Apache/MIT terms. Retain the downloaded license files. No model is claimed to have been trained from scratch by this application.

## Hardware and limits

The inspected laptop has a GTX 1650 with 4 GB VRAM and about 16 GB RAM. Real SAM 2 CPU inference was tested on a local room photo. SDXL + ControlNet and SDXL inpainting were **not** executed: their weights are not installed and this GPU is below the configured 8 GB minimum. An 8 GB guard is not a guarantee of sufficient memory; a 16–24 GB GPU host with adequate system RAM is a more practical target and must be measured. CPU diffusion requires an explicit opt-in and may be extremely slow. Only one diffusion pipeline is resident at once; SAM defaults to CPU.

`compose.gpu.yaml` and `Dockerfile` provide an unverified remote GPU configuration. Run behind TLS, keep the port private, configure real authentication, model/data volumes and backups, and set a reverse-proxy body limit (31 MB). The Docker image and GPU deployment have not been run here.

The structured prompt includes style, palette, room type, original user instructions, planning budget and architecture-preservation guidance. Canny conditions the actual room or cleaned input. It cannot guarantee unchanged walls, doors, windows or floor. The text encoders are primarily English; Mongolian instructions are passed through without pretending they were translated. English structured style tokens supplement them. A future explicit translation adapter can improve prompt fidelity. Budget is a planning constraint with no furniture-catalog price grounding.

## API

`/docs` contains the generated OpenAPI schemas.

| Method and route | Behavior |
| --- | --- |
| GET `/health` | Server health and configured model capabilities; not a claim that GPU inference was tested |
| POST `/api/rooms` | Multipart `file`; decode, normalize EXIF orientation, store PNG and compute real brightness/sharpness metrics |
| POST `/api/segment` | JSON `room_id`, optional `image_id`, exactly one `point` or `box` in original pixel coordinates; real SAM mask |
| POST `/api/masks` | Multipart `room_id`, `image_id`, PNG `file`; explicitly manual mask |
| POST `/api/remove-furniture` | JSON room/image, `mask_ids`, seed, dilation; real inpainting and exact original pixels outside the dilated mask |
| POST `/api/generate` | Typed preferences, prompt, seed and optional masks; persist job and return 202 |
| GET `/api/jobs/{id}` | Persisted queued/running/completed/failed/cancelled status; measured denoising-step progress when available |
| POST `/api/jobs/{id}/cancel` | Cooperative cancellation; checked between actual inference steps |
| GET `/api/images/{id}` | Owner-checked PNG; `?overlay=true` returns a transparent green mask visualization |
| POST `/api/projects` | Save only a genuinely completed job and its metadata |
| GET `/api/projects`, GET `/api/projects/{id}` | List/retrieve owner-specific projects |

File contents and decoded pixel limits are validated; filename extensions are not trusted. Metadata uses SQLite WAL and image filenames are generated IDs. Path traversal and cross-owner access are rejected. No walls/geometry are claimed by the image-quality checks. The UI therefore uses neutral guidance.

Development execution is one SQLite queue consumer, one Uvicorn process and a serialized model lock. Queued jobs survive restarts; interrupted running jobs become failed. Cancellation cannot interrupt a checkpoint load immediately, and synchronous removal can continue after a client timeout; retry is safe because the source stays unchanged. For production use a separate durable worker service (for example Celery/RQ), transactional job claiming, per-user quotas, idempotency, storage limits and monitoring. Do not run multiple consumers against this development queue.

`scripts/cleanup.py` lists expired unreferenced/orphan PNG files; `--apply` removes them. It protects saved projects and recorded source/job references. Removing a Flutter selection clears its current state, not archived server files. Retention defaults to 30 days and should be scheduled deliberately. No hidden background deletion is enabled.

## Verification and experiments

```powershell
.venv/Scripts/python -m pytest -q
$env:SANAA_TEST_MODELS='1'
.venv/Scripts/python -m pytest -q tests/test_real_models.py
.venv/Scripts/python scripts/check_models.py
$env:SANAA_SEGMENTATION_ENABLED='true'
.venv/Scripts/python scripts/experiment.py --input ../assets/images/room_input.png --point 180 145 --output data/experiments/sam2-room
```

The experiment saves the real binary mask, overlay, input SHA-256, model confidence and wall-clock time. SAM confidence is **not** ground-truth segmentation accuracy. Add `--ground-truth-mask annotations/room-mask.png` to measure IoU against a manually annotated mask. Add `--generate` only after configuring compatible checkpoints/hardware; it saves an actual generated image, seed, structured prompt, inference settings and a simple before/after pixel comparison. Pixel difference is not aesthetic quality. Compare multiple fixed seeds, manually inspect architecture changes and furniture placement, and record peak VRAM on the GPU host.

Custom application work comprises typed state, access control, persistence, safe image handling, crop-coordinate mapping, brush correction, mask union/dilation, exact unmasked-region compositing, structured prompts, durable jobs, comparison and exports. SAM 2 and diffusion inference are pretrained model capabilities. Future fine-tuning should use consented paired interior images and mask annotations, a held-out room split, a small SDXL LoRA baseline, fixed-seed comparisons and quality/structure assessments. No fine-tuning or training from scratch has been performed.

Implemented but unverified on hardware: full SDXL generation/removal, remote GPU deployment, native iOS networking/export and physical mobile camera-to-AI flow. Modern/classic cards currently use existing local example photographs; they are labeled as example previews, not curated depictions of those styles. Speech input is explicitly disabled because no speech service is configured.
