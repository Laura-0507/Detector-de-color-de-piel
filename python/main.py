import argparse
import sys

from config import BAUDRATE
from image_loader import load_image_rgb, image_to_bytes
from skin_model import analyze, Result


def show(res: Result, origen: str) -> None:
    veredicto = "SI es color de piel" if res.is_skin else "NO es color de piel"
    print(f"[{origen}] {veredicto}  (bloques densos: {res.dense_blocks})")


def main() -> int:
    ap = argparse.ArgumentParser(description="Detector de color de piel con FPGA")
    ap.add_argument("imagen", nargs="?", help="ruta del PNG (400x400)")
    ap.add_argument("--port", "-p", help="puerto serial (COM5, /dev/ttyUSB0...)")
    ap.add_argument("--baud", type=int, default=BAUDRATE)
    ap.add_argument("--simulate", action="store_true",
                    help="usar el modelo en software en vez de la FPGA")
    ap.add_argument("--verify", action="store_true",
                    help="ademas de la FPGA, correr el modelo y comparar")
    ap.add_argument("--list-ports", action="store_true",
                    help="listar puertos seriales y salir")
    args = ap.parse_args()

    if args.list_ports:
        from serial.tools import list_ports
        for p in list_ports.comports():
            print(f"{p.device}  -  {p.description}")
        return 0

    if not args.imagen:
        ap.error("falta la imagen")
    arr = load_image_rgb(args.imagen)

    if args.simulate:
        show(analyze(arr), "SOFTWARE")
        return 0

    if not args.port:
        ap.error("falta --port (usa --list-ports para verlos)")

    from serial_link import FpgaLink, FpgaError

    def progreso(enviados: int, total: int) -> None:
        print(f"\rEnviando... {100 * enviados // total}%", end="", flush=True)

    try:
        with FpgaLink(args.port, args.baud) as link:
            res = link.classify(image_to_bytes(arr), progress=progreso)
    except FpgaError as e:
        print(f"\nError: {e}")
        return 1
    print()
    show(res, "FPGA")

    if args.verify:
        ref = analyze(arr)
        show(ref, "SOFTWARE")
        ok = (ref.is_skin == res.is_skin and ref.dense_blocks == res.dense_blocks)
        print("COINCIDEN" if ok else "NO COINCIDEN: revisa que los umbrales sean iguales")
        return 0 if ok else 2
    return 0
