import random

from fastapi import APIRouter, UploadFile, File, Depends
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.database import get_db
from app.models.artwork import Artwork
from app.schemas.artwork import ImageSearchResultOut, ImageSearchResultList

router = APIRouter(prefix="/api/image-search", tags=["以图搜图"])


def _artwork_simple(a: Artwork) -> dict:
    return {
        "id": a.id,
        "name": a.name,
        "dynasty": a.dynasty,
        "type": a.type,
        "material": a.material,
        "description": a.description,
        "cover_image": a.cover_image,
        "popularity": a.popularity,
        "like_count": a.like_count,
        "favorite_count": a.favorite_count,
        "comment_count": a.comment_count,
        "year_range": a.year_range,
        "origin": a.origin,
        "dimensions": a.dimensions,
        "weight": a.weight,
        "collection_place": a.collection_place,
        "tags": a.tags or [],
        "historical_background": a.historical_background,
        "cultural_significance": a.cultural_significance,
        "images": [],
        "audio_guide": None,
    }


@router.post("", response_model=ImageSearchResultList)
async def image_search(file: UploadFile = File(...), db: Session = Depends(get_db)):
    """
    以图搜图：上传图片，返回相似文物列表

    当前实现为模拟特征匹配，返回热度最高的文物作为结果。
    真实场景应使用图像特征提取模型 + 向量数据库检索。
    """
    all_artworks = db.query(Artwork).order_by(desc(Artwork.popularity)).limit(20).all()

    results = []
    for i, artwork in enumerate(all_artworks):
        score = round(random.uniform(60, 99), 1)
        results.append({
            "artwork": _artwork_simple(artwork),
            "similarity_score": score,
        })

    results.sort(key=lambda x: x["similarity_score"], reverse=True)
    return ImageSearchResultList(results=results[:10])
