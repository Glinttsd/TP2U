`timescale 1ns / 1ps

module DSP_Top(
    input               CLK,
    input               SCLR,
    //data
    input       [26:0]  A,
    input       [17:0]  B,
    input       [47:0]  C,
    input       [26:0]  D,
    //ce
    input               CEA3,
    input               CEA4,
    input               CEB3,
    input               CEB4,
    //cascade
    output      [47:0]  P
    );


    DSP48_Macro u_DSP48_Macro(
        .CLK(CLK),
        .SCLR(SCLR),
        //data
        .A(A),
        .B(B),
        .C(C),
        .D(D),
        //ce
        .CEA3(CEA3),
        .CEA4(CEA4),
        .CEB3(CEB3),
        .CEB4(CEB4),

        .P(P)
    );

endmodule
