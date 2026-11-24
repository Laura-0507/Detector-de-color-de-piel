`timescale 1ns/1ps
// tb_top.v
// Prueba de humo del sistema completo (pines -> uart_rx -> skin_detector ->
// uart_tx -> pines). Con BAUD alto para que dure poco.
//   - el reset automatico (POR) termina solo
//   - tras la cabecera AA 55 se prende "recibiendo" (led[1] = 0, es activo en bajo)
//   - se manda UNA imagen completa de 400x400 (cuadro de piel) y la respuesta que
//     sale por el pin uart_tx se decodifica con otro uart_rx: A5, 01, bloques
//     densos = 169.
// Tarda varios minutos de simulacion; correr con:  make top
module tb_top;
    localparam CLK_FREQ = 27_000_000;
    localparam BAUD     = 3_000_000;       // = CPB de 9 ciclos
    localparam CPB      = (CLK_FREQ + BAUD / 2) / BAUD;

    reg        clk = 0, rx_pin = 1, mon_rst_n = 0;
    wire       tx_pin;
    wire [5:0] led;

    top #(.BAUD(BAUD)) dut (.clk(clk), .uart_rx(rx_pin), .uart_tx(tx_pin), .led(led));

    always #18.518 clk = ~clk;

    // receptor "espia" para leer la respuesta de la FPGA
    wire [7:0] mon_data;
    wire       mon_valid;
    uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) mon (
        .clk(clk), .rst_n(mon_rst_n), .rx(tx_pin), .data(mon_data), .valid(mon_valid));

    reg [7:0] resp [0:3];
    integer   nresp = 0;
    always @(posedge clk) if (mon_valid) begin
        if (nresp < 4) resp[nresp] = mon_data;
        nresp = nresp + 1;
    end

    task send_byte(input [7:0] bt);
        integer j;
        begin
            rx_pin = 0; repeat (CPB) @(posedge clk);
            for (j = 0; j < 8; j = j + 1) begin rx_pin = bt[j]; repeat (CPB) @(posedge clk); end
            rx_pin = 1; repeat (CPB) @(posedge clk);
        end
    endtask

    integer x, y, errors = 0, cycles;
    initial begin
        repeat (5) @(posedge clk); mon_rst_n = 1;
        repeat (45) @(posedge clk);
        if (dut.rst_n !== 1'b1) begin errors = errors + 1; $display("FALLO: el reset automatico no termino"); end
        if (led[1] !== 1'b1) begin errors = errors + 1; $display("FALLO: led[1] deberia estar apagado en reposo"); end

        // cabecera + el primer byte del primer pixel: ya debe estar "recibiendo"
        send_byte(8'hAA); send_byte(8'h55);
        send_byte(8'd30);
        repeat (20) @(posedge clk);
        if (led[1] !== 1'b0) begin errors = errors + 1; $display("FALLO: led[1] no se prendio al recibir"); end

        // se termina la imagen (cuadro de piel de 13x13 bloques sobre fondo azul)
        $display("  humo OK, mandando imagen completa por UART (tarda)...");
        send_byte(8'd60); send_byte(8'd160);     // resto del pixel (0,0), azul
        for (y = 0; y < 400; y = y + 1)
            for (x = 0; x < 400; x = x + 1)
                if (x != 0 || y != 0) begin
                    if (x >= 96 && x < 304 && y >= 96 && y < 304) begin
                        send_byte(8'd224); send_byte(8'd172); send_byte(8'd105);
                    end else begin
                        send_byte(8'd30); send_byte(8'd60); send_byte(8'd160);
                    end
                end
        cycles = 0;
        while (nresp < 4 && cycles < 5000) begin @(posedge clk); cycles = cycles + 1; end
        if (nresp !== 4) begin errors = errors + 1; $display("FALLO: llegaron %0d bytes de respuesta", nresp); end
        else begin
            if (resp[0] !== 8'hA5) begin errors = errors + 1; $display("FALLO: cabecera %h", resp[0]); end
            if (resp[1] !== 8'h01) begin errors = errors + 1; $display("FALLO: veredicto %h (esperaba 01)", resp[1]); end
            if ({resp[2][1:0], resp[3]} !== 10'd169) begin errors = errors + 1; $display("FALLO: densos %0d (esperaba 169)", {resp[2][1:0], resp[3]}); end
        end
        if (errors == 0) $display("PASS tb_top (smoke + imagen completa)");
        else             $display("FAIL tb_top (%0d errores)", errors);
        $finish;
    end
endmodule
