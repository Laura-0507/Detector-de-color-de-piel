"""
config.py
Todas las constantes del proyecto en un solo lugar.
IMPORTANTE: los umbrales de abajo deben ser IGUALES a los parametros
de fpga/src/skin_detector.v y skin_pixel.v, si no el PC y la FPGA
van a dar respuestas distintas.
"""

# ---------- Imagen ----------
IMG_W = 400
IMG_H = 400

# ---------- Puerto serial (UART) ----------
BAUDRATE = 460800          # debe coincidir con BAUD en fpga/src/top.v
TIMEOUT_S = 30             # segundos esperando la respuesta de la FPGA
CHUNK = 4096               # bytes que se mandan por tanda

# ---------- Protocolo ----------
HEADER = bytes([0xAA, 0x55])   # PC -> FPGA: "ahi te va una imagen"
RESP_HEADER = 0xA5             # FPGA -> PC: primer byte de la respuesta

# ---------- Deteccion de piel (YCbCr) ----------
CB_MIN, CB_MAX = 77, 127
CR_MIN, CR_MAX = 133, 173

# ---------- "Muy juntos" (bloques) ----------
BLOCK = 16          # cada bloque es de 16x16 pixeles -> 25x25 bloques
DENSE_TH = 128      # un bloque es "denso" si >= 128 de sus 256 pixeles son piel
MIN_DENSE = 20      # minimo de bloques densos para decir "si hay piel"
MIN_PAIRS = 10      # minimo de bloques densos que se tocan entre si
