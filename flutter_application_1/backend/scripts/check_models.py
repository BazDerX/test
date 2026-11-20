import importlib.metadata
import json
import torch
from diffusers import StableDiffusionXLControlNetImg2ImgPipeline, StableDiffusionXLInpaintPipeline, ControlNetModel
from transformers import CLIPTextModel, CLIPTokenizer

print(json.dumps({'torch': torch.__version__, 'diffusers': importlib.metadata.version('diffusers'), 'transformers': importlib.metadata.version('transformers'), 'cuda_available': torch.cuda.is_available(), 'pipeline_imports': 'ok'}, indent=2))
