import gc
import importlib.util
import threading
from pathlib import Path
from ..core.errors import ServiceError


class ModelRuntime:
    def __init__(self, settings):
        self.settings = settings
        self.lock = threading.Lock()
        self.predictor = None
        self.pipeline = None
        self.pipeline_kind = None

    def capabilities(self):
        cfg = self.settings
        torch = importlib.util.find_spec('torch') is not None
        diffusion = torch and importlib.util.find_spec('diffusers') is not None
        return dict(
            segmentation=cfg.segmentation_enabled and torch and importlib.util.find_spec('sam2') is not None and Path(cfg.sam_checkpoint).is_file(),
            removal=cfg.removal_enabled and diffusion and Path(cfg.inpaint_model, 'model_index.json').is_file(),
            generation=cfg.generation_enabled and diffusion and Path(cfg.base_model, 'model_index.json').is_file() and Path(cfg.controlnet_model, 'config.json').is_file(),
            speech=False, inference_verified=False,
        )

    def require(self, capability):
        if not self.capabilities().get(capability, False):
            raise ServiceError(503, f'{capability}_unavailable', 'Шаардлагатай AI загвар эсвэл жин холбогдоогүй байна. Серверийн тохиргоог шалгана уу.')

    def diffusion_device(self):
        import torch
        cfg = self.settings
        if cfg.device == 'cuda':
            if not torch.cuda.is_available():
                raise ServiceError(503, 'gpu_unavailable', 'CUDA GPU серверт боломжгүй байна.')
            total = torch.cuda.get_device_properties(0).total_memory / 1024**3
            if total < cfg.min_diffusion_vram_gb:
                raise ServiceError(503, 'insufficient_vram', 'SDXL ажиллуулах GPU санах ой хүрэлцэхгүй байна. Илүү их VRAM-тай сервер тохируулна уу.')
            return 'cuda', torch.float16
        if not cfg.diffusion_cpu_allowed:
            raise ServiceError(503, 'cpu_inference_disabled', 'SDXL-ийн CPU ажиллуулалт идэвхгүй. GPU сервер тохируулна уу.')
        return 'cpu', torch.float32

    def get_pipeline(self, kind):
        self.require('generation' if kind == 'generation' else 'removal')
        device, dtype = self.diffusion_device()
        if self.predictor is not None and self.settings.sam_device != 'cpu':
            self.predictor.model.to('cpu')
            self.predictor = None
        if self.pipeline_kind == kind:
            return self.pipeline
        self.pipeline = None
        self.pipeline_kind = None
        gc.collect()
        import torch
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
        if kind == 'generation':
            from diffusers import ControlNetModel, StableDiffusionXLControlNetImg2ImgPipeline
            control = ControlNetModel.from_pretrained(self.settings.controlnet_model, torch_dtype=dtype, local_files_only=True, use_safetensors=True)
            pipeline = StableDiffusionXLControlNetImg2ImgPipeline.from_pretrained(self.settings.base_model, controlnet=control, torch_dtype=dtype, local_files_only=True, use_safetensors=True)
        else:
            from diffusers import StableDiffusionXLInpaintPipeline
            pipeline = StableDiffusionXLInpaintPipeline.from_pretrained(self.settings.inpaint_model, torch_dtype=dtype, local_files_only=True, use_safetensors=True)
        pipeline.enable_attention_slicing()
        pipeline.enable_vae_tiling()
        if device == 'cuda':
            pipeline.enable_model_cpu_offload()
        else:
            pipeline.to('cpu')
        self.pipeline, self.pipeline_kind = pipeline, kind
        return pipeline
