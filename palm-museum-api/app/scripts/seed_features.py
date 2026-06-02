"""
特征向量种子脚本

为数据库中所有文物预计算图像特征向量，存入 artwork_features 表。

用法：
    cd palm-museum-api
    python -m app.scripts.seed_features

支持两种图片来源（自动检测）：
  1. 绝对路径：直接读取本地文件
  2. 相对路径（如 /images/por_001.jpg）：从项目 images/ 目录读取
  3. HTTP URL：从远程下载（仅当本地文件不存在时）
"""
import sys
import os
from datetime import datetime
from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy.orm import Session

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from app.database import SessionLocal
from app.models.artwork import Artwork
from app.models.artwork_feature import ArtworkFeature
from app.utils.image_features import extract_feature_vector, FEATURE_DIM

# 项目根目录下的 images 文件夹
IMAGES_DIR = Path(__file__).resolve().parent.parent.parent / "images"


def read_cover_image(url: str) -> bytes | None:
    """读取封面图片，返回字节数据。支持本地路径和 HTTP URL。"""
    if not url:
        return None

    # 情况 1：绝对文件路径
    if os.path.isabs(url):
        path = Path(url)
        if path.exists():
            with open(path, "rb") as f:
                return f.read()
            return None

    # 情况 2：相对路径（如 /images/por_001.jpg）
    # 去掉开头的 / 或 \
    relative = url.lstrip("/\\")
    local_path = IMAGES_DIR / relative.replace("images/", "", 1) if "images/" in relative else IMAGES_DIR / relative
    if local_path.exists():
        with open(local_path, "rb") as f:
            return f.read()

    # 情况 3：HTTP URL — 从远程下载
    import requests
    try:
        resp = requests.get(url, timeout=15)
        resp.raise_for_status()
        return resp.content
    except Exception as e:
        print(f"  ⚠️  无法读取: {url} — {e}")
        return None


def seed_features(db: Session, force: bool = False):
    """为所有文物预计算特征向量"""
    artworks = db.query(Artwork).all()
    print(f"共 {len(artworks)} 件文物")

    created, skipped, failed = 0, 0, 0

    for artwork in artworks:
        # 检查是否已存在
        existing = (
            db.query(ArtworkFeature)
            .filter(ArtworkFeature.artwork_id == artwork.id)
            .first()
        )
        if existing and not force:
            skipped += 1
            continue

        # 读取封面图
        image_bytes = read_cover_image(artwork.cover_image)
        if not image_bytes:
            failed += 1
            print(f"  ❌ {artwork.name}: 读取封面失败 ({artwork.cover_image})")
            continue

        # 提取特征
        feature = extract_feature_vector(image_bytes)
        if not feature or len(feature) != FEATURE_DIM:
            failed += 1
            print(f"  ❌ {artwork.name}: 特征提取失败")
            continue

        # 保存
        if existing:
            existing.feature_vector = feature
            existing.feature_dim = FEATURE_DIM
            existing.updated_at = datetime.now()
        else:
            af = ArtworkFeature(
                artwork_id=artwork.id,
                feature_vector=feature,
                feature_dim=FEATURE_DIM,
            )
            db.add(af)

        created += 1
        print(f"  ✅ {artwork.name}: {FEATURE_DIM}维特征已保存")

    db.commit()
    print(f"\n完成: 新创建 {created}, 跳过 {skipped}, 失败 {failed}")


if __name__ == "__main__":
    db = SessionLocal()
    try:
        force = "--force" in sys.argv
        seed_features(db, force=force)
    finally:
        db.close()
