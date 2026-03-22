`timescale 1ns / 1ps

module DSP48_Macro(
    input               CLK,
    input               SCLR,
    // data
    input       [26:0]  A,
    input       [17:0]  B,
    input       [47:0]  C,
    input       [26:0]  D,
    // clock enable
    input               CEA3,
    input               CEA4,
    input               CEB3,
    input               CEB4,
    // result
    output      [47:0]  P
);

    // Zero-extend A and D to DSP48E2 width
    wire [29:0] A_ext = {3'b000, A};  // 30-bit
    wire [26:0] D_ext = D;            // already 27-bit

    DSP48E2 #(
        // Basic mode: Multiply + Add
        .AMULTSEL("A"),
        .A_INPUT("DIRECT"),
        .BMULTSEL("B"),
        .B_INPUT("DIRECT"),
        .USE_MULT("MULTIPLY"),
        .USE_SIMD("ONE48"),
        // pipeline
        .AREG(2),
        .BREG(2),
        .CREG(1),
        .MREG(1),
        .PREG(1)
    ) dsp48e2_inst (
        // Data
        .A(A_ext),
        .B(B),
        .C(C),
        .D(D_ext),
        .P(P),

        // Control
        .ALUMODE(4'b0000),           // normal add
        .OPMODE(9'b001110101),       // P = A*B + C
        .INMODE(5'b00000),
        .CARRYIN(1'b0),
        .CARRYINSEL(3'b000),

        // Clocking
        .CLK(CLK),
        .CEA1(CEA3),    // map your CEA3 -> DSP AREG1
        .CEA2(CEA4),    // map your CEA4 -> DSP AREG2
        .CEB1(CEB3),    // map your CEB3 -> DSP BREG1
        .CEB2(CEB4),    // map your CEB4 -> DSP BREG2
        .CEC(1'b1),
        .CEM(1'b1),
        .CEP(1'b1),
        .CEAD(1'b0),
        .CEALUMODE(1'b1),
        .CECARRYIN(1'b1),
        .CECTRL(1'b1),
        .CED(1'b1),
        .CEINMODE(1'b1),

        // Reset
        .RSTA(SCLR),
        .RSTB(SCLR),
        .RSTC(SCLR),
        .RSTD(SCLR),
        .RSTM(SCLR),
        .RSTP(SCLR),
        .RSTALLCARRYIN(SCLR),
        .RSTALUMODE(SCLR),
        .RSTCTRL(SCLR),
        .RSTINMODE(SCLR),

        // Unused cascade ports
        .ACIN(30'b0), .BCIN(18'b0),
        .CARRYCASCIN(1'b0), .MULTSIGNIN(1'b0), .PCIN(),
        .ACOUT(), .BCOUT(), .CARRYCASCOUT(), .MULTSIGNOUT(), .PCOUT(),
        .OVERFLOW(), .PATTERNBDETECT(), .PATTERNDETECT(), .UNDERFLOW(),
        .CARRYOUT(), .XOROUT()
    );

endmodule
