"""Server-side login attempt tracking, keyed by username.

The mobile app calls Supabase Auth directly for the actual sign-in — this
backend never sees the password. So lockout state has to live here instead,
in a table only this service-role client can touch (see
mobile_app/sql/supabase_migration_login_attempts.sql for the RLS reasoning):
a client-side-only counter (e.g. in SharedPreferences) could just be wiped by
reinstalling the app, which defeats the point.
"""

from datetime import datetime, timedelta, timezone

from app.services import supabase_client

MAX_ATTEMPTS = 5
LOCKOUT_MINUTES = 5


class LoginAttemptsException(Exception):
    def __init__(self, message: str, status_code: int = 503):
        super().__init__(message)
        self.status_code = status_code


def _key(username: str) -> str:
    return username.strip().lower()


def _seconds_remaining(locked_until_raw: str, now: datetime) -> int | None:
    locked_until = datetime.fromisoformat(locked_until_raw)
    remaining = (locked_until - now).total_seconds()
    return int(remaining) if remaining > 0 else None


def check(username: str) -> tuple[bool, int | None]:
    """Returns (is_locked, retry_after_seconds) without recording anything —
    called before the app attempts the real Supabase sign-in."""
    admin = supabase_client.get_admin_client()
    try:
        rows = (
            admin.from_("login_attempts")
            .select("locked_until")
            .eq("username", _key(username))
            .execute()
            .data
        )
    except Exception as e:
        raise LoginAttemptsException(f"Couldn't check login status: {e}") from e

    locked_until_raw = rows[0]["locked_until"] if rows else None
    if not locked_until_raw:
        return False, None

    retry_after = _seconds_remaining(locked_until_raw, datetime.now(timezone.utc))
    return (retry_after is not None), retry_after


def record_failure(username: str) -> tuple[bool, int | None, int | None]:
    """Returns (is_locked, retry_after_seconds, attempts_remaining)."""
    admin = supabase_client.get_admin_client()
    key = _key(username)
    now = datetime.now(timezone.utc)

    try:
        rows = (
            admin.from_("login_attempts")
            .select("failed_count, locked_until")
            .eq("username", key)
            .execute()
            .data
        )
    except Exception as e:
        raise LoginAttemptsException(f"Couldn't record login attempt: {e}") from e

    current = rows[0] if rows else None

    # Already locked and the lock hasn't expired yet: don't pile on another
    # failed attempt, just report the time left.
    if current and current.get("locked_until"):
        retry_after = _seconds_remaining(current["locked_until"], now)
        if retry_after is not None:
            return True, retry_after, None

    next_count = (current["failed_count"] if current else 0) + 1
    locked = next_count >= MAX_ATTEMPTS

    payload = {
        "username": key,
        "failed_count": next_count,
        "locked_until": (now + timedelta(minutes=LOCKOUT_MINUTES)).isoformat() if locked else None,
        "updated_at": now.isoformat(),
    }

    try:
        admin.from_("login_attempts").upsert(payload, on_conflict="username").execute()
    except Exception as e:
        raise LoginAttemptsException(f"Couldn't record login attempt: {e}") from e

    if locked:
        return True, LOCKOUT_MINUTES * 60, None
    return False, None, MAX_ATTEMPTS - next_count


def record_success(username: str) -> None:
    admin = supabase_client.get_admin_client()
    try:
        admin.from_("login_attempts").delete().eq("username", _key(username)).execute()
    except Exception:
        # Non-fatal — worst case the counter resets a little late instead of
        # blocking a login that Supabase itself already approved.
        pass
