"""Aggregate-only lookup of nearby prior reports, used to warn a consumer
about a place before they rely on it. Never returns raw rows — only counts —
since reports.additional_details and reporter identity are private per-user
data (RLS restricts `reports` to `select own` for regular users). This uses
the service-role client specifically to compute a safe aggregate across all
users without ever exposing what's actually private.
"""

import math

from app.services import supabase_client

_KM_PER_DEGREE_LAT = 111.0


def _bounding_box(lat: float, lng: float, radius_km: float) -> tuple[float, float, float, float]:
    lat_delta = radius_km / _KM_PER_DEGREE_LAT
    lng_delta = radius_km / (_KM_PER_DEGREE_LAT * max(math.cos(math.radians(lat)), 0.01))
    return lat - lat_delta, lat + lat_delta, lng - lng_delta, lng + lng_delta


def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    r = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlng / 2) ** 2
    )
    return r * 2 * math.asin(min(1, math.sqrt(a)))


def _count_within_radius(
    table: str, lat_col: str, lng_col: str, lat: float, lng: float, radius_km: float
) -> int:
    admin = supabase_client.get_admin_client()
    min_lat, max_lat, min_lng, max_lng = _bounding_box(lat, lng, radius_km)

    try:
        rows = (
            admin.from_(table)
            .select(f"{lat_col},{lng_col}")
            .gte(lat_col, min_lat)
            .lte(lat_col, max_lat)
            .gte(lng_col, min_lng)
            .lte(lng_col, max_lng)
            .execute()
            .data
        )
    except Exception:
        # Informational-only feature — an error here should never block a
        # report submission, so degrade to "no data" rather than raising.
        return 0

    return sum(
        1
        for row in rows
        if row.get(lat_col) is not None
        and row.get(lng_col) is not None
        and _haversine_km(lat, lng, row[lat_col], row[lng_col]) <= radius_km
    )


def summary(lat: float, lng: float, radius_km: float = 1.0) -> dict:
    return {
        "complaint_count": _count_within_radius("reports", "purchase_lat", "purchase_lng", lat, lng, radius_km),
    }
