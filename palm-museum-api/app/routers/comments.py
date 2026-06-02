from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.database import get_db
from app.models.user import User
from app.models.artwork import Artwork
from app.models.comment import Comment
from app.models.comment_like import CommentLike
from app.schemas.comment import CommentCreate, CommentOut
from app.utils.dependencies import get_current_user, get_optional_user

router = APIRouter(prefix="/api/comments", tags=["评论"])


def _build_comment_out(
    c: Comment,
    db: Session,
    current_user_id: int | None = None,
) -> CommentOut:
    """构建 CommentOut，填充用户名、头像、点赞数、是否已点赞"""
    user = db.query(User).filter(User.id == c.user_id).first()
    like_count = db.query(CommentLike).filter(CommentLike.comment_id == c.id).count()
    is_liked = False
    if current_user_id is not None:
        is_liked = (
            db.query(CommentLike)
            .filter(
                CommentLike.user_id == current_user_id,
                CommentLike.comment_id == c.id,
            )
            .first()
            is not None
        )
    return CommentOut(
        id=c.id,
        artwork_id=c.artwork_id,
        user_id=c.user_id,
        username=user.nickname if user else "未知用户",
        avatar=user.avatar if user else "",
        content=c.content,
        parent_id=c.parent_id,
        created_at=c.created_at,
        like_count=like_count,
        is_liked=is_liked,
        replies=[],
    )


@router.get("/{artwork_id}", response_model=list[CommentOut])
def list_comments(
    artwork_id: str,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_optional_user),
):
    """获取文物的所有评论（按时间倒序），已按 parent_id 嵌套回复"""
    all_comments = (
        db.query(Comment)
        .filter(Comment.artwork_id == artwork_id)
        .order_by(desc(Comment.created_at))
        .all()
    )
    current_user_id = current_user.id if current_user else None

    # 先构建所有 CommentOut（不含 replies）
    comment_map: dict[int, CommentOut] = {}
    for c in all_comments:
        comment_map[c.id] = _build_comment_out(c, db, current_user_id)

    # 按 parent_id 嵌套
    top_level: list[CommentOut] = []
    for c in all_comments:
        out = comment_map[c.id]
        if c.parent_id and c.parent_id in comment_map:
            comment_map[c.parent_id].replies.append(out)
        else:
            top_level.append(out)

    return top_level


@router.post("", response_model=CommentOut, status_code=status.HTTP_201_CREATED)
def create_comment(
    body: CommentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """发表评论或回复（设置 parent_id 即为回复）"""
    artwork = db.query(Artwork).filter(Artwork.id == body.artwork_id).first()
    if not artwork:
        raise HTTPException(status_code=404, detail="文物不存在")

    if body.parent_id is not None:
        parent = db.query(Comment).filter(Comment.id == body.parent_id).first()
        if not parent:
            raise HTTPException(status_code=404, detail="回复的评论不存在")

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

    return _build_comment_out(comment, db, current_user.id)


@router.post("/{comment_id}/like", response_model=dict)
def like_comment(
    comment_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """点赞评论"""
    comment = db.query(Comment).filter(Comment.id == comment_id).first()
    if not comment:
        raise HTTPException(status_code=404, detail="评论不存在")

    existing = (
        db.query(CommentLike)
        .filter(
            CommentLike.user_id == current_user.id,
            CommentLike.comment_id == comment_id,
        )
        .first()
    )
    if existing:
        raise HTTPException(status_code=409, detail="已经点过赞了")

    like = CommentLike(user_id=current_user.id, comment_id=comment_id)
    db.add(like)
    db.commit()
    like_count = db.query(CommentLike).filter(CommentLike.comment_id == comment_id).count()
    return {"is_liked": True, "like_count": like_count}


@router.delete("/{comment_id}/like", response_model=dict)
def unlike_comment(
    comment_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """取消点赞评论"""
    existing = (
        db.query(CommentLike)
        .filter(
            CommentLike.user_id == current_user.id,
            CommentLike.comment_id == comment_id,
        )
        .first()
    )
    if not existing:
        raise HTTPException(status_code=404, detail="未点赞")

    db.delete(existing)
    db.commit()
    like_count = db.query(CommentLike).filter(CommentLike.comment_id == comment_id).count()
    return {"is_liked": False, "like_count": like_count}
