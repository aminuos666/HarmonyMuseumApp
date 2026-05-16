from datetime import datetime

from sqlalchemy import Column, Integer, String, Text, DateTime, Date
from app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    account = Column(String(100), unique=True, nullable=False, index=True)
    password = Column(String(200), nullable=False)  # bcrypt hash
    nickname = Column(String(50), default="")
    avatar = Column(String(500), default="")
    phone = Column(String(20), default="")
    email = Column(String(100), default="")
    gender = Column(String(10), default="")
    birthday = Column(Date, nullable=True)
    signature = Column(String(200), default="")
    created_at = Column(DateTime, default=datetime.now)
