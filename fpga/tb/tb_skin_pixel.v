`timescale 1ns/1ps
// tb_skin_pixel.v
// Prueba el circuito combinacional skin_pixel contra un modelo de referencia
// escrito de otra forma (enteros con division "piso" explicita).
//   1) 4 pixeles conocidos (piel, azul, verde, rojo)
//   2) barrido en rejilla de R,G,B (pasos de 5)
//   3) 20000 pixeles aleatorios
module tb_skin_pixel;
    reg  [7:0] r, g, b;
    wire       is_skin;
    skin_pixel dut (.r(r), .g(g), .b(b), .is_skin(is_skin));

    integer errors = 0, tests = 0;
    integer ri, gi, bi, k;

    // dividir entre 256 redondeando hacia abajo (igual que >>> 8)
    function integer floor_div256(input integer v);
        begin
            if (v >= 0) floor_div256 = v / 256;
            else        floor_div256 = -(((-v) + 255) / 256);
        end
    endfunction

    function ref_skin(input integer rr, input integer gg, input integer bb);
        integer cb, cr;
        begin
            cb = 128 + floor_div256(-43 * rr - 85 * gg + 128 * bb);
            cr = 128 + floor_div256(128 * rr - 107 * gg - 21 * bb);
            ref_skin = (cb >= 77) && (cb <= 127) && (cr >= 133) && (cr <= 173);
        end
    endfunction

    task check(input [7:0] rr, input [7:0] gg, input [7:0] bb);
        begin
            r = rr; g = gg; b = bb;
            #1;
            tests = tests + 1;
            if (is_skin !== ref_skin(rr, gg, bb)) begin
                errors = errors + 1;
                if (errors <= 10)
                    $display("FALLO: R=%0d G=%0d B=%0d  dut=%b ref=%b", rr, gg, bb, is_skin, ref_skin(rr, gg, bb));
            end
        end
    endtask

    task expect_val(input [7:0] rr, input [7:0] gg, input [7:0] bb, input exp);
        begin
            r = rr; g = gg; b = bb;
            #1;
            tests = tests + 1;
            if (is_skin !== exp) begin
                errors = errors + 1;
                $display("FALLO conocido: (%0d,%0d,%0d) esperaba %b y dio %b", rr, gg, bb, exp, is_skin);
            end
        end
    endtask

    initial begin
        // 1) pixeles conocidos
        expect_val(224, 172, 105, 1'b1);  // piel (Cb=85, Cr=159)
        expect_val(241, 194, 160, 1'b1);  // piel clara
        expect_val( 30,  60, 160, 1'b0);  // azul
        expect_val( 20, 140,  60, 1'b0);  // verde
        expect_val(200,  30,  30, 1'b0);  // rojo
        expect_val(  0,   0,   0, 1'b0);  // negro
        expect_val(255, 255, 255, 1'b0);  // blanco

        // 2) rejilla
        for (ri = 0; ri <= 255; ri = ri + 5)
            for (gi = 0; gi <= 255; gi = gi + 5)
                for (bi = 0; bi <= 255; bi = bi + 5)
                    check(ri[7:0], gi[7:0], bi[7:0]);

        // 3) aleatorios
        for (k = 0; k < 20000; k = k + 1)
            check($urandom, $urandom, $urandom);

        if (errors == 0) $display("PASS tb_skin_pixel (%0d pruebas)", tests);
        else             $display("FAIL tb_skin_pixel (%0d errores de %0d)", errors, tests);
        $finish;
    end
endmodule
