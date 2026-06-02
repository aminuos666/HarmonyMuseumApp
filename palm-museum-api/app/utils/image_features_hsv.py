"""
图像特征提取器

使用 PIL/Pillow 提取图像的视觉特征向量（128维），用于以图搜图功能。

特征设计（128维）：
  - 0-31:  HSV 颜色直方图 H 通道（32 bins）
  - 32-47: HSV 颜色直方图 S 通道（16 bins）
  - 48-63: HSV 颜色直方图 V 通道（16 bins）
  - 64-95: 分块颜色矩（4×4网格，每块2个矩：均值、标准差）→ 32维
  - 96-127: 边缘方向直方图（32 bins）

所有特征拼接后做 L2 归一化，余弦相似度 = 归一化向量的点积。

真实生产环境建议：
  - 使用 ResNet-50 / ViT 等预训练模型提取语义特征
  - 使用 FAISS / Milvus / Qdrant 等专业向量数据库
  - 当前实现：基于 PIL 的轻量级特征 + MySQL 存储
"""
import math
import hashlib
from io import BytesIO
from typing import Optional

try:
    from PIL import Image, ImageStat, ImageFilter
    HAS_PIL = True
except ImportError:
    HAS_PIL = False

FEATURE_DIM = 128


def extract_feature_vector(image_data: bytes) -> Optional[list[float]]:
    """
    从图像字节数据提取 128 维特征向量

    Args:
        image_data: 图像文件的原始字节（JPEG/PNG 等）

    Returns:
        L2 归一化后的 128 维特征向量，提取失败返回 None
    """
    if not HAS_PIL:
        return _fallback_feature(image_data)

    try:
        img = Image.open(BytesIO(image_data)).convert("RGB")
        # 统一缩放到 256x256 加速处理
        img = img.resize((256, 256), Image.LANCZOS)

        features: list[float] = []

        # 1. HSV 颜色直方图 (64 维)
        hsv_hist = _hsv_histogram(img)
        features.extend(hsv_hist)

        # 2. 分块颜色矩 (32 维) — 4x4 网格，每块取均值+标准差（灰度）
        block_moments = _block_color_moments(img)
        features.extend(block_moments)

        # 3. 边缘方向直方图 (32 维) — 用 Sobel 核近似
        edge_hist = _edge_histogram(img)
        features.extend(edge_hist)

        # L2 归一化
        return _l2_normalize(features)

    except Exception as e:
        print(f"[ImageFeature] extraction error: {e}")
        return _fallback_feature(image_data)


def cosine_similarity(vec_a: list[float], vec_b: list[float]) -> float:
    """计算两个已 L2 归一化向量的余弦相似度"""
    if len(vec_a) != len(vec_b):
        return 0.0
    dot = sum(a * b for a, b in zip(vec_a, vec_b))
    # 已归一化，直接点积即为余弦相似度，夹到 [0, 1]
    return max(0.0, min(1.0, dot))


def _hsv_histogram(img: Image.Image) -> list[float]:
    """提取 HSV 颜色直方图：H 32 bins + S 16 bins + V 16 bins = 64 维"""
    h_bins, s_bins, v_bins = 32, 16, 16
    h_hist = [0.0] * h_bins
    s_hist = [0.0] * s_bins
    v_hist = [0.0] * v_bins

    hsv_img = img.convert("HSV")
    pixels = list(hsv_img.getdata())
    total = len(pixels) or 1

    for h, s, v in pixels:
        h_hist[int(h * h_bins / 256)] += 1
        s_hist[int(s * s_bins / 256)] += 1
        v_hist[int(v * v_bins / 256)] += 1

    result: list[float] = []
    for hist in (h_hist, s_hist, v_hist):
        result.extend([h / total for h in hist])
    return result


def _block_color_moments(img: Image.Image) -> list[float]:
    """提取 4×4 分块颜色矩：每块灰度均值 + 标准差 = 32 维"""
    gray = img.convert("L")
    w, h = gray.size
    grid = 4
    block_w, block_h = w // grid, h // grid

    moments: list[float] = []
    for row in range(grid):
        for col in range(grid):
            box = (col * block_w, row * block_h,
                   (col + 1) * block_w, (row + 1) * block_h)
            block = gray.crop(box)
            stat = ImageStat.Stat(block)
            mean = stat.mean[0] / 255.0 if stat.mean else 0.5
            std = stat.stddev[0] / 255.0 if stat.stddev else 0.0
            moments.append(mean)
            moments.append(std)
    return moments


def _edge_histogram(img: Image.Image) -> list[float]:
    """提取边缘方向直方图：Sobel 滤波后按梯度方向分 32 bins"""
    gray = img.convert("L")
    edges = gray.filter(ImageFilter.FIND_EDGES)
    pixels = list(edges.getdata())

    bins = 32
    hist = [0.0] * bins
    total = len(pixels) or 1

    for v in pixels:
        hist[v * bins // 256] += 1

    return [h / total for h in hist]


def _l2_normalize(vec: list[float]) -> list[float]:
    """L2 归一化"""
    norm = math.sqrt(sum(v * v for v in vec))
    if norm == 0:
        return vec
    return [v / norm for v in vec]


def _fallback_feature(image_data: bytes) -> Optional[list[float]]:
    """PIL 不可用时的回退方案：基于图像字节哈希生成确定性特征"""
    h = hashlib.sha256(image_data).digest()
    features: list[float] = []
    for i in range(FEATURE_DIM):
        # 取 2 字节合并成一个 0-1 的浮点数
        idx = (i * 2) % len(h)
        val = (h[idx] * 256 + h[(idx + 1) % len(h)]) / 65536.0
        features.append(val)
    return _l2_normalize(features)
