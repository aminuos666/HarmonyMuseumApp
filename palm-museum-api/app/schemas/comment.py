from typing import Optional
from datetime import datetime
from pydantic import BaseModel


class CommentCreate(BaseModel):
    artwork_id: str
    content: str
    parent_id: Optional[int] = None


class CommentOut(BaseModel):
    id: int
    artwork_id: str
    user_id: int
    username: str = ""
    avatar: str = ""
    content: str
    parent_id: Optional[int] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True
