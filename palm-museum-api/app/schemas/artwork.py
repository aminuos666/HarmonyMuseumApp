from typing import Optional
from datetime import datetime
from pydantic import BaseModel


class ArtworkImageSchema(BaseModel):
    id: str
    url: str
    thumbnail_url: str
    title: str
    description: str
    width: int = 0
    height: int = 0

    class Config:
        from_attributes = True


class AudioGuideSchema(BaseModel):
    id: str
    url: str
    duration: int = 0
    narrator: str = ""
    text_script: str = ""

    class Config:
        from_attributes = True


class ArtworkOut(BaseModel):
    id: str
    name: str
    dynasty: str
    type: str
    material: str = ""
    description: str = ""
    detail_description: str = ""
    cover_image: str = ""
    popularity: int = 0
    like_count: int = 0
    favorite_count: int = 0
    comment_count: int = 0
    year_range: str = ""
    origin: str = ""
    dimensions: str = ""
    weight: str = ""
    collection_place: str = ""
    tags: list[str] = []
    historical_background: str = ""
    cultural_significance: str = ""
    images: list[ArtworkImageSchema] = []
    audio_guide: Optional[AudioGuideSchema] = None
    create_time: Optional[datetime] = None

    class Config:
        from_attributes = True


class ArtworkListOut(BaseModel):
    artworks: list[ArtworkOut]
    total: int
    page: int
    page_size: int


class ImageSearchResultOut(BaseModel):
    artwork: ArtworkOut
    similarity_score: float


class ImageSearchResultList(BaseModel):
    results: list[ImageSearchResultOut]
