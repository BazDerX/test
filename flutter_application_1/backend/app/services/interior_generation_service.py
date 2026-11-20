import cv2
import numpy as np
from PIL import Image
from .furniture_removal_service import inference_size
from .prompt_builder import build_prompt, NEGATIVE


class InteriorGenerationService:
    def __init__(self, runtime):
        self.runtime = runtime

    def generate(self, image, request, progress):
        with self.runtime.lock:
            progress(None, 'Загварыг ачаалж байна.')
            pipeline = self.runtime.get_pipeline('generation')
            import torch
            size = inference_size(image, self.runtime.settings.image_side)
            source = image.convert('RGB').resize(size, Image.Resampling.LANCZOS)
            edges = cv2.Canny(np.asarray(source), 100, 200)
            control = Image.fromarray(np.repeat(edges[:, :, None], 3, axis=2))
            prompt = build_prompt(request)
            def callback(pipe, step, timestep, callback_kwargs):
                total = pipe.num_timesteps
                progress((step + 1) / total if total else None, 'AI тохижуулалт үүсгэж байна.')
                return callback_kwargs
            output = pipeline(prompt=prompt, negative_prompt=NEGATIVE, image=source, control_image=control, strength=.65, controlnet_conditioning_scale=.7, guidance_scale=7.5, num_inference_steps=self.runtime.settings.inference_steps, generator=torch.Generator(device='cpu').manual_seed(request.seed), callback_on_step_end=callback).images[0]
            parameters = dict(base_model=self.runtime.settings.base_model, controlnet=self.runtime.settings.controlnet_model, seed=request.seed, steps=self.runtime.settings.inference_steps, strength=.65, controlnet_conditioning_scale=.7, guidance_scale=7.5, inference_size=size, structured_prompt=prompt, negative_prompt=NEGATIVE, architecture_guaranteed=False, catalog_prices_verified=False)
            return output, parameters
