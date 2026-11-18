module skin_detector #(
    parameter IMG_W     = 400,
    parameter IMG_H     = 400,
    parameter DENSE_TH  = 128,   // = DENSE_TH en config.py
    parameter MIN_DENSE = 20,    // = MIN_DENSE en config.py
    parameter MIN_PAIRS = 10     // = MIN_PAIRS en config.py
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] rx_data,
    input  wire       rx_valid,
    output reg  [7:0] tx_data,
    output reg        tx_start,
    input  wire       tx_busy,
    output reg        verdict,
    output wire       receiving
);
    localparam S_H1 = 4'd0, S_H2 = 4'd1, S_R = 4'd2, S_G = 4'd3, S_B = 4'd4,
               S_ACC = 4'd5, S_SWEEP = 4'd6, S_VERD = 4'd7, S_TX = 4'd8;

    reg [3:0]   state;
    reg [7:0]   r_reg, g_reg, b_reg;
    reg [8:0]   x, y;                 // posicion del pixel actual
    reg [224:0] cnt_flat;             // 25 contadores de 9 bits (0..256)
    reg [24:0]  prev_dense;           // bloques densos de la fila de bloques anterior
    reg         left_dense;           // el bloque de la izquierda era denso?
    reg [4:0]   sweep_i;              // bloque que se esta revisando (0..24)
    reg [9:0]   dense_total;          // total de bloques densos (max 625)
    reg [10:0]  pairs;                // pares de bloques densos que se tocan
    reg [1:0]   tx_idx;               // cual byte de la respuesta toca

    assign receiving = (state >= S_R) && (state <= S_VERD);

    wire is_skin;
    skin_pixel u_px (.r(r_reg), .g(g_reg), .b(b_reg), .is_skin(is_skin));

    wire [8:0] bx        = x[8:4];                         // x / 16
    wire [8:0] cur_cnt   = cnt_flat[sweep_i * 9 +: 9];
    wire       cur_dense = (cur_cnt >= DENSE_TH);
    wire       horiz     = cur_dense & left_dense;
    wire       vert      = cur_dense & prev_dense[sweep_i];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_H1; tx_start <= 1'b0; tx_data <= 8'd0; verdict <= 1'b0;
            x <= 0; y <= 0; sweep_i <= 0; dense_total <= 0; pairs <= 0;
            tx_idx <= 0; prev_dense <= 0; left_dense <= 0; cnt_flat <= 0;
            r_reg <= 0; g_reg <= 0; b_reg <= 0;
        end else begin
            tx_start <= 1'b0;
            case (state)
                // ---- cabecera ----
                S_H1: if (rx_valid && rx_data == 8'hAA) state <= S_H2;

                S_H2: if (rx_valid) begin
                    if (rx_data == 8'h55) begin
                        x <= 0; y <= 0; dense_total <= 0; pairs <= 0;
                        prev_dense <= 0; left_dense <= 0; cnt_flat <= 0;
                        state <= S_R;
                    end else if (rx_data != 8'hAA) state <= S_H1;
                end

                // ---- recibir un pixel ----
                S_R: if (rx_valid) begin r_reg <= rx_data; state <= S_G; end
                S_G: if (rx_valid) begin g_reg <= rx_data; state <= S_B; end
                S_B: if (rx_valid) begin b_reg <= rx_data; state <= S_ACC; end

                // ---- clasificar y contar ----
                S_ACC: begin
                    if (is_skin)
                        cnt_flat[bx * 9 +: 9] <= cnt_flat[bx * 9 +: 9] + 9'd1;

                    if (x == IMG_W - 1) begin
                        x <= 0;
                        if (y[3:0] == 4'd15) begin   // termino una fila de bloques
                            sweep_i <= 0; left_dense <= 1'b0; state <= S_SWEEP;
                        end else begin
                            y <= y + 9'd1; state <= S_R;
                        end
                    end else begin
                        x <= x + 9'd1; state <= S_R;
                    end
                end

                // ---- barrido de los 25 bloques ----
                S_SWEEP: begin
                    if (cur_dense) dense_total <= dense_total + 10'd1;
                    pairs <= pairs + {10'd0, horiz} + {10'd0, vert};
                    left_dense <= cur_dense;
                    prev_dense[sweep_i] <= cur_dense;
                    cnt_flat[sweep_i * 9 +: 9] <= 9'd0;      // limpiar para la siguiente fila
                    if (sweep_i == 5'd24) begin
                        if (y == IMG_H - 1) state <= S_VERD;
                        else begin y <= y + 9'd1; state <= S_R; end
                    end else sweep_i <= sweep_i + 5'd1;
                end

                // ---- decidir ----
                S_VERD: begin
                    verdict <= (dense_total >= MIN_DENSE) && (pairs >= MIN_PAIRS);
                    tx_idx  <= 0;
                    state   <= S_TX;
                end

                // ---- responder 4 bytes ----
                S_TX: if (!tx_busy && !tx_start) begin
                    tx_start <= 1'b1;
                    case (tx_idx)
                        2'd0: tx_data <= 8'hA5;
                        2'd1: tx_data <= {7'd0, verdict};
                        2'd2: tx_data <= {6'd0, dense_total[9:8]};
                        2'd3: tx_data <= dense_total[7:0];
                    endcase
                    tx_idx <= tx_idx + 2'd1;
                    if (tx_idx == 2'd3) state <= S_H1;
                end

                default: state <= S_H1;
            endcase
        end
    end
endmodule
