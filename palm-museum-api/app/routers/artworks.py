from typing import Optional

from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.database import get_db
from app.models.artwork import Artwork, ArtworkImage, AudioGuide
from app.schemas.artwork import ArtworkOut, ArtworkListOut, ImageSearchResultOut, ImageSearchResultList

router = APIRouter(prefix="/api/artworks", tags=["文物"])


def _artwork_to_out(a: Artwork) -> ArtworkOut:
    images = [
        {
            "id": img.id,
            "url": img.url,
            "thumbnail_url": img.thumbnail_url,
            "title": img.title,
            "description": img.description,
            "width": img.width,
            "height": img.height,
        }
        for img in (a.images or [])
    ]
    audio = None
    if a.audio_guide:
        audio = {
            "id": a.audio_guide.id,
            "url": a.audio_guide.url,
            "duration": a.audio_guide.duration,
            "narrator": a.audio_guide.narrator,
            "text_script": a.audio_guide.text_script,
        }
    return ArtworkOut(
        id=a.id,
        name=a.name,
        dynasty=a.dynasty,
        type=a.type,
        material=a.material,
        description=a.description,
        detail_description=a.detail_description,
        cover_image=a.cover_image,
        popularity=a.popularity,
        like_count=a.like_count,
        favorite_count=a.favorite_count,
        comment_count=a.comment_count,
        year_range=a.year_range,
        origin=a.origin,
        dimensions=a.dimensions,
        weight=a.weight,
        collection_place=a.collection_place,
        tags=a.tags or [],
        historical_background=a.historical_background,
        cultural_significance=a.cultural_significance,
        images=images,
        audio_guide=audio,
        create_time=a.create_time,
    )


@router.get("", response_model=ArtworkListOut)
def list_artworks(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    sort: str = Query("default", pattern="^(default|popular|dynasty|type)$"),
    dynasty: Optional[str] = Query(None),
    type_filter: Optional[str] = Query(None, alias="type"),
    db: Session = Depends(get_db),
):
    """获取文物列表（支持分页、排序、筛选）"""
    query = db.query(Artwork)

    if dynasty:
        query = query.filter(Artwork.dynasty == dynasty)
    if type_filter:
        query = query.filter(Artwork.type == type_filter)

    if sort == "popular":
        query = query.order_by(desc(Artwork.popularity))
    elif sort == "dynasty":
        query = query.order_by(Artwork.year_range)
    elif sort == "type":
        query = query.order_by(Artwork.type)
    else:
        query = query.order_by(desc(Artwork.create_time))

    total = query.count()
    artworks = query.offset((page - 1) * page_size).limit(page_size).all()

    return ArtworkListOut(
        artworks=[_artwork_to_out(a) for a in artworks],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/daily", response_model=ArtworkOut)
def daily_recommendation(db: Session = Depends(get_db)):
    """获取每日推荐文物"""
    artwork = db.query(Artwork).order_by(desc(Artwork.popularity)).first()
    if not artwork:
        raise HTTPException(status_code=404, detail="暂无文物数据")
    return _artwork_to_out(artwork)


@router.get("/search", response_model=ArtworkListOut)
def search_artworks(
    keyword: str = Query(..., min_length=1),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
):
    """搜索文物（按名称、描述、朝代）"""
    like = f"%{keyword}%"
    query = (
        db.query(Artwork)
        .filter(
            Artwork.name.like(like)
            | Artwork.description.like(like)
            | Artwork.dynasty.like(like)
        )
        .order_by(desc(Artwork.popularity))
    )
    total = query.count()
    artworks = query.offset((page - 1) * page_size).limit(page_size).all()
    return ArtworkListOut(
        artworks=[_artwork_to_out(a) for a in artworks],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/batch", response_model=list[ArtworkOut])
def batch_artworks(ids: str = Query(..., description="逗号分隔的ID列表"), db: Session = Depends(get_db)):
    """批量获取文物（用于浏览历史、点赞列表等）"""
    id_list = [i.strip() for i in ids.split(",") if i.strip()]
    artworks = db.query(Artwork).filter(Artwork.id.in_(id_list)).all()
    return [_artwork_to_out(a) for a in artworks]


@router.get("/{artwork_id}", response_model=ArtworkOut)
def get_artwork(artwork_id: str, db: Session = Depends(get_db)):
    """获取文物详情"""
    artwork = db.query(Artwork).filter(Artwork.id == artwork_id).first()
    if not artwork:
        raise HTTPException(status_code=404, detail="文物不存在")
    return _artwork_to_out(artwork)
