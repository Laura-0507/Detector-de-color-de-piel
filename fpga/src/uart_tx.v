module uart_tx #(
    parameter CLK_FREQ = 27_000_000,
    parameter BAUD     = 460800
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,
    input  wire [7:0] data,
    output reg        tx,
    output reg        busy
);
    localparam CPB = (CLK_FREQ + BAUD / 2) / BAUD;

    reg [15:0] cnt;
    reg [3:0]  bit_i;
    reg [9:0]  sh;      // {parada, 8 datos, inicio}

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx <= 1'b1; busy <= 1'b0; cnt <= 0; bit_i <= 0; sh <= 10'h3FF;
        end else begin
            if (!busy) begin
                if (start) begin
                    sh    <= {1'b1, data, 1'b0};
                    busy  <= 1'b1;
                    cnt   <= 0;
                    bit_i <= 0;
                    tx    <= 1'b0;                 // bit de inicio
                end
            end else begin
                if (cnt == CPB - 1) begin
                    cnt <= 0;
                    if (bit_i == 4'd9) begin
                        busy <= 1'b0;
                        tx   <= 1'b1;
                    end else begin
                        bit_i <= bit_i + 1;
                        tx    <= sh[bit_i + 1];
                    end
                end else cnt <= cnt + 1;
            end
        end
    end
endmodule
