# Detector-de-color-de-piel
Laura Sanabria y Juan Triviño


# Declaración de IA

**Autores:** Juan José Triviño Baquero y Laura Juliana Sanabria  
**Institución:** Escuela Colombiana de Ingeniería Julio Garavito

---

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

## 4. Compromiso de los Autores

Los autores se comprometen a mantener el dominio técnico y el control sobre la arquitectura y la lógica del proyecto, verificando que todo código generado u optimizado con asistencia de IA esté debidamente revisado, probado y alineado con la estructura base y los criterios de integridad académica y técnica del trabajo.
