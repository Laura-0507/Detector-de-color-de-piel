odule uart_rx #(
    parameter CLK_FREQ = 27_000_000,
    parameter BAUD     = 460800
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,
    output reg  [7:0] data,
    output reg        valid
);
    localparam CPB  = (CLK_FREQ + BAUD / 2) / BAUD;  // ciclos de reloj por bit
    localparam HALF = CPB / 2;

    // Sincronizador: la senal del pin llega "sin avisar" al reloj
    reg rx_s1, rx_s2;
    always @(posedge clk) begin
        rx_s1 <= rx;
        rx_s2 <= rx_s1;
    end

    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;
    reg [1:0] st;
    reg [15:0] cnt;
    reg [2:0]  bit_i;
    reg [7:0]  sh;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st <= IDLE; cnt <= 0; bit_i <= 0; sh <= 0; data <= 0; valid <= 0;
        end else begin
            valid <= 1'b0;
            case (st)
                IDLE: if (!rx_s2) begin st <= START; cnt <= 0; end

                START: begin   // esperar la mitad del bit de inicio
                    if (cnt == HALF - 1) begin
                        cnt <= 0;
                        bit_i <= 0;
                        st <= rx_s2 ? IDLE : DATA;   // si ya subio, fue ruido
                    end else cnt <= cnt + 1;
                end

                DATA: begin    // muestrear cada bit a la mitad
                    if (cnt == CPB - 1) begin
                        cnt <= 0;
                        sh <= {rx_s2, sh[7:1]};      // el bit menos significativo llega primero
                        if (bit_i == 3'd7) st <= STOP;
                        else bit_i <= bit_i + 1;
                    end else cnt <= cnt + 1;
                end

                STOP: begin
                    if (cnt == CPB - 1) begin
                        cnt <= 0;
                        data <= sh;
                        valid <= 1'b1;
                        st <= IDLE;
                    end else cnt <= cnt + 1;
                end
            endcase
        end
    end
endmodule
