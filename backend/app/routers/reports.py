from fastapi import APIRouter

from app.schemas.report_schema import NearbySummaryRequest
from app.services import nearby_reports

router = APIRouter(prefix="/reports", tags=["reports"])


@router.post("/nearby-summary")
def nearby_summary(body: NearbySummaryRequest) -> dict:
    return nearby_reports.summary(body.lat, body.lng, body.radius_km)
