import os

import numpy as np
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "test_images")
os.makedirs(OUT, exist_ok=True)
SKIN = (224, 172, 105)
BLUE = (30, 60, 160)

# 1) ovalo de piel
img = Image.new("RGB", (400, 400), BLUE)
ImageDraw.Draw(img).ellipse((100, 60, 300, 340), fill=SKIN)
img.save(os.path.join(OUT, "piel.png"))

# 2) sin piel
img = Image.new("RGB", (400, 400), (20, 140, 60))
ImageDraw.Draw(img).rectangle((0, 200, 400, 400), fill=BLUE)
img.save(os.path.join(OUT, "sin_piel.png"))

# 3) ruido disperso: 5% de pixeles piel, el resto azul
rng = np.random.default_rng(1)
arr = np.zeros((400, 400, 3), dtype=np.uint8)
arr[:] = BLUE
arr[rng.random((400, 400)) < 0.05] = SKIN
Image.fromarray(arr).save(os.path.join(OUT, "ruido_disperso.png"))

print("Listo, revisa la carpeta", os.path.abspath(OUT))
