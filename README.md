# Detector-de-color-de-piel
**Autores:** Laura Sanabria y Juan Triviño


# Declaración de IA


## 1. Declaración de Uso y Metodología de Validación

Por medio del presente apartado, los autores declaran que en este proyecto se emplearon herramientas de Inteligencia Artificial (IA) principalmente para la generación de bancos de pruebas (*testbenches*) orientados a la verificación de módulos, y en el resto del desarrollo como apoyo para la **optimización de código**.

El uso de IA se realizó sobre una **estructura base** previamente definida y comprendida por los autores (arquitectura del sistema, módulos principales, señales, interfaces y lógica esperada). Contar con claridad sobre esa estructura base permitió contrastar los resultados de simulación y revisión contra el diseño esperado para verificar que cada componente esté bien implementado y cumpla con las especificaciones del proyecto.

---

## 2. Criterios de Verificación Aplicados

Para validar el código asistido por IA a partir de la estructura base establecida, se aplicaron los siguientes criterios:

* **Verificación mediante *testbenches*:** Evaluación de estímulos, casos normales y condiciones de borde en simulación para comprobar el comportamiento funcional de cada módulo frente a la estructura base.
* **Optimización y coherencia con la estructura base:** Revisión de mejoras de legibilidad, síntesis o eficiencia para confirmar que no alteran la interfaz, los tiempos ni la lógica definida por los autores.

---

## 3. Registro de Códigos Generados u Optimizados con IA

### 3.1. *Testbenches* para prueba de módulos

| Archivo / Módulo | Lenguaje | Uso de IA | Verificación realizada |
| :--- | :--- | :--- | :--- |
| `tb_skin_detector.v` | Verilog | *Testbench* para prueba del módulo detector de piel. | Simulación de estímulos y contraste de salidas con la estructura base. |
| `tb_skin_pixel.v` | Verilog | *Testbench* para prueba del procesamiento por píxel. | Validación de casos de prueba y revisión de señales en simulación. |
| `tb_top.v` | Verilog | *Testbench* de integración para prueba del módulo superior (*top*). | Verificación del flujo general y señales entre módulos según diseño base. |
| `tb_uart_loopback.v` | Verilog | *Testbench* para prueba de comunicación UART en modo *loopback*. | Comprobación de transmisión/recepción y sincronización de tramas. |
| `tb_uart_rx.v` | Verilog | *Testbench* para prueba del receptor UART (*RX*). | Evaluación de recepción de bits, *baud rate* y condiciones de borde. |
| `tb_uart_tx.v` | Verilog | *Testbench* para prueba del transmisor UART (*TX*). | Verificación de tramas transmitidas y temporización frente al diseño base. |

---

## 4. Uso de IA en Código Python

Dado que el enfoque principal del curso es el diseño digital en Verilog, la parte en Python no constituye el núcleo del trabajo y se realizó mayoritariamente con apoyo de IA. El esfuerzo de los autores en este bloque se centró en entender qué hace cada módulo de Python, su rol dentro del flujo general y cómo interactúa con el sistema, comprobando que cumpla su función de apoyo sin desviar la atención del diseño en Verilog.

---

## 5. Compromiso de los Autores

Los autores se comprometen a mantener el dominio técnico y el control sobre la arquitectura y la lógica del proyecto, verificando que todo código generado u optimizado con asistencia de IA esté debidamente revisado, probado y alineado con la estructura base y los criterios de integridad académica y técnica del trabajo.

# Conexión de Hardware al PC

El montaje requiere **dos cables USB** conectados al PC (uno por placa) y **tres cables Dupont** entre las placas:

### Cables USB hacia el PC
* **Tang Nano 9K → PC:** Cable **USB-C a USB-C** (alimenta la placa y permite cargar el *bitstream* desde Gowin EDA).
* **FT232R (YP-05) → PC:** Cable **USB-A a mini-USB** (transmite los datos de imagen; genera un puerto serie como `COM5` en Windows o `/dev/ttyUSB0` en Linux/Mac para usar en `--port`).

### Conexión entre placas (UART)

| Pin FT232R (YP-05) | Dirección | Pin Tang Nano 9K | Función |
| :--- | :---: | :--- | :--- |
| **TXD** | $\rightarrow$ | **Pin 25** (`uart_rx`) | Envío de píxeles hacia la FPGA |
| **RXD** | $\leftarrow$ | **Pin 26** (`uart_tx`) | Recepción del resultado desde la FPGA |
| **GND** | $\longleftrightarrow$ | **GND** | Tierra común |
| **VCC** | $\times$ | *No conectar* | Evita conflictos de alimentación |

---
#  Guía de Puesta en Marcha y Pruebas

1. **Prueba solo el Python (sin hardware):** Entra a la carpeta `python`, instala las dependencias con `pip install -r requirements.txt`, genera las imágenes de prueba con `python make_test_images.py` y ejecuta `python main.py ../test_images/piel.png --simulate`. Debe responder **SÍ**, mientras que `sin_piel.png` y `ruido_disperso.png` deben responder **NO**; si esto falla, el problema es de Python y no del hardware.
2. **Carga la FPGA (Gowin EDA):** Crea un nuevo proyecto con el dispositivo `GW1NR-LV9QN88PC6/I5`, agrega los 5 archivos de `fpga/src/` y el archivo `.cst` asignando `top` como módulo superior, ejecuta *Synthesize* y luego *Place & Route*, y usa *Programmer* para cargar el *bitstream* (en **SRAM** para probar de forma volátil, o en **Flash** para que quede grabado).
3. **Encuentra el puerto del FT232R:** Ejecuta `python main.py --list-ports` para identificar el puerto serie (por ejemplo, `COM5` en Windows o `/dev/ttyUSB0` en Linux/Mac). Si no aparece, instala el driver FTDI (VCP).
4. **Prueba el FT232R solo (aislar el módulo):** Desconecta los cables hacia la FPGA, une `TXD` con `RXD` del módulo FT232R con un cable y ejecuta en Python interactivo (a `460800` baudios y ajustando el puerto): `import serial`, `s = serial.Serial("COM5", 460800, timeout=1)` y `s.write(b"hola"); print(s.read(4))`. Debe imprimir `b'hola'`; si es así, el módulo y el driver están bien. Retira el puente y vuelve a conectar a la FPGA.
5. **La prueba real:** Ejecuta `python main.py ../test_images/piel.png --port COM5 --verify`. Ten paciencia porque enviar 480 000 bytes a 460 800 baudios tarda unos **10 segundos** (no se colgó). Con `piel.png` se espera **SÍ** (con 169 bloques densos y coincidencia con el cálculo por software del PC gracias a `--verify`), con `sin_piel.png` y `ruido_disperso.png` debe dar **NO**, y al final puedes probar con una foto tuya de **400×400**.
