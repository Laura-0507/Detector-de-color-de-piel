
import numpy as np
from PIL import Image

from config import IMG_W, IMG_H


def load_image_rgb(path: str, resize: bool = True) -> np.ndarray:
    """Devuelve un arreglo (400, 400, 3) de uint8 con orden R, G, B."""
    img = Image.open(path).convert("RGB")   # quita el canal alfa si el PNG lo trae
    if img.size != (IMG_W, IMG_H):
        if not resize:
            raise ValueError(f"La imagen es {img.size}, debe ser {IMG_W}x{IMG_H}")
        img = img.resize((IMG_W, IMG_H), Image.LANCZOS)
    return np.asarray(img, dtype=np.uint8)


def image_to_bytes(arr: np.ndarray) -> bytes:
    """Aplana la imagen fila por fila: R,G,B del pixel (0,0), luego (0,1), ..."""
    return arr.tobytes()   # 400*400*3 = 480000 bytes
