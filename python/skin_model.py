from dataclasses import dataclass
from typing import Optional

import numpy as np

from config import (IMG_W, IMG_H, BLOCK, DENSE_TH, MIN_DENSE, MIN_PAIRS,
                    CB_MIN, CB_MAX, CR_MIN, CR_MAX)


@dataclass
class Result:
    is_skin: bool
    dense_blocks: int
    pairs: Optional[int] = None   # la FPGA no lo devuelve, el modelo si


def skin_mask(arr: np.ndarray) -> np.ndarray:
    """Matriz booleana (400,400): True donde el pixel parece piel."""
    r = arr[..., 0].astype(np.int32)
    g = arr[..., 1].astype(np.int32)
    b = arr[..., 2].astype(np.int32)
    # '>> 8' equivale a dividir entre 256 (igual que '>>> 8' en Verilog)
    cb = ((-43 * r - 85 * g + 128 * b) >> 8) + 128
    cr = ((128 * r - 107 * g - 21 * b) >> 8) + 128
    return (cb >= CB_MIN) & (cb <= CB_MAX) & (cr >= CR_MIN) & (cr <= CR_MAX)


def analyze(arr: np.ndarray) -> Result:
    mask = skin_mask(arr)
    # cuantos pixeles de piel hay en cada bloque de 16x16 -> matriz 25x25
    counts = mask.reshape(IMG_H // BLOCK, BLOCK, IMG_W // BLOCK, BLOCK).sum(axis=(1, 3))
    dense = counts >= DENSE_TH
    total = int(dense.sum())
    horizontal = int((dense[:, 1:] & dense[:, :-1]).sum())
    vertical = int((dense[1:, :] & dense[:-1, :]).sum())
    pairs = horizontal + vertical
    return Result(is_skin=(total >= MIN_DENSE and pairs >= MIN_PAIRS),
                  dense_blocks=total, pairs=pairs)
