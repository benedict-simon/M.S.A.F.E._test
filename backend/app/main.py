from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

load_dotenv()

from app.routers import auth, reports, scan
from app.services import inference, meat_gate
from app.utils.logging import get_logger

app = FastAPI(title="M.S.A.F.E. API", version="0.1.0")
logger = get_logger(__name__)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(scan.router)
app.include_router(auth.router)
app.include_router(reports.router)


@app.on_event("startup")
def warm_up_models() -> None:
    # Both models are lru_cache'd and normally load on first use. Without this,
    # that load (torch/ultralytics import + CLIP/YOLO weights) happens during
    # someone's first real scan and can take longer than the app's request
    # timeout, making the first scan after every server restart look broken.
    try:
        meat_gate._load_model()
        inference._load_model()
        logger.info("Model warm-up complete")
    except Exception as e:
        logger.error("Model warm-up failed (will retry lazily on first scan): %s", e)


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}
