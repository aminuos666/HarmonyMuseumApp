from datetime import datetime

from sqlalchemy import Column, Integer, String, DateTime, JSON, UniqueConstraint, Index
from app.database import Base


class ArtworkFeature(Base):
    """文物图像特征向量表

    存储每个文物封面图的 128 维特征向量，用于以图搜图的余弦相似度检索。
    artwork_id 引用 artworks.id，但不使用数据库级外键以避免 charset 兼容问题。
    """
    __tablename__ = "artwork_features"
    __table_args__ = (UniqueConstraint("artwork_id", name="uk_artwork_feature"),)

    id = Column(Integer, primary_key=True, autoincrement=True)
    artwork_id = Column(String(32), nullable=False, unique=True, index=True)
    feature_vector = Column(JSON, nullable=False)
    feature_dim = Column(Integer, default=128)
    created_at = Column(DateTime, default=datetime.now)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)
