from typing import Literal
from pydantic import BaseModel, Field, model_validator
from typing import Any

RoomType = Literal['living', 'bedroom']
Style = Literal['scandinavian', 'warm_minimal', 'modern', 'classic']
Palette = Literal['beige', 'sage', 'brown', 'gray', 'forest']


class SegmentRequest(BaseModel):
    room_id: str
    image_id: str | None = None
    point: tuple[float, float] | None = None
    box: tuple[float, float, float, float] | None = None

    @model_validator(mode='after')
    def has_prompt(self):
        if (self.point is None) == (self.box is None):
            raise ValueError('Provide exactly one point or box')
        return self


class RemovalRequest(BaseModel):
    room_id: str
    image_id: str | None = None
    mask_ids: list[str] = Field(min_length=1, max_length=20)
    dilation: int = Field(default=5, ge=0, le=25)
    seed: int = Field(default=42, ge=0, le=2**32-1)


class Preferences(BaseModel):
    room_type: RoomType = 'living'
    style: Style = 'scandinavian'
    palette: Palette = 'beige'
    budget: int = Field(default=2_000_000, ge=500_000, le=5_000_000)


class GenerateRequest(Preferences):
    room_id: str
    image_id: str | None = None
    mask_ids: list[str] = Field(default_factory=list, max_length=20)
    prompt: str = Field(min_length=5, max_length=2000)
    seed: int = Field(default=42, ge=0, le=2**32-1)


class ProjectRequest(BaseModel):
    job_id: str
    name: str = Field(min_length=1, max_length=120)


class ImageMetadata(BaseModel):
    id: str
    room_id: str
    kind: Literal['source', 'cleaned', 'mask', 'generated']
    width: int
    height: int
    metadata: dict[str, Any]
    created: float


class RoomUploadResponse(BaseModel):
    room_id: str
    image: ImageMetadata
    quality: dict[str, Any]


class JobResponse(BaseModel):
    id: str
    status: Literal['queued', 'running', 'completed', 'failed', 'cancelled']
    progress: float | None = None
    request: dict[str, Any]
    output_image_id: str | None = None
    message: str | None = None
    error: str | None = None
    error_code: str | None = None
    parameters: dict[str, Any] = Field(default_factory=dict)
    created: float


class ProjectResponse(BaseModel):
    id: str
    name: str
    job_id: str
    room_id: str
    source_image_id: str
    output_image_id: str
    preferences: GenerateRequest
    parameters: dict[str, Any]
    created: float
