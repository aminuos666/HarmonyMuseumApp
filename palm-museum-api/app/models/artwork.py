from datetime import datetime

from sqlalchemy import Column, Integer, String, Text, Float, ForeignKey, DateTime, JSON
from sqlalchemy.orm import relationship

from app.database import Base


class Artwork(Base):
    __tablename__ = "artworks"

    id = Column(String(32), primary_key=True)
    name = Column(String(200), nullable=False, index=True)
    dynasty = Column(String(50), nullable=False, index=True)
    type = Column(String(50), nullable=False, index=True)
    material = Column(String(50), default="")
    description = Column(Text, default="")
    detail_description = Column(Text, default="")
    cover_image = Column(String(500), default="")
    popularity = Column(Integer, default=0)
    like_count = Column(Integer, default=0)
    favorite_count = Column(Integer, default=0)
    comment_count = Column(Integer, default=0)
    year_range = Column(String(50), default="")
    origin = Column(String(200), default="")
    dimensions = Column(String(200), default="")
    weight = Column(String(50), default="")
    collection_place = Column(String(200), default="")
    tags = Column(JSON, default=list)
    historical_background = Column(Text, default="")
    cultural_significance = Column(Text, default="")
    create_time = Column(DateTime, default=datetime.now)

    images = relationship("ArtworkImage", back_populates="artwork", cascade="all, delete-orphan")
    audio_guide = relationship("AudioGuide", uselist=False, back_populates="artwork", cascade="all, delete-orphan")


class ArtworkImage(Base):
    __tablename__ = "artwork_images"

    id = Column(String(64), primary_key=True)
    artwork_id = Column(String(32), ForeignKey("artworks.id"), nullable=False)
    url = Column(String(500), default="")
    thumbnail_url = Column(String(500), default="")
    title = Column(String(200), default="")
    description = Column(String(500), default="")
    width = Column(Integer, default=0)
    height = Column(Integer, default=0)

    artwork = relationship("Artwork", back_populates="images")


class AudioGuide(Base):
    __tablename__ = "audio_guides"

    id = Column(String(64), primary_key=True)
    artwork_id = Column(String(32), ForeignKey("artworks.id"), nullable=False, unique=True)
    url = Column(String(500), default="")
    duration = Column(Integer, default=0)
    narrator = Column(String(100), default="")
    text_script = Column(Text, default="")

    artwork = relationship("Artwork", back_populates="audio_guide")
