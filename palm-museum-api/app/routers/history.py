from typing import Optional

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.database import get_db
from app.models.user import User
from app.models.interaction import BrowseHistory
from app.utils.dependencies import get_current_user


class AddHistoryRequest(BaseModel):
    artwork_id: str


router = APIRouter(prefix="/api/history", tags=["浏览历史"])


@router.post("")
def add_history(
    body: AddHistoryRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """添加浏览记录"""
    db.add(BrowseHistory(user_id=current_user.id, artwork_id=body.artwork_id))
    db.commit()
    return {"message": "记录成功"}


@router.get("")
def get_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """获取浏览历史"""
    records = (
        db.query(BrowseHistory)
        .filter(BrowseHistory.user_id == current_user.id)
        .order_by(desc(BrowseHistory.browse_time))
        .limit(100)
        .all()
    )
    return [
        {"artwork_id": r.artwork_id, "browse_time": r.browse_time.isoformat()}
        for r in records
    ]


@router.delete("")
def clear_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """清空浏览历史"""
    db.query(BrowseHistory).filter(BrowseHistory.user_id == current_user.id).delete()
    db.commit()
    return {"message": "已清空"}
