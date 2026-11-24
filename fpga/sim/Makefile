# Makefile - simulacion con Icarus Verilog (iverilog + vvp)
#   make            corre los 5 testbenches rapidos
#   make skin_pixel / uart_rx / uart_tx / loopback / detector
#   make top        el sistema completo (tarda mas)
#   make wave T=skin_pixel   abre la forma de onda en GTKWave (si lo tienes)
#   make clean
SRC = ../src/skin_pixel.v ../src/uart_rx.v ../src/uart_tx.v ../src/skin_detector.v ../src/top.v
TB  = ../tb
IV  = iverilog -g2012 -Wall -Wno-timescale

.PHONY: all skin_pixel uart_rx uart_tx loopback detector top clean wave
all: skin_pixel uart_rx uart_tx loopback detector

build:
	mkdir -p build

skin_pixel uart_rx uart_tx detector top: %: build
	$(IV) -o build/$@.vvp $(TB)/tb_$(if $(filter detector,$@),skin_detector,$@).v $(SRC)
	vvp -n build/$@.vvp | tee build/$@.log
	@! grep -q FAIL build/$@.log

loopback: build
	$(IV) -o build/loopback.vvp $(TB)/tb_uart_loopback.v $(SRC)
	vvp -n build/loopback.vvp | tee build/loopback.log
	@! grep -q FAIL build/loopback.log

wave: build
	@echo "Agrega  \$$dumpfile(\"build/$(T).vcd\"); \$$dumpvars;  al testbench y luego: gtkwave build/$(T).vcd"

clean:
	rm -rf build
