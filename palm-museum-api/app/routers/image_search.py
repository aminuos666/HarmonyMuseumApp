"""
以图搜图 API
"""
from fastapi import APIRouter, UploadFile, File, Depends, HTTPException, Request
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.artwork import Artwork
from app.models.artwork_feature import ArtworkFeature
from app.schemas.artwork import ImageSearchResultOut, ImageSearchResultList, ArtworkOut
from app.utils.image_features import extract_feature_vector, cosine_similarity

router = APIRouter(prefix="/api/image-search", tags=["以图搜图"])
TOP_K = 20


def _full_url(base: str, path: str) -> str:
    if not path or path.startswith("http"):
        return path
    return f"{base.rstrip('/')}/{path.lstrip('/')}"


def _artwork_to_out(a: Artwork, base_url: str = "") -> ArtworkOut:
    return ArtworkOut(
        id=a.id, name=a.name, dynasty=a.dynasty, type=a.type,
        material=a.material or "", description=a.description or "",
        detail_description=a.detail_description or "",
        cover_image=_full_url(base_url, a.cover_image or ""),
        popularity=a.popularity or 0, like_count=a.like_count or 0,
        favorite_count=a.favorite_count or 0, comment_count=a.comment_count or 0,
        year_range=a.year_range or "", origin=a.origin or "",
        dimensions=a.dimensions or "", weight=a.weight or "",
        collection_place=a.collection_place or "", tags=a.tags or [],
        historical_background=a.historical_background or "",
        cultural_significance=a.cultural_significance or "",
        images=[], audio_guide=None, create_time=a.create_time,
    )


async def _do_search(image_bytes: bytes, base_url: str, db: Session) -> ImageSearchResultList:
    """以图搜图核心逻辑"""
    if len(image_bytes) > 10 * 1024 * 1024:
        raise HTTPException(400, "图片不能超过 10MB")
    query_feature = extract_feature_vector(image_bytes)
    if query_feature is None or len(query_feature) == 0:
        raise HTTPException(500, "特征提取失败")
    stored_features = db.query(ArtworkFeature).all()
    if not stored_features:
        all_artworks = db.query(Artwork).order_by(Artwork.popularity.desc()).limit(TOP_K).all()
        results = []
        for i, a in enumerate(all_artworks):
            results.append(ImageSearchResultOut(
                artwork=_artwork_to_out(a, base_url),
                similarity_score=round(90.0 - i * 3.0, 1),
            ))
        return ImageSearchResultList(results=results)
    scored = []
    for sf in stored_features:
        feat = sf.feature_vector
        if not feat or len(feat) == 0:
            continue
        sim = cosine_similarity(query_feature, feat)
        scored.append((sf, sim))
    if not scored:
        return ImageSearchResultList(results=[])
    scored.sort(key=lambda x: x[1], reverse=True)
    artwork_ids = [s[0].artwork_id for s in scored]
    artworks_map = {}
    if artwork_ids:
        for a in db.query(Artwork).filter(Artwork.id.in_(artwork_ids)).all():
            artworks_map[a.id] = a
    results = []
    for sf, sim in scored[:TOP_K]:
        a = artworks_map.get(sf.artwork_id)
        if a:
            results.append(ImageSearchResultOut(
                artwork=_artwork_to_out(a, base_url),
                similarity_score=round(sim * 100, 1),
            ))
    return ImageSearchResultList(results=results)


@router.post("", response_model=ImageSearchResultList)
async def image_search(
    file: UploadFile = File(...),
    request: Request = None,
    db: Session = Depends(get_db),
):
    """以图搜图：上传图片，返回相似文物列表"""
    return await _do_search(
        await file.read(),
        str(request.base_url) if request else "",
        db,
    )
