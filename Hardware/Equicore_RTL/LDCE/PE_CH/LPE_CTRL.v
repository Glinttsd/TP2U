module LPE_CTRL #(
    parameter DATA_WIDTH = 8
)(
    input  wire                     clk,
    input  wire                     rst_n,

    input  wire                     src_IxIy_vld,

    // 输出数据
    output wire                     lpe_dataout_vld,

    output wire                     lpe_bram_en,
    output reg [7:0]                lpe_bram_addr,
    output reg [7:0]                lpe_bram_addr_max
);

    reg dsp_vld_0, dsp_vld_1, dsp_vld_2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dsp_vld_0 <= 1'b0;
            dsp_vld_1 <= 1'b0;
            dsp_vld_2 <= 1'b0;
        end else begin
            dsp_vld_0 <= src_IxIy_vld;
            dsp_vld_1 <= dsp_vld_0;
            dsp_vld_2 <= dsp_vld_1;
        end
    end


    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
          lpe_bram_addr <= 'd0;
          lpe_bram_addr_max <= 'd0;
        end else begin
          lpe_bram_addr <= ~dsp_vld_1 ? 'd0 : lpe_bram_addr + 1;
          lpe_bram_addr_max <= ~dsp_vld_1 ? lpe_bram_addr : lpe_bram_addr_max;
        end
    end

    assign lpe_bram_en = dsp_vld_1;
    assign lpe_dataout_vld = dsp_vld_2;

endmodule