from pydantic import BaseModel


class NearbySummaryRequest(BaseModel):
    lat: float
    lng: float
    radius_km: float = 1.0
