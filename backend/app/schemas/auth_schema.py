from pydantic import BaseModel


class RequestOtpRequest(BaseModel):
    email: str


class UsernameRequest(BaseModel):
    username: str


class VerifySignupRequest(BaseModel):
    email: str
    otp: str
    first_name: str
    middle_initial: str = ""
    last_name: str
    username: str
    phone_number: str
    password: str
