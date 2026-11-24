`timescale 1ns/1ps
// tb_uart_loopback.v
// Conecta uart_tx directo a uart_rx y manda los 256 valores posibles de un
// byte (00..FF). Si salen todos igual, transmisor y receptor hablan el mismo
// idioma.
module tb_uart_loopback;
    localparam CLK_FREQ = 27_000_000;
    localparam BAUD     = 460800;

    reg        clk = 0, rst_n = 0, start = 0;
    reg  [7:0] tx_byte = 0;
    wire       line, busy, valid;
    wire [7:0] rx_byte;

    uart_tx #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) u_tx (
        .clk(clk), .rst_n(rst_n), .start(start), .data(tx_byte), .tx(line), .busy(busy));
    uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) u_rx (
        .clk(clk), .rst_n(rst_n), .rx(line), .data(rx_byte), .valid(valid));

    always #18.518 clk = ~clk;

    integer i, errors = 0, received = 0;
    reg [7:0] last_rx;
    always @(posedge clk) if (valid) begin last_rx = rx_byte; received = received + 1; end

    initial begin
        repeat (5) @(posedge clk); rst_n = 1;
        repeat (10) @(posedge clk);
        for (i = 0; i < 256; i = i + 1) begin
            @(negedge clk);
            while (busy) @(negedge clk);
            tx_byte = i[7:0]; start = 1;
            @(negedge clk); start = 0;
            wait (received == i + 1);
            if (last_rx !== i[7:0]) begin
                errors = errors + 1;
                $display("FALLO: se mando %h y llego %h", i[7:0], last_rx);
            end
        end
        if (errors == 0) $display("PASS tb_uart_loopback (256 bytes)");
        else             $display("FAIL tb_uart_loopback (%0d errores)", errors);
        $finish;
    end

    // perro guardian: si algo se cuelga
    initial begin
        #200_000_000;
        $display("FAIL tb_uart_loopback (se colgo, solo llegaron %0d bytes)", received);
        $finish;
    end
endmodule
