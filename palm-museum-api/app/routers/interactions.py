from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.database import get_db
from app.models.user import User
from app.models.artwork import Artwork
from app.models.interaction import UserLike, UserCollection
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api", tags=["互动"])


# ── 点赞 ──

@router.post("/likes/{artwork_id}")
def like_artwork(
    artwork_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """点赞文物"""
    artwork = db.query(Artwork).filter(Artwork.id == artwork_id).first()
    if not artwork:
        raise HTTPException(status_code=404, detail="文物不存在")

    existing = db.query(UserLike).filter(
        UserLike.user_id == current_user.id,
        UserLike.artwork_id == artwork_id,
    ).first()
    if existing:
        return {"message": "已经点过赞了"}

    db.add(UserLike(user_id=current_user.id, artwork_id=artwork_id))
    artwork.like_count = (artwork.like_count or 0) + 1
    db.commit()
    return {"message": "点赞成功", "is_liked": True, "like_count": artwork.like_count}


@router.delete("/likes/{artwork_id}")
def unlike_artwork(
    artwork_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """取消点赞"""
    like = db.query(UserLike).filter(
        UserLike.user_id == current_user.id,
        UserLike.artwork_id == artwork_id,
    ).first()
    if not like:
        raise HTTPException(status_code=404, detail="未点赞")

    db.delete(like)
    artwork = db.query(Artwork).filter(Artwork.id == artwork_id).first()
    if artwork and artwork.like_count > 0:
        artwork.like_count -= 1
    db.commit()
    return {"message": "已取消点赞", "is_liked": False, "like_count": artwork.like_count if artwork else 0}


@router.get("/likes")
def get_likes(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """获取用户点赞列表"""
    likes = (
        db.query(UserLike)
        .filter(UserLike.user_id == current_user.id)
        .order_by(desc(UserLike.created_at))
        .all()
    )
    return {"artwork_ids": [l.artwork_id for l in likes]}


# ── 收藏 ──

@router.post("/collections/{artwork_id}")
def collect_artwork(
    artwork_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """收藏文物"""
    artwork = db.query(Artwork).filter(Artwork.id == artwork_id).first()
    if not artwork:
        raise HTTPException(status_code=404, detail="文物不存在")

    existing = db.query(UserCollection).filter(
        UserCollection.user_id == current_user.id,
        UserCollection.artwork_id == artwork_id,
    ).first()
    if existing:
        return {"message": "已经收藏过了"}

    db.add(UserCollection(user_id=current_user.id, artwork_id=artwork_id))
    artwork.favorite_count = (artwork.favorite_count or 0) + 1
    db.commit()
    return {"message": "收藏成功", "is_favorited": True, "favorite_count": artwork.favorite_count}


@router.delete("/collections/{artwork_id}")
def uncollect_artwork(
    artwork_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """取消收藏"""
    collection = db.query(UserCollection).filter(
        UserCollection.user_id == current_user.id,
        UserCollection.artwork_id == artwork_id,
    ).first()
    if not collection:
        raise HTTPException(status_code=404, detail="未收藏")

    db.delete(collection)
    artwork = db.query(Artwork).filter(Artwork.id == artwork_id).first()
    if artwork and artwork.favorite_count > 0:
        artwork.favorite_count -= 1
    db.commit()
    return {"message": "已取消收藏", "is_favorited": False, "favorite_count": artwork.favorite_count if artwork else 0}


@router.get("/collections")
def get_collections(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """获取用户收藏列表"""
    collections = (
        db.query(UserCollection)
        .filter(UserCollection.user_id == current_user.id)
        .order_by(desc(UserCollection.created_at))
        .all()
    )
    return {"artwork_ids": [c.artwork_id for c in collections]}
