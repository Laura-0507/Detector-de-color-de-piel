"""
test_skin_model.py  -  pruebas de la parte de Python (solo libreria estandar: unittest)

Correr desde la carpeta python/ :
    python -m unittest discover -s tests -v

Los numeros esperados (densos / pares) son los MISMOS que usa el testbench
fpga/tb/tb_skin_detector.v, asi el modelo en Python y la FPGA se prueban con
las mismas imagenes.
"""
import os
import sys
import unittest
from unittest import mock

import numpy as np

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))

from skin_model import analyze, skin_mask   # noqa: E402
from config import HEADER, RESP_HEADER, IMG_W, IMG_H   # noqa: E402

SKIN = (224, 172, 105)
BLUE = (30, 60, 160)
YY, XX = np.mgrid[0:400, 0:400]

# (nombre, mascara de piel, densos, pares, veredicto)  = mismos casos del testbench
CASOS = [
    ("cuadro 13x13 bloques", (XX >= 96) & (XX < 304) & (YY >= 96) & (YY < 304), 169, 312, True),
    ("disperso 1 de cada 9", (XX % 3 == 0) & (YY % 3 == 0), 0, 0, False),
    ("solo 3x3 bloques", (XX < 48) & (YY < 48), 9, 12, False),
    ("solo 5x5 bloques", (XX < 80) & (YY < 80), 25, 40, True),
    ("columnas pares", (XX % 2 == 0), 625, 1200, True),
    ("columnas pares sin fila 0", (XX % 2 == 0) & (YY != 0), 600, 1151, True),
]


def imagen(mask):
    a = np.zeros((IMG_H, IMG_W, 3), np.uint8)
    a[:] = BLUE
    a[mask] = SKIN
    return a


class TestPixel(unittest.TestCase):
    def test_pixeles_conocidos(self):
        casos = {(224, 172, 105): True, (241, 194, 160): True, (30, 60, 160): False,
                 (20, 140, 60): False, (200, 30, 30): False, (0, 0, 0): False, (255, 255, 255): False}
        for rgb, esperado in casos.items():
            a = np.array([[rgb]], dtype=np.uint8)
            self.assertEqual(bool(skin_mask(a)[0, 0]), esperado, rgb)


class TestImagenes(unittest.TestCase):
    def test_casos_del_testbench(self):
        for nombre, mask, densos, pares, veredicto in CASOS:
            with self.subTest(nombre):
                r = analyze(imagen(mask))
                self.assertEqual(r.dense_blocks, densos)
                self.assertEqual(r.pairs, pares)
                self.assertEqual(r.is_skin, veredicto)


class TestSerialLink(unittest.TestCase):
    """Prueba el protocolo con un puerto serial falso (sin hardware)."""

    def test_envia_cabecera_y_lee_respuesta(self):
        enviado = bytearray()

        class FakeSerial:
            is_open = True

            def __init__(self, *a, **k):
                pass

            def reset_input_buffer(self):
                pass

            def write(self, data):
                enviado.extend(data)

            def flush(self):
                pass

            def read(self, n):
                return bytes([RESP_HEADER, 1, 0, 169])   # A5, SI, 169 bloques

            def close(self):
                self.is_open = False

        import serial_link
        with mock.patch.object(serial_link.serial, "Serial", FakeSerial):
            with serial_link.FpgaLink("FAKE") as link:
                res = link.classify(bytes(480000))
        self.assertEqual(bytes(enviado[:2]), HEADER)
        self.assertEqual(len(enviado), 2 + 480000)
        self.assertTrue(res.is_skin)
        self.assertEqual(res.dense_blocks, 169)

    def test_respuesta_corta_da_error(self):
        class FakeSerial:
            is_open = True

            def __init__(self, *a, **k):
                pass

            def reset_input_buffer(self):
                pass

            def write(self, data):
                pass

            def flush(self):
                pass

            def read(self, n):
                return b""

            def close(self):
                pass

        import serial_link
        with mock.patch.object(serial_link.serial, "Serial", FakeSerial):
            with serial_link.FpgaLink("FAKE") as link:
                with self.assertRaises(serial_link.FpgaError):
                    link.classify(bytes(10))


if __name__ == "__main__":
    unittest.main()
