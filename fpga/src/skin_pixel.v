module skin_pixel (
    input  wire [7:0] r,
    input  wire [7:0] g,
    input  wire [7:0] b,
    output wire       is_skin
);
    // Los 8 bits se extienden a 18 bits con signo (siempre positivos)
    wire signed [17:0] rs = {10'd0, r};
    wire signed [17:0] gs = {10'd0, g};
    wire signed [17:0] bs = {10'd0, b};

    wire signed [17:0] cb_acc = -18'sd43 * rs - 18'sd85 * gs + 18'sd128 * bs;
    wire signed [17:0] cr_acc =  18'sd128 * rs - 18'sd107 * gs - 18'sd21 * bs;

    wire signed [17:0] cb = (cb_acc >>> 8) + 18'sd128;
    wire signed [17:0] cr = (cr_acc >>> 8) + 18'sd128;

    assign is_skin = (cb >= 18'sd77)  && (cb <= 18'sd127) && (cr >= 18'sd133) && (cr <= 18'sd173);
endmodule
              
