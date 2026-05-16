from typing import Optional
from datetime import date, datetime
from pydantic import BaseModel


# ── 请求体 ──

class RegisterRequest(BaseModel):
    account: str
    password: str
    nickname: str


class LoginRequest(BaseModel):
    account: str
    password: str


class UpdateProfileRequest(BaseModel):
    nickname: Optional[str] = None
    avatar: Optional[str] = None
    gender: Optional[str] = None
    birthday: Optional[date] = None
    signature: Optional[str] = None


class ChangePasswordRequest(BaseModel):
    old_password: str
    new_password: str


# ── 响应体 ──

class UserOut(BaseModel):
    id: int
    account: str
    nickname: str = ""
    avatar: str = ""
    phone: str = ""
    email: str = ""
    gender: str = ""
    birthday: Optional[date] = None
    signature: str = ""
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class BrowseHistoryOut(BaseModel):
    artwork_id: str
    browse_time: datetime
