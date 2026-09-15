"""Lazily creates and caches the Supabase client for the shared DB the
mobile app also writes to (SUPABASE_URL/SUPABASE_KEY in backend/.env —
loaded by app/main.py's load_dotenv() call at startup).

Nothing in the backend calls get_client() yet — routers can import it once
they need to read/write the shared tables (e.g. persisting scan results
alongside the mobile app's history).
"""

import os
from functools import lru_cache

from supabase import Client, ClientOptions, create_client


class SupabaseConfigError(Exception):
    pass


def _env() -> tuple[str, str]:
    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_KEY")
    if not url or not key:
        raise SupabaseConfigError(
            "SUPABASE_URL and SUPABASE_KEY must be set in backend/.env — see README.md."
        )
    return url, key


@lru_cache(maxsize=1)
def get_client() -> Client:
    """Anon-key client, safe to share across requests — only use it for
    calls that don't carry a specific user's identity, like validating a
    JWT (auth.get_user(jwt) takes the token as an argument rather than
    mutating session state)."""
    url, key = _env()
    return create_client(url, key)


@lru_cache(maxsize=1)
def get_admin_client() -> Client:
    """Service-role client — bypasses RLS entirely. Only for server-side
    admin operations that must happen after our own verification, never in
    response to an unauthenticated request: currently just
    auth.admin.create_user() in routers/auth.py, called only after the
    OTP in pending_signups has been checked. Never expose this client's
    key, or any client built from it, to the mobile app."""
    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    if not url or not key:
        raise SupabaseConfigError(
            "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set in backend/.env "
            "to use admin operations — see README.md."
        )
    return create_client(url, key)


def get_authed_client(access_token: str) -> Client:
    """A fresh client per call, scoped to one user's access token.

    The token is passed via ClientOptions(headers=...) rather than
    Client.postgrest.auth(access_token) — that only patches the postgrest
    sub-client after the fact. Client.storage and Client.postgrest are each
    lazily built straight from self.options.headers independently, so
    postgrest.auth() silently left storage authenticated as the anon key
    only, which meant every photo upload got rejected by the "TO
    authenticated" RLS policy on storage.objects (see
    mobile_app/sql/supabase_migration_scan_photos.sql) with a 403 —
    despite postgrest queries against `scans` working fine. Setting the
    header before either sub-client is constructed fixes both at once.

    Deliberately NOT cached/shared: a shared client scoped to one token
    would leak across concurrent requests for different users.
    """
    url, key = _env()
    options = ClientOptions(headers={"Authorization": f"Bearer {access_token}"})
    return create_client(url, key, options=options)
