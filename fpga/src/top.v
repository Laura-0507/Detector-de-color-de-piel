module top (
    input  wire       clk,       // reloj de 27 MHz
    input  wire       uart_rx,   // viene del TXD del FT232R
    output wire       uart_tx,   // va al RXD del FT232R
    output wire [5:0] led        // LEDs de la placa (se prenden con 0)
);
    parameter CLK_FREQ = 27_000_000;
    parameter BAUD     = 460800;   // = BAUDRATE en config.py

    // Reset automatico al encender (no usamos boton)
    reg [3:0] por_cnt = 4'd0;
    wire rst_n = &por_cnt;
    always @(posedge clk) if (!rst_n) por_cnt <= por_cnt + 4'd1;

    wire [7:0] rx_data;
    wire       rx_valid;
    wire [7:0] tx_data;
    wire       tx_start, tx_busy;
    wire       verdict, receiving;

    uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) u_rx (
        .clk(clk), .rst_n(rst_n), .rx(uart_rx),
        .data(rx_data), .valid(rx_valid));

    skin_detector u_det (
        .clk(clk), .rst_n(rst_n),
        .rx_data(rx_data), .rx_valid(rx_valid),
        .tx_data(tx_data), .tx_start(tx_start), .tx_busy(tx_busy),
        .verdict(verdict), .receiving(receiving));

    uart_tx #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) u_tx (
        .clk(clk), .rst_n(rst_n), .start(tx_start), .data(tx_data),
        .tx(uart_tx), .busy(tx_busy));

    // led[0] prendido = ultima imagen SI era piel | led[1] prendido = recibiendo
    assign led = {4'b1111, ~receiving, ~verdict};
endmodule
