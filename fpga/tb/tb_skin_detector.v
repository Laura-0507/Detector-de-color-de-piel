`timescale 1ns/1ps
// tb_skin_detector.v
// Prueba el cerebro (FSM) SIN el UART: se le entregan los bytes directo con
// rx_valid y se captura lo que pide transmitir (tx_start / tx_data).
//
// Se mandan 6 imagenes de 400x400 generadas por formulas y, para cada una, se
// compara contra los numeros esperados (calculados con skin_model.py, mismos
// patrones en python/tests/test_skin_model.py):
//
//   caso  imagen                                   densos  pares  veredicto
//    0    cuadro de piel 13x13 bloques             169     312    SI
//    1    pixeles de piel dispersos (1 de cada 9)  0       0      NO
//    2    solo 3x3 bloques de piel                 9       12     NO  (muy pocos)
//    3    solo 5x5 bloques de piel                 25      40     SI
//    4    columnas pares de piel (todo denso)      625     1200   SI  (maximos)
//    5    igual que 4 pero sin la fila y=0         600     1151   SI  (borde: 120 < 128)
//
// Tambien se prueba la cabecera: antes de la primera imagen se mandan bytes
// basura y un AA suelto, y el detector debe ignorarlos.
module tb_skin_detector;
    localparam GAP = 32;    // ciclos de reloj entre bytes (el barrido necesita ~27)

    reg        clk = 0, rst_n = 0;
    reg  [7:0] rx_data = 0;
    reg        rx_valid = 0;
    wire [7:0] tx_data;
    wire       tx_start, verdict, receiving;

    skin_detector dut (
        .clk(clk), .rst_n(rst_n),
        .rx_data(rx_data), .rx_valid(rx_valid),
        .tx_data(tx_data), .tx_start(tx_start), .tx_busy(1'b0),
        .verdict(verdict), .receiving(receiving));

    always #18.518 clk = ~clk;

    // --- captura de la respuesta ---
    reg [7:0] resp [0:3];
    integer   nresp = 0;
    always @(posedge clk) if (tx_start) begin
        if (nresp < 4) resp[nresp] = tx_data;
        nresp = nresp + 1;
    end

    task send_byte(input [7:0] bt);
        begin
            @(negedge clk); rx_data = bt; rx_valid = 1;
            @(negedge clk); rx_valid = 0;
            repeat (GAP - 1) @(negedge clk);
        end
    endtask

    // --- las imagenes ---
    function pix_skin(input integer kind, input integer x, input integer y);
        begin
            case (kind)
                0: pix_skin = (x >= 96 && x < 304 && y >= 96 && y < 304);
                1: pix_skin = (x % 3 == 0) && (y % 3 == 0);
                2: pix_skin = (x < 48 && y < 48);
                3: pix_skin = (x < 80 && y < 80);
                4: pix_skin = (x % 2 == 0);
                5: pix_skin = (x % 2 == 0) && (y != 0);
                default: pix_skin = 0;
            endcase
        end
    endfunction

    task send_image(input integer kind);
        integer x, y;
        begin
            send_byte(8'hAA); send_byte(8'h55);              // cabecera
            for (y = 0; y < 400; y = y + 1)
                for (x = 0; x < 400; x = x + 1)
                    if (pix_skin(kind, x, y)) begin
                        send_byte(8'd224); send_byte(8'd172); send_byte(8'd105);   // piel
                    end else begin
                        send_byte(8'd30);  send_byte(8'd60);  send_byte(8'd160);   // azul
                    end
        end
    endtask

    integer errors = 0;

    task run_case(input integer kind, input integer exp_dense, input integer exp_pairs, input exp_verdict);
        integer wait_cycles;
        begin
            nresp = 0;
            send_image(kind);
            wait_cycles = 0;
            while (nresp < 4 && wait_cycles < 2000) begin
                @(negedge clk); wait_cycles = wait_cycles + 1;
            end
            repeat (10) @(negedge clk);
            if (nresp !== 4) begin
                errors = errors + 1;
                $display("FALLO caso %0d: llegaron %0d bytes de respuesta (se esperaban 4)", kind, nresp);
            end else begin
                if (resp[0] !== 8'hA5) begin errors = errors + 1; $display("FALLO caso %0d: cabecera de respuesta %h", kind, resp[0]); end
                if (resp[1] !== {7'd0, exp_verdict}) begin errors = errors + 1; $display("FALLO caso %0d: veredicto %h, esperaba %b", kind, resp[1], exp_verdict); end
                if ({resp[2][1:0], resp[3]} !== exp_dense) begin errors = errors + 1; $display("FALLO caso %0d: densos %0d, esperaba %0d", kind, {resp[2][1:0], resp[3]}, exp_dense); end
                if (dut.pairs !== exp_pairs) begin errors = errors + 1; $display("FALLO caso %0d: pares %0d, esperaba %0d", kind, dut.pairs, exp_pairs); end
            end
            $display("  caso %0d listo: densos=%0d pares=%0d veredicto=%b", kind, {resp[2][1:0], resp[3]}, dut.pairs, resp[1][0]);
        end
    endtask

    initial begin
        repeat (5) @(posedge clk); rst_n = 1;
        repeat (10) @(posedge clk);

        // basura antes de la cabecera: AA AA 00 12 (el detector debe seguir esperando)
        send_byte(8'h12); send_byte(8'hAA); send_byte(8'hAA); send_byte(8'h00); send_byte(8'h99);
        if (dut.state !== 4'd0) begin errors = errors + 1; $display("FALLO: la basura saco al detector de S_H1"); end

        run_case(0, 169,  312, 1);
        run_case(1,   0,    0, 0);
        run_case(2,   9,   12, 0);
        run_case(3,  25,   40, 1);
        run_case(4, 625, 1200, 1);
        run_case(5, 600, 1151, 1);

        if (errors == 0) $display("PASS tb_skin_detector (6 imagenes)");
        else             $display("FAIL tb_skin_detector (%0d errores)", errors);
        $finish;
    end
endmodule
