from pydantic import BaseModel, Field


class ScanResponse(BaseModel):
    is_fresh: bool
    classification: str  # "Fresh" | "Spoiled" — mirrors is_fresh, matches the mobile app's stored value
    confidence: float = Field(ge=0.0, le=1.0)
    meat_type: str

    hue_deg: float = Field(ge=0.0, le=360.0)
    saturation_pct: float = Field(ge=0.0, le=100.0)
    brightness_pct: float = Field(ge=0.0, le=100.0)
    uniformity_pct: float = Field(ge=0.0, le=100.0)

    scan_id: str | None = None
    image_path: str | None = None
    image_url: str | None = None
