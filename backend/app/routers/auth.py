"""OTP-before-account-creation signup: request-otp emails a code without
creating any Supabase Auth record, verify only creates the account once
that code checks out. See app/services/signup_otp.py for the OTP handling
and mobile_app/sql/supabase_migration_pending_signups.sql for the table
this depends on.
"""

from fastapi import APIRouter, HTTPException

from app.schemas.auth_schema import RequestOtpRequest, UsernameRequest, VerifySignupRequest
from app.services import login_attempts, signup_otp, supabase_client
from app.utils.logging import get_logger

router = APIRouter(prefix="/auth", tags=["auth"])
logger = get_logger(__name__)


@router.post("/login-check")
def login_check(body: UsernameRequest) -> dict:
    try:
        locked, retry_after_seconds = login_attempts.check(body.username)
    except login_attempts.LoginAttemptsException as e:
        raise HTTPException(status_code=e.status_code, detail=str(e)) from e
    return {"locked": locked, "retry_after_seconds": retry_after_seconds}


@router.post("/login-failed")
def login_failed(body: UsernameRequest) -> dict:
    try:
        locked, retry_after_seconds, attempts_remaining = login_attempts.record_failure(body.username)
    except login_attempts.LoginAttemptsException as e:
        raise HTTPException(status_code=e.status_code, detail=str(e)) from e
    return {
        "locked": locked,
        "retry_after_seconds": retry_after_seconds,
        "attempts_remaining": attempts_remaining,
    }


@router.post("/login-success")
def login_success(body: UsernameRequest) -> dict:
    login_attempts.record_success(body.username)
    return {"success": True}


@router.post("/signup/request-otp")
def request_otp(body: RequestOtpRequest) -> dict:
    email = body.email.strip().lower()
    if "@" not in email:
        raise HTTPException(status_code=400, detail="Please enter a valid email address.")

    try:
        signup_otp.generate_and_send_otp(email)
    except signup_otp.SignupOtpException as e:
        raise HTTPException(status_code=e.status_code, detail=str(e)) from e

    logger.info("signup OTP sent to %s", email)
    return {"sent": True}


@router.post("/signup/verify")
def verify_signup(body: VerifySignupRequest) -> dict:
    email = body.email.strip().lower()

    try:
        signup_otp.verify_otp(email, body.otp.strip())
    except signup_otp.SignupOtpException as e:
        raise HTTPException(status_code=e.status_code, detail=str(e)) from e

    try:
        admin = supabase_client.get_admin_client()
    except supabase_client.SupabaseConfigError as e:
        raise HTTPException(status_code=503, detail=str(e)) from e

    try:
        result = admin.auth.admin.create_user(
            {
                "email": email,
                "password": body.password,
                "email_confirm": True,
                "user_metadata": {
                    "first_name": body.first_name,
                    "middle_initial": body.middle_initial,
                    "last_name": body.last_name,
                    "username": body.username,
                    "phone_number": body.phone_number,
                    "agreed_to_terms": True,
                },
            }
        )
    except Exception as e:
        msg = str(e).lower()
        if "already" in msg or "duplicate" in msg or "exists" in msg:
            raise HTTPException(
                status_code=409, detail="An account with that email already exists. Try logging in instead."
            ) from e
        logger.error("create_user failed for %s: %s", email, e)
        raise HTTPException(status_code=503, detail="We couldn't create your account. Please try again.") from e

    user = result.user
    if user is None:
        raise HTTPException(status_code=503, detail="We couldn't create your account. Please try again.")

    try:
        admin.from_("profiles").update(
            {
                "phone_number": body.phone_number,
                "user_email": email,
                "middle_initial": body.middle_initial,
            }
        ).eq("profile_id", user.id).execute()
    except Exception as e:
        # Non-fatal — the account itself was created successfully via
        # user_metadata above (a trigger normally seeds these same fields
        # onto the profiles row from that); this is just a best-effort
        # top-up, same as the pre-OTP flow this replaced.
        logger.error("post-create profiles update failed for %s: %s", email, e)

    logger.info("account created for %s after OTP verification", email)
    return {"success": True}
