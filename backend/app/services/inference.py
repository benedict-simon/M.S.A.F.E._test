"""Loads the trained YOLOv8 classification model and runs Fresh/Spoiled inference.

The model is loaded once (lazily, on first request) and cached — reloading multi-MB
weights per request would be wasteful. See notebooks/train_yolov8_colab.ipynb for how
yolov8_msafe.pt gets produced.
"""

from functools import lru_cache
from pathlib import Path

from PIL import Image

MODEL_PATH = Path(__file__).resolve().parent.parent / "models" / "yolov8_msafe.pt"


class InferenceServiceException(Exception):
    pass


@lru_cache(maxsize=1)
def _load_model():
    from ultralytics import YOLO

    if not MODEL_PATH.exists():
        raise InferenceServiceException(
            f"Model weights not found at {MODEL_PATH}. Train and export yolov8_msafe.pt "
            "first — see notebooks/train_yolov8_colab.ipynb."
        )
    try:
        return YOLO(str(MODEL_PATH))
    except Exception as e:
        # Ultralytics raises plain TypeError/RuntimeError for a missing, empty, or
        # corrupt checkpoint (e.g. the tracked placeholder .pt before training has
        # actually run) — never let that leak as a raw 500, it's an expected state
        # during development, not a genuine server bug.
        raise InferenceServiceException(
            f"Couldn't load model weights from {MODEL_PATH}: {e}. If you haven't trained "
            "yet, this file is still the empty placeholder — see "
            "notebooks/train_yolov8_colab.ipynb."
        ) from e


def classify(image: Image.Image) -> tuple[bool, float]:
    """Returns (is_fresh, confidence) for a single RGB image."""
    model = _load_model()
    results = model.predict(image, verbose=False)
    probs = results[0].probs

    if probs is None:
        raise InferenceServiceException(
            "Model returned no classification probabilities — is app/models/yolov8_msafe.pt "
            "a YOLOv8-cls checkpoint, not a detection one?"
        )

    top1_index = int(probs.top1)
    confidence = float(probs.top1conf)
    # Read the label from the model's own class mapping rather than assuming index 0 =
    # fresh — Ultralytics assigns indices alphabetically from the training folder names,
    # so trust what the model actually says, not a hardcoded guess.
    label = model.names[top1_index].strip().lower()

    return label == "fresh", confidence
