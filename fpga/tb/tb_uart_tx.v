`timescale 1ns/1ps
// tb_uart_tx.v
// Manda bytes con uart_tx y los "lee" desde el cable muestreando a la mitad de
// cada bit, como lo haria el FT232R. Revisa: bit de inicio, 8 datos (LSB
// primero), bit de parada, la bandera busy y que un start mientras esta
// ocupado se ignore.
module tb_uart_tx;
    localparam CLK_FREQ = 27_000_000;
    localparam BAUD     = 460800;
    localparam CPB      = (CLK_FREQ + BAUD / 2) / BAUD;

    reg        clk = 0, rst_n = 0, start = 0;
    reg  [7:0] data = 0;
    wire       tx, busy;

    uart_tx #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) dut (
        .clk(clk), .rst_n(rst_n), .start(start), .data(data), .tx(tx), .busy(busy));

    always #18.518 clk = ~clk;

    integer errors = 0, i;
    reg [7:0] captured;

    task pulse_start(input [7:0] bt);
        begin
            @(negedge clk); data = bt; start = 1;
            @(negedge clk); start = 0;
        end
    endtask

    task capture_and_check(input [7:0] expected, input integer check_busy_ignore);
        integer j;
        begin
            @(negedge tx);                       // llega el bit de inicio
            repeat (CPB / 2) @(posedge clk);     // centro del bit de inicio
            if (tx !== 1'b0) begin errors = errors + 1; $display("FALLO: bit de inicio != 0"); end
            if (busy !== 1'b1) begin errors = errors + 1; $display("FALLO: busy no subio"); end
            for (j = 0; j < 8; j = j + 1) begin
                repeat (CPB) @(posedge clk);
                captured[j] = tx;
                if (check_busy_ignore && j == 3) pulse_start(8'hEE);   // start estando ocupado: se ignora
            end
            repeat (CPB) @(posedge clk);         // centro del bit de parada
            if (tx !== 1'b1) begin errors = errors + 1; $display("FALLO: bit de parada != 1"); end
            if (captured !== expected) begin
                errors = errors + 1;
                $display("FALLO: se mando %h y se leyo %h", expected, captured);
            end
            repeat (CPB) @(posedge clk);
            if (busy !== 1'b0) begin errors = errors + 1; $display("FALLO: busy no bajo"); end
        end
    endtask

    reg [7:0] vec [0:5];
    initial begin
        vec[0] = 8'hA5; vec[1] = 8'h00; vec[2] = 8'hFF; vec[3] = 8'h01; vec[4] = 8'h80; vec[5] = 8'h5A;
        repeat (5) @(posedge clk);
        rst_n = 1;
        repeat (10) @(posedge clk);

        if (tx !== 1'b1) begin errors = errors + 1; $display("FALLO: el cable no esta en 1 en reposo"); end

        for (i = 0; i < 6; i = i + 1) begin
            fork
                pulse_start(vec[i]);
                capture_and_check(vec[i], (i == 2));   // en el 3er byte probamos start estando ocupado
            join
            repeat (20) @(posedge clk);
        end

        if (errors == 0) $display("PASS tb_uart_tx (6 bytes)");
        else             $display("FAIL tb_uart_tx (%0d errores)", errors);
        $finish;
    end
endmodule
