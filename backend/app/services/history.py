"""Saves a completed scan — classification + the exact photo that was
scanned — to Supabase, matching what the mobile app's history screens
already read (see mobile_app/lib/services/history_service.dart).

The backend is the sole writer to `scans` and `scan-photos` — the mobile
app used to insert history rows itself right after receiving a
classification, but that would now double-save every scan since this
module does it first. Saving is optional per request: a guest (no
Authorization header) can still get a classification back, just without a
`scans` row or a stored photo.
"""

import mimetypes
import os
import uuid
from datetime import datetime, timezone
from typing import NamedTuple

from app.services import supabase_client

# See mobile_app/sql/supabase_migration_scan_photos.sql for the bucket +
# RLS policies (INSERT/SELECT scoped to the uploader's own `{uid}/...`
# folder) this relies on.
SCAN_PHOTOS_BUCKET = "scan-photos"

# scan-photos is a private bucket, so a plain public URL wouldn't actually
# be reachable — image_url has to be a signed URL instead. 10 years is a
# pragmatic stand-in for "effectively permanent"; signed URLs do still
# expire, so re-sign nearer the time if this ever needs to be long-lived
# for real (e.g. regenerate from image_path on read instead of trusting
# the stored URL indefinitely).
SIGNED_URL_EXPIRES_IN = 10 * 365 * 24 * 3600


class HistorySaveException(Exception):
    def __init__(self, message: str, status_code: int = 503):
        super().__init__(message)
        self.status_code = status_code


class SavedScan(NamedTuple):
    scan_id: str
    image_path: str
    image_url: str | None


def _extract_bearer_token(authorization: str | None) -> str | None:
    if not authorization:
        return None
    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise HistorySaveException(
            "Authorization header must be 'Bearer <token>'.", status_code=401
        )
    return token


def _upload_photo(client, user_id: str, image_bytes: bytes, content_type: str | None) -> str:
    ext = (mimetypes.guess_extension(content_type) if content_type else None) or ".jpg"
    path = f"{user_id}/{uuid.uuid4().hex}{ext}"
    client.storage.from_(SCAN_PHOTOS_BUCKET).upload(
        path,
        image_bytes,
        file_options={"content-type": content_type or "application/octet-stream"},
    )
    return path


def _signed_url(client, path: str) -> str | None:
    try:
        result = client.storage.from_(SCAN_PHOTOS_BUCKET).create_signed_url(path, SIGNED_URL_EXPIRES_IN)
    except Exception:
        # Non-fatal: the row still gets image_path, which is enough to
        # re-derive a fresh signed URL later even if this one attempt fails.
        return None
    url = result.get("signedURL") or result.get("signedUrl")
    if not url:
        return None
    if url.startswith("http"):
        return url
    base_url = os.getenv("SUPABASE_URL", "").rstrip("/")
    return f"{base_url}{url}"


def save_scan(
    *,
    authorization: str | None,
    meat_type_id: int,
    is_fresh: bool,
    confidence: float,
    image_bytes: bytes,
    image_content_type: str | None,
    hue_deg: float | None = None,
    saturation_pct: float | None = None,
    brightness_pct: float | None = None,
    uniformity_pct: float | None = None,
) -> SavedScan | None:
    """Uploads the scanned photo and inserts its `scans` row, returning
    both ids — or None if the caller is a guest (no Authorization header)
    and nothing was saved."""
    token = _extract_bearer_token(authorization)
    if token is None:
        return None

    try:
        user_response = supabase_client.get_client().auth.get_user(token)
    except Exception as e:
        raise HistorySaveException(f"Invalid or expired session: {e}", status_code=401) from e

    user = user_response.user if user_response else None
    if user is None:
        raise HistorySaveException("Invalid or expired session.", status_code=401)

    client = supabase_client.get_authed_client(token)

    try:
        image_path = _upload_photo(client, user.id, image_bytes, image_content_type)
    except Exception as e:
        raise HistorySaveException(f"Couldn't upload scan photo: {e}", status_code=503) from e

    image_url = _signed_url(client, image_path)

    try:
        response = (
            client.from_("scans")
            .insert(
                {
                    "profile_id": user.id,
                    "meat_type_id": meat_type_id,
                    "classification": "Fresh" if is_fresh else "Spoiled",
                    "confidence_score": confidence,
                    "scanned_at": datetime.now(timezone.utc).isoformat(),
                    "image_path": image_path,
                    "image_url": image_url,
                    "hue_deg": hue_deg,
                    "saturation_pct": saturation_pct,
                    "brightness_pct": brightness_pct,
                    "uniformity_pct": uniformity_pct,
                }
            )
            .select("scan_id")
            .execute()
        )
    except Exception as e:
        raise HistorySaveException(f"Couldn't save this scan: {e}", status_code=503) from e

    if not response.data:
        raise HistorySaveException("Scan insert returned no row.", status_code=503)
    return SavedScan(scan_id=response.data[0]["scan_id"], image_path=image_path, image_url=image_url)
