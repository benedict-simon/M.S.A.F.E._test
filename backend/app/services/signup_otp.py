"""OTP-before-account-creation signup flow.

The point: no Supabase Auth account (not even an unconfirmed one) gets
created until the emailed code is verified — see routers/auth.py for how
this gets used end to end, and mobile_app/sql/supabase_migration_pending_signups.sql
for the backing table. Only `email + hashed code + expiry` is stored while
a signup is pending; the account's actual password never touches this
table, only the request body of the one call that creates the account.
"""

import hashlib
import os
import secrets
import smtplib
from datetime import datetime, timedelta, timezone
from email.message import EmailMessage

from app.services import supabase_client

OTP_TTL_MINUTES = 15
MAX_ATTEMPTS = 5


class SignupOtpException(Exception):
    def __init__(self, message: str, status_code: int = 400):
        super().__init__(message)
        self.status_code = status_code


def _hash(otp: str) -> str:
    return hashlib.sha256(otp.encode()).hexdigest()


def generate_and_send_otp(email: str) -> None:
    otp = f"{secrets.randbelow(1_000_000):06d}"
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=OTP_TTL_MINUTES)

    try:
        client = supabase_client.get_admin_client()
        # Upsert: a second request for the same still-pending email
        # (e.g. "Resend code") just replaces the old code/expiry outright.
        client.from_("pending_signups").upsert(
            {
                "email": email,
                "otp_hash": _hash(otp),
                "expires_at": expires_at.isoformat(),
                "attempts": 0,
            }
        ).execute()
    except Exception as e:
        raise SignupOtpException(f"Couldn't start signup verification: {e}", status_code=503) from e

    _send_otp_email(email, otp)


def verify_otp(email: str, otp: str) -> None:
    """Raises SignupOtpException if the code is wrong, expired, or the
    attempt limit was hit. Returns normally — and clears the pending row —
    if the code is correct; the caller is then clear to create the account."""
    try:
        client = supabase_client.get_admin_client()
        response = client.from_("pending_signups").select("*").eq("email", email).execute()
    except Exception as e:
        raise SignupOtpException(f"Couldn't verify that code: {e}", status_code=503) from e

    rows = response.data or []
    if not rows:
        raise SignupOtpException(
            "No pending signup found for this email. Please request a new code.", status_code=404
        )
    row = rows[0]

    expires_at = datetime.fromisoformat(row["expires_at"])
    if datetime.now(timezone.utc) >= expires_at:
        client.from_("pending_signups").delete().eq("email", email).execute()
        raise SignupOtpException("That code has expired. Please request a new one.", status_code=400)

    if row["attempts"] >= MAX_ATTEMPTS:
        client.from_("pending_signups").delete().eq("email", email).execute()
        raise SignupOtpException(
            "Too many incorrect attempts. Please request a new code.", status_code=429
        )

    if _hash(otp) != row["otp_hash"]:
        client.from_("pending_signups").update({"attempts": row["attempts"] + 1}).eq("email", email).execute()
        raise SignupOtpException("That code is incorrect. Please check it and try again.", status_code=400)

    client.from_("pending_signups").delete().eq("email", email).execute()


def _send_otp_email(email: str, otp: str) -> None:
    sender = os.getenv("SMTP_EMAIL")
    app_password = os.getenv("SMTP_APP_PASSWORD")
    if not sender or not app_password:
        raise SignupOtpException(
            "SMTP_EMAIL and SMTP_APP_PASSWORD must be set in backend/.env to send signup codes.",
            status_code=503,
        )

    message = EmailMessage()
    message["Subject"] = "Your M.S.A.F.E. verification code"
    message["From"] = sender
    message["To"] = email
    message.set_content(f"Your M.S.A.F.E. verification code is {otp}. It expires in {OTP_TTL_MINUTES} minutes.")
    message.add_alternative(_html_body(otp), subtype="html")

    try:
        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as smtp:
            smtp.login(sender, app_password)
            smtp.send_message(message)
    except Exception as e:
        raise SignupOtpException(f"Couldn't send the verification email: {e}", status_code=503) from e


def _html_body(otp: str) -> str:
    return f"""
    <div style="background:#f4f4f4; padding:40px 0; font-family:Arial, sans-serif;">
      <div style="background:#ffffff; max-width:460px; width:100%; margin:0 auto; border:1px solid #e8e8e8; border-radius:8px; overflow:hidden;">
        <div style="background-color:#B71C1C; padding:24px 32px; text-align:center;">
          <span style="font-size:20px; font-weight:bold; color:#ffffff; letter-spacing:1px;">M.S.A.F.E.</span>
        </div>
        <div style="padding:32px;">
          <h2 style="color:#1a1a1a; font-size:18px; margin:0 0 16px; font-weight:600;">Confirm your account</h2>
          <p style="color:#444444; font-size:14px; line-height:1.6; margin:0 0 12px;">Hi there,</p>
          <p style="color:#444444; font-size:14px; line-height:1.6; margin:0 0 12px;">
            Thanks for signing up with M.S.A.F.E. To finish setting up your account, please enter the verification code below in the app.
          </p>
          <p style="color:#444444; font-size:14px; line-height:1.6; margin:0 0 24px;">
            Your account will not be created until you verify your email.
          </p>
          <div style="text-align:center; margin:0 0 24px;">
            <span style="display:inline-block; background-color:#fbebeb; color:#B71C1C; padding:14px 28px; border-radius:6px; font-weight:bold; font-size:32px; letter-spacing:8px;">
              {otp}
            </span>
          </div>
          <p style="color:#888888; font-size:12px; line-height:1.5; margin:0 0 4px;">This code expires in {OTP_TTL_MINUTES} minutes.</p>
          <p style="color:#888888; font-size:12px; line-height:1.5; margin:0;">Enter it in the M.S.A.F.E. app on the "Enter Verification Code" screen.</p>
        </div>
        <div style="background-color:#eeeeee; padding:20px 32px;">
          <p style="color:#999999; font-size:11px; line-height:1.6; margin:0;">
            If you did not create an account with M.S.A.F.E., you can safely ignore this email. No account will be created without confirmation.
          </p>
          <p style="color:#bbbbbb; font-size:11px; margin:12px 0 0;">© 2026 M.S.A.F.E.</p>
        </div>
      </div>
    </div>
    """
