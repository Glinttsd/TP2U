`timescale 1ns / 1ps

module DSP_Top_SIM(
    input               CLK,
    input               SCLR,
    input       [26:0]  A,
    input       [17:0]  B,
    input       [47:0]  C,
    input       [26:0]  D,
    input               CEA3,
    input               CEA4,
    input               CEB3,
    input               CEB4,
    output reg  [47:0]  P
);

    always @(posedge CLK or posedge SCLR) begin
        if (SCLR) begin
            P <= 48'd0;
        end else if (CEA3 & CEA4 & CEB3 & CEB4) begin
            P <= ((A + D) * B) + C;
        end
    end

endmodule
