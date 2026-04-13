module Packing #(
    parameter DATA_WIDTH = 8,
    parameter SIM        = 0  // 1: 仿真, 0: 综合DSP
)(
    input  wire                     clk,
    input  wire                     rst_n,

    input  wire [DATA_WIDTH-1:0]    data_in_L, // 低位
    input  wire [DATA_WIDTH-1:0]    data_in_H, // 高位
    input  wire [DATA_WIDTH-1:0]    data_in_W, // 公用数据
    input  wire                     data_in_vld,

    output reg  [2*DATA_WIDTH-1:0]  data_out_0,
    output wire [2*DATA_WIDTH-1:0]  data_out_1
);

    // ----------------------------------------
    wire signed [26:0] dsp_A = {{19{data_in_L[DATA_WIDTH-1]}}, data_in_L};
    wire signed [26:0] dsp_D = {{19{data_in_H[DATA_WIDTH-1]}}, data_in_H};
    wire signed [17:0] dsp_B = {{10{data_in_W[DATA_WIDTH-1]}}, data_in_W};
    wire signed [47:0] dsp_C = 48'd0;
    (*use_dsp48 = "yes"*) wire [47:0] dsp_P;

    // ----------------------------------------
    generate
        if (SIM) begin : gen_sim
            DSP_Top_SIM u_dsp_sim (
                .CLK(clk),
                .SCLR(~rst_n),
                .A(dsp_A),
                .B(dsp_B),
                .C(dsp_C),
                .D(dsp_D),
                .CEA3(data_in_vld),
                .CEA4(data_in_vld),
                .CEB3(data_in_vld),
                .CEB4(data_in_vld),
                .P(dsp_P)
            );
        end else begin : gen_real
 (*DONT_TOUCH= "yes"*) DSP48E2  dsp_inst(
	            .A(dsp_A),
	            .B(dsp_B),
                .C(dsp_C),
                .D(dsp_D),
	            .P(dsp_P),
	            // control DSP
	            .ALUMODE(),
	            .INMODE(),
	            .OPMODE(), 

	            // clocking reset and enables.. control signals
	            .CLK(clk),
	            .RSTA(~rst_n),
	            .RSTALLCARRYIN(~rst_n),
	            .RSTALUMODE(~rst_n),
	            .RSTB(~rst_n),
	            .RSTC(~rst_n),
	            .RSTCTRL(~rst_n),
	            .RSTD(~rst_n),
	            .RSTINMODE(~rst_n),
	            .RSTM(~rst_n),
	            .RSTP(~rst_n),
	            .CEA1(data_in_vld),
	            .CEA2(data_in_vld),
	            .CEAD(data_in_vld),
	            .CEALUMODE(data_in_vld),
	            .CEB1(data_in_vld),
	            .CEB2(data_in_vld),
	            .CEC(data_in_vld),
	            .CECARRYIN(data_in_vld),
	            .CECTRL(data_in_vld),
	            .CED(data_in_vld),
	            .CEINMODE(data_in_vld),
	            .CEM(data_in_vld),
	            .CEP(data_in_vld)
            );
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data_out_0 <= 0;
        end else if (data_in_vld) begin
            data_out_0 <= dsp_P[2*DATA_WIDTH-1:0];
        end
    end

    (*DONT_TOUCH= "yes"*) Correction u_Correction (
      .clk             (clk                                 ),
      .rst_n           (rst_n                               ),
      .data_in_vld     (data_in_vld                         ),
      .low_neg         (data_in_L[DATA_WIDTH-1]             ),
      .data_in_W       (data_in_W                           ),
      .dsp_P           (dsp_P[2*DATA_WIDTH*2-1:2*DATA_WIDTH]),
      .data_out_1      (data_out_1                          )
    );

endmodule
