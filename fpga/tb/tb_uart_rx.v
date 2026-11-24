`timescale 1ns/1ps
// tb_uart_rx.v
// Le "habla" al receptor como lo haria el FT232R (8N1) y revisa que entregue
// cada byte. Incluye bytes pegados (sin pausa) y un pulso de ruido que NO debe
// contar como byte.
module tb_uart_rx;
    localparam CLK_FREQ = 27_000_000;
    localparam BAUD     = 460800;
    localparam CPB      = (CLK_FREQ + BAUD / 2) / BAUD;   // 59 ciclos por bit

    reg        clk = 0, rst_n = 0, rx = 1;
    wire [7:0] data;
    wire       valid;

    uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) dut (
        .clk(clk), .rst_n(rst_n), .rx(rx), .data(data), .valid(valid));

    always #18.518 clk = ~clk;   // 27 MHz

    reg [7:0] got [0:31];
    integer   n = 0, errors = 0, i;
    always @(posedge clk) if (valid) begin got[n] = data; n = n + 1; end

    task send_byte(input [7:0] bt);
        integer j;
        begin
            rx = 0; repeat (CPB) @(posedge clk);                // inicio
            for (j = 0; j < 8; j = j + 1) begin
                rx = bt[j]; repeat (CPB) @(posedge clk);        // datos (LSB primero)
            end
            rx = 1; repeat (CPB) @(posedge clk);                // parada
        end
    endtask

    reg [7:0] exp [0:6];

    initial begin
        exp[0] = 8'hA5; exp[1] = 8'h00; exp[2] = 8'hFF; exp[3] = 8'h55;
        exp[4] = 8'hAA; exp[5] = 8'h01; exp[6] = 8'h80;

        repeat (5) @(posedge clk);
        rst_n = 1;
        repeat (20) @(posedge clk);

        for (i = 0; i < 7; i = i + 1) send_byte(exp[i]);   // pegados
        repeat (200) @(posedge clk);

        if (n !== 7) begin
            errors = errors + 1;
            $display("FALLO: llegaron %0d bytes, se esperaban 7", n);
        end
        for (i = 0; i < 7; i = i + 1)
            if (got[i] !== exp[i]) begin
                errors = errors + 1;
                $display("FALLO: byte %0d = %h, esperaba %h", i, got[i], exp[i]);
            end

        // ruido: pulso bajo muy corto, no debe generar byte
        rx = 0; repeat (CPB / 4) @(posedge clk);
        rx = 1; repeat (CPB * 12) @(posedge clk);
        if (n !== 7) begin
            errors = errors + 1;
            $display("FALLO: el ruido se tomo como byte");
        end

        // y despues del ruido debe seguir funcionando
        send_byte(8'h3C);
        repeat (200) @(posedge clk);
        if (n !== 8 || got[7] !== 8'h3C) begin
            errors = errors + 1;
            $display("FALLO: despues del ruido no recibio 3C (n=%0d)", n);
        end

        if (errors == 0) $display("PASS tb_uart_rx (8 bytes + ruido)");
        else             $display("FAIL tb_uart_rx (%0d errores)", errors);
        $finish;
    end
endmodule
