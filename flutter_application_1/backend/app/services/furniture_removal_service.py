from PIL import Image


def inference_size(image, side):
    ratio = min(1, side / max(image.size))
    return tuple(max(64, int(d * ratio) // 8 * 8) for d in image.size)


class FurnitureRemovalService:
    def __init__(self, runtime):
        self.runtime = runtime

    def remove(self, image, mask, seed):
        with self.runtime.lock:
            pipeline = self.runtime.get_pipeline('removal')
            import torch
            size = inference_size(image, self.runtime.settings.image_side)
            generator = torch.Generator(device='cpu').manual_seed(seed)
            result = pipeline(prompt='empty clean room, continuous natural wall and floor surfaces, no furniture in the selected area, same room perspective and lighting', negative_prompt='furniture, people, distorted walls, text, watermark', image=image.resize(size), mask_image=mask.resize(size, Image.Resampling.NEAREST), width=size[0], height=size[1], strength=.99, num_inference_steps=self.runtime.settings.inference_steps, generator=generator).images[0]
            # Exact original pixels outside the accepted (dilated) mask.
            cleaned = Image.composite(result.resize(image.size, Image.Resampling.LANCZOS), image, mask)
            return cleaned, dict(model=self.runtime.settings.inpaint_model, seed=seed, steps=self.runtime.settings.inference_steps, strength=.99, inference_size=size, unmasked_pixels_preserved=True)
