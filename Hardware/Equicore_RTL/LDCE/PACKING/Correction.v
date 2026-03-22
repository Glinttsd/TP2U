module Correction #(
    parameter DATA_WIDTH = 8,
    parameter SIM        = 0  // 1: 仿真, 0: 综合DSP
)(
    input  wire  clk,
    input  wire  rst_n,

    input  wire                    data_in_vld    ,
    input  wire                    low_neg        ,
    input  wire [DATA_WIDTH-1:0]   data_in_W      ,
    input  wire [2*DATA_WIDTH-1:0] dsp_P          ,

    output reg  [2*DATA_WIDTH-1:0] data_out_1     
);

    wire [2*DATA_WIDTH-1:0] high_correction = low_neg ? {{DATA_WIDTH{1'b0}}, data_in_W} : 0;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data_out_1 <= 0;
        end else if (data_in_vld) begin
            // dsp_P 的低 16 位对应低位乘法，高 16 位对应高位乘法
            data_out_1 <= dsp_P + high_correction;
        end
    end



endmodule