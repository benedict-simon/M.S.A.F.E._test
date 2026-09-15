"""Validates and decodes an uploaded scan photo before it reaches inference.

Ultralytics handles resizing/normalization internally, so this stays intentionally
thin — it's a validation boundary (reject bad uploads early with a clear error),
not a full preprocessing pipeline.
"""

import io

from PIL import Image, ImageOps, UnidentifiedImageError

MAX_UPLOAD_BYTES = 10 * 1024 * 1024  # 10 MB


class ImageValidationError(Exception):
    pass


def load_image(file_bytes: bytes) -> Image.Image:
    if not file_bytes:
        raise ImageValidationError("Uploaded file is empty.")
    if len(file_bytes) > MAX_UPLOAD_BYTES:
        raise ImageValidationError("Uploaded file is too large (max 10 MB).")

    try:
        image = Image.open(io.BytesIO(file_bytes))
        image.load()
    except UnidentifiedImageError as e:
        raise ImageValidationError("Uploaded file isn't a valid image.") from e

    detected_format = image.format

    image = ImageOps.exif_transpose(image)

    converted = image.convert("RGB")
    converted.format = detected_format
    return converted
