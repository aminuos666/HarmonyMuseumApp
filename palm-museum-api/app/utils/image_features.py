"""
图像特征提取器（统一入口）

特征提取方案（自动选择最优）：
  1. ONNX Runtime + ResNet-50 → 2048 维深度学习语义特征 ✅
  2. PIL + HSV 直方图 → 128 维颜色/纹理特征（降级）

优先级：深度学习 > HSV
调用方无需关心底层实现，始终通过 extract_feature_vector() 获取特征。
"""
import logging
from typing import Optional

# ── 公开 API ──
from app.utils.deep_features import extract as _deep_extract, FEATURE_DIM as _DEEP_DIM
from app.utils.image_features_hsv import extract_feature_vector as _hsv_extract
from app.utils.image_features_hsv import cosine_similarity as _hsv_cosine
from app.utils.image_features_hsv import FEATURE_DIM as _HSV_DIM

# 对外暴露的特征维度（由当前活跃的提取器决定）
FEATURE_DIM = _DEEP_DIM  # 2048


def extract_feature_vector(image_data: bytes) -> Optional[list[float]]:
    """
    提取图像特征向量。

    Priority:
      1. ResNet-50 深度学习特征（2048 维）— 真正理解图像语义
      2. HSV 颜色+纹理特征（128 维）— 仅识别颜色分布

    Args:
        image_data: 图片文件的原始字节数据

    Returns:
        L2 归一化的特征向量列表；失败返回 None
    """
    # 先尝试深度学习特征
    feat = _deep_extract(image_data)
    if feat is not None:
        return feat

    # 降级到 HSV 特征
    feat = _hsv_extract(image_data)
    return feat


def cosine_similarity(vec_a: list[float], vec_b: list[float]) -> float:
    """
    计算两个 L2 归一化向量的余弦相似度。

    兼容不同维度的特征向量（当新旧特征混存时自动适配）。
    """
    if len(vec_a) != len(vec_b):
        # 维度不一致时，用较短向量的长度计算
        min_len = min(len(vec_a), len(vec_b))
        logging.warning(f"特征维度不匹配: {len(vec_a)} vs {len(vec_b)}，截断到 {min_len}")
        vec_a_trim = vec_a[:min_len]
        vec_b_trim = vec_b[:min_len]
        # 分别归一化后点积
        norm_a = sum(v * v for v in vec_a_trim) ** 0.5
        norm_b = sum(v * v for v in vec_b_trim) ** 0.5
        if norm_a == 0 or norm_b == 0:
            return 0.0
        dot = sum(a * b for a, b in zip(vec_a_trim, vec_b_trim))
        return max(0.0, min(1.0, dot / (norm_a * norm_b)))

    dot = sum(a * b for a, b in zip(vec_a, vec_b))
    return max(0.0, min(1.0, dot))
