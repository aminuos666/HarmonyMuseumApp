from datetime import datetime

from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, UniqueConstraint
from app.database import Base


class UserLike(Base):
    """用户点赞表"""
    __tablename__ = "user_likes"
    __table_args__ = (UniqueConstraint("user_id", "artwork_id", name="uk_user_artwork_like"),)

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    artwork_id = Column(String(32), ForeignKey("artworks.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.now)


class UserCollection(Base):
    """用户收藏表"""
    __tablename__ = "user_collections"
    __table_args__ = (UniqueConstraint("user_id", "artwork_id", name="uk_user_artwork_collection"),)

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    artwork_id = Column(String(32), ForeignKey("artworks.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.now)


class BrowseHistory(Base):
    """浏览历史表"""
    __tablename__ = "browse_history"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    artwork_id = Column(String(32), ForeignKey("artworks.id"), nullable=False)
    browse_time = Column(DateTime, default=datetime.now, index=True)
