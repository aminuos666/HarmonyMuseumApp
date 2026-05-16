from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.database import get_db
from app.models.user import User
from app.models.artwork import Artwork
from app.models.comment import Comment
from app.schemas.comment import CommentCreate, CommentOut
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/comments", tags=["评论"])


@router.get("/{artwork_id}", response_model=list[CommentOut])
def list_comments(artwork_id: str, db: Session = Depends(get_db)):
    """获取文物的所有评论"""
    comments = (
        db.query(Comment)
        .filter(Comment.artwork_id == artwork_id)
        .order_by(desc(Comment.created_at))
        .all()
    )
    result = []
    for c in comments:
        user = db.query(User).filter(User.id == c.user_id).first()
        result.append(CommentOut(
            id=c.id,
            artwork_id=c.artwork_id,
            user_id=c.user_id,
            username=user.nickname if user else "未知用户",
            avatar=user.avatar if user else "",
            content=c.content,
            parent_id=c.parent_id,
            created_at=c.created_at,
        ))
    return result


@router.post("", response_model=CommentOut, status_code=status.HTTP_201_CREATED)
def create_comment(
    body: CommentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """发表评论"""
    artwork = db.query(Artwork).filter(Artwork.id == body.artwork_id).first()
    if not artwork:
        raise HTTPException(status_code=404, detail="文物不存在")

    comment = Comment(
        artwork_id=body.artwork_id,
        user_id=current_user.id,
        content=body.content,
        parent_id=body.parent_id,
    )
    db.add(comment)
    artwork.comment_count = (artwork.comment_count or 0) + 1
    db.commit()
    db.refresh(comment)

    return CommentOut(
        id=comment.id,
        artwork_id=comment.artwork_id,
        user_id=comment.user_id,
        username=current_user.nickname,
        avatar=current_user.avatar or "",
        content=comment.content,
        parent_id=comment.parent_id,
        created_at=comment.created_at,
    )
