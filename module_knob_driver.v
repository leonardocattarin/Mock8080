module module_knob_driver (qzt_clk,
                        rot_A,
                        rot_B,

                        pulse,
                        direction);

input qzt_clk;
input rot_A;
input rot_B;

output pulse;
output direction;

reg pulse;
reg direction;
reg rot_A_old;
reg rot_B_old;


always @(posedge qzt_clk) begin
    //rot A anticipates B => right rotation (anti-orario)
    if (rot_A && rot_B && !rot_B_old) begin
        pulse <= 1;
        direction <= 0;
    end else if (rot_B  && rot_A && !rot_A_old) begin
        pulse <= 1;
        direction <= 1;
    end else begin
        pulse <= 0;
        direction <= 0;
    end

rot_A_old <= rot_A;
rot_B_old <= rot_B;
end

endmodule