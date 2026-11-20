import secrets
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix='SANAA_', env_file='.env', extra='ignore')
    data_dir: Path = Path('data')
    api_tokens: str = ''
    cors_origins: str = 'http://localhost:5188,http://127.0.0.1:5188'
    max_upload_bytes: int = 30 * 1024 * 1024
    max_pixels: int = 40_000_000
    segmentation_enabled: bool = False
    sam_checkpoint: str = 'models/sam2.1_hiera_tiny.pt'
    sam_config: str = 'configs/sam2.1/sam2.1_hiera_t.yaml'
    removal_enabled: bool = False
    generation_enabled: bool = False
    base_model: str = 'models/sdxl-base'
    controlnet_model: str = 'models/controlnet-canny-sdxl'
    inpaint_model: str = 'models/sdxl-inpainting'
    device: str = 'cpu'
    sam_device: str = 'cpu'
    min_diffusion_vram_gb: float = 8
    diffusion_cpu_allowed: bool = False
    inference_steps: int = 25
    image_side: int = 768
    asset_retention_days: int = 30

    def tokens(self) -> list[str]:
        if self.api_tokens:
            return [t.strip() for t in self.api_tokens.split(',') if t.strip()]
        self.data_dir.mkdir(parents=True, exist_ok=True)
        token_file = self.data_dir / '.dev-token'
        if not token_file.exists():
            token_file.write_text(secrets.token_urlsafe(32), encoding='utf-8')
        return [token_file.read_text(encoding='utf-8').strip()]
