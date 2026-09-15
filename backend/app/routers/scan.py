from fastapi import APIRouter, File, Form, Header, HTTPException, UploadFile
from PIL import Image

from app.schemas.scan_schema import ScanResponse
from app.services import history, image_analysis, inference, meat_gate
from app.utils.image_preprocessing import ImageValidationError, load_image
from app.utils.logging import get_logger

router = APIRouter(prefix="/scan", tags=["scan"])
logger = get_logger(__name__)


@router.post("", response_model=ScanResponse)
async def scan_meat(
    file: UploadFile = File(...),
    meat_type: str = Form(...),
    meat_type_id: int = Form(...),
    authorization: str | None = Header(default=None),
) -> ScanResponse:
    file_bytes = await file.read()

    try:
        image = load_image(file_bytes)
    except ImageValidationError as e:
        raise HTTPException(status_code=400, detail=str(e)) from e

    logger.info("Authorization header present: %s", authorization is not None)

    try:
        is_meat, meat_probability = meat_gate.looks_like_raw_meat(image, meat_type=meat_type)
    except meat_gate.MeatGateException as e:
        raise HTTPException(status_code=503, detail=str(e)) from e
    logger.info("meat_gate: is_meat=%s probability=%.2f", is_meat, meat_probability)
    if not is_meat:
        raise HTTPException(
            status_code=422,
            detail="This doesn't look like a photo of meat. Please retake the photo — "
            "fill the frame with the meat surface, with no packaging or plate.",
        )

    try:
        is_fresh, confidence = inference.classify(image)
    except inference.InferenceServiceException as e:
        raise HTTPException(status_code=503, detail=str(e)) from e
    logger.info("classify: is_fresh=%s confidence=%.2f", is_fresh, confidence)

    findings = image_analysis.analyze_image(image)

    real_content_type = Image.MIME.get(image.format) if image.format else None

    try:
        saved = history.save_scan(
            authorization=authorization,
            meat_type_id=meat_type_id,
            is_fresh=is_fresh,
            confidence=confidence,
            image_bytes=file_bytes,
            image_content_type=real_content_type or file.content_type,
            hue_deg=findings.hue_deg,
            saturation_pct=findings.saturation_pct,
            brightness_pct=findings.brightness_pct,
            uniformity_pct=findings.uniformity_pct,
        )
        logger.info("save_scan result: %s", saved)
    except history.HistorySaveException as e:
        logger.error("save_scan FAILED (%s): %s", e.status_code, e)
        raise HTTPException(status_code=e.status_code, detail=str(e)) from e

    return ScanResponse(
        is_fresh=is_fresh,
        classification="Fresh" if is_fresh else "Spoiled",
        confidence=confidence,
        meat_type=meat_type,
        scan_id=saved.scan_id if saved else None,
        image_path=saved.image_path if saved else None,
        image_url=saved.image_url if saved else None,
        hue_deg=findings.hue_deg,
        saturation_pct=findings.saturation_pct,
        brightness_pct=findings.brightness_pct,
        uniformity_pct=findings.uniformity_pct,
    )
