import time
from typing import Callable, Optional

import serial   # pip install pyserial

from config import BAUDRATE, TIMEOUT_S, CHUNK, HEADER, RESP_HEADER
from skin_model import Result


class FpgaError(Exception):
    pass


class FpgaLink:
    def __init__(self, port: str, baud: int = BAUDRATE, timeout: float = TIMEOUT_S):
        self.ser = serial.Serial(port, baud, bytesize=8, parity="N",
                                 stopbits=1, timeout=timeout)

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        self.close()

    def close(self):
        if self.ser.is_open:
            self.ser.close()

    def classify(self, payload: bytes,
                 progress: Optional[Callable[[int, int], None]] = None) -> Result:
        self.ser.reset_input_buffer()
        self.ser.write(HEADER)
        total = len(payload)
        for i in range(0, total, CHUNK):
            self.ser.write(payload[i:i + CHUNK])
            if progress:
                progress(min(i + CHUNK, total), total)
        self.ser.flush()

        resp = self.ser.read(4)
        if len(resp) < 4:
            raise FpgaError("La FPGA no respondio a tiempo. Revisa cables TX/RX, "
                            "baudrate y que el bitstream este cargado.")
        if resp[0] != RESP_HEADER:
            raise FpgaError(f"Respuesta rara: {resp.hex()} (se esperaba A5 ..)")
        dense = ((resp[2] & 0x03) << 8) | resp[3]
        return Result(is_skin=bool(resp[1] & 1), dense_blocks=dense)
