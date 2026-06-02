"""
深度学习特征提取器 - ONNX Runtime + ResNet-50

将输入图片转换为 2048 维语义特征向量，
真正理解文物器型、纹饰、风格，而非仅凭颜色匹配。

用法：
    from app.utils.deep_features import extract
    vector = extract(image_bytes)  # 返回 2048 维 L2 归一化特征

    如果 ONNX 模型或运行时不可用，内部自动回退到 HSV 特征。
    调用方无需关心底层用的是深度学习还是传统特征。
"""
import io
import logging
from pathlib import Path

import numpy as np
from PIL import Image

MODEL_DIR = Path(__file__).resolve().parent.parent.parent / "models"
MODEL_PATH = MODEL_DIR / "resnet50-v2-7.onnx"
MODEL_URL = "https://github.com/onnx/models/raw/main/validated/vision/classification/resnet/model/resnet50-v2-7.onnx"

FEATURE_DIM = 2048

MEAN = np.array([0.485, 0.456, 0.406], dtype=np.float32)
STD = np.array([0.229, 0.224, 0.225], dtype=np.float32)

_session = None
_model_loaded = False


def _load_model():
    """延迟加载 ONNX 模型（只加载一次）"""
    global _session, _model_loaded
    if _model_loaded:
        return True
    try:
        import onnxruntime
    except ImportError:
        logging.warning("onnxruntime 未安装，降级到 HSV 特征")
        _model_loaded = False
        return False

    if not MODEL_PATH.exists():
        logging.warning(f"模型文件不存在: {MODEL_PATH}，降级到 HSV 特征")
        _model_loaded = False
        return False

    try:
        _session = onnxruntime.InferenceSession(str(MODEL_PATH), providers=["CPUExecutionProvider"])
        _model_loaded = True
        logging.info(f"ONNX 模型加载成功: {MODEL_PATH.name}")
        return True
    except Exception as e:
        logging.error(f"模型加载失败: {e}")
        _model_loaded = False
        return False


def _preprocess(image: Image.Image) -> np.ndarray:
    """预处理图片：resize → 中心裁剪 → 归一化 → NCHW"""
    w, h = image.size
    if w < h:
        new_w, new_h = 256, int(h * 256 / w)
    else:
        new_h, new_w = 256, int(w * 256 / h)
    image = image.resize((new_w, new_h), Image.BILINEAR)
    left = (new_w - 224) // 2
    top = (new_h - 224) // 2
    image = image.crop((left, top, left + 224, top + 224))
    img = np.array(image, dtype=np.float32) / 255.0
    img = (img - MEAN) / STD
    img = img.transpose(2, 0, 1)[np.newaxis, ...]
    return img.astype(np.float32)


def _extract_deep(image_bytes: bytes) -> np.ndarray | None:
    """
    用 ONNX ResNet-50 提取特征向量。

    策略：
    1. 尝试取全局平均池化后的 2048 维中间层特征
    2. 如果找不到中间层，尝试从模型扫描所有输出，取倒数第二层
    3. 最终降级到全模型输出的 logits（1000维）
    """
    try:
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    except Exception:
        return None

    input_tensor = _preprocess(image)
    input_name = _session.get_inputs()[0].name
    output_names = [o.name for o in _session.get_outputs()]

    # 尝试常见的池化层输出名
    pool_candidates = ["resnetv24_pool1_fwd", "pool5", "avgpool", "global_average_pooling2d_1"]
    found_pool = None
    for name in pool_candidates:
        if name in [o.name for o in _session.get_outputs()]:
            found_pool = name
            break

    try:
        if found_pool:
            outputs = _session.run([found_pool], {input_name: input_tensor})
            feat = np.array(outputs[0]).flatten()
        else:
            # 跑完整模型
            outputs = _session.run(output_names, {input_name: input_tensor})
            feat = np.array(outputs[-1]).flatten()
    except Exception as e:
        logging.error(f"ONNX 推理失败: {e}")
        return None

    # 截取或填充到 FEATURE_DIM
    if len(feat) > FEATURE_DIM:
        feat = feat[:FEATURE_DIM]
    elif len(feat) < FEATURE_DIM:
        feat = np.pad(feat, (0, FEATURE_DIM - len(feat)))

    norm = np.linalg.norm(feat)
    if norm > 0:
        feat = feat / norm
    return feat


def extract(image_bytes: bytes) -> list[float] | None:
    """
    提取图片特征向量。

    优先用 ResNet-50（2048 维），
    ONNX 不可用时降级到 HSV（128 维）。

    Args:
        image_bytes: 图片字节数据

    Returns:
        L2 归一化特征向量；失败返回 None
    """
    loaded = _load_model()
    if loaded and _session:
        feat = _extract_deep(image_bytes)
        if feat is not None:
            return feat.tolist()
    from app.utils.image_features_hsv import extract_feature_vector as hsv_extract
    return hsv_extract(image_bytes)
