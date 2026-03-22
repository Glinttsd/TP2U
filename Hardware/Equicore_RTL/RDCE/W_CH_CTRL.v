module W_CH_CTRL #(
    parameter DATA_WIDTH    = 8
)(
    input  wire                     clk         ,
    input  wire                     rst_n       ,
    // DATA
    input  wire                     data_vld    ,
    input  wire [47:0]              dsp_P_0     ,
    input  wire [47:0]              dsp_P_1     ,
    input  wire [47:0]              dsp_P_2     ,
    input  wire [47:0]              dsp_P_3     ,
    // CTRL
    input  wire                     data_done   ,
    // Output
    output reg [31:0]               result_out  ,
    output reg                      result_vld
);
    reg     ch_vld_0,ch_vld_1,ch_vld_2;
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
          ch_vld_0 <= 'd0;
          ch_vld_1 <= 'd0;
          ch_vld_2 <= 'd0;
        end else begin
          ch_vld_0 <= data_vld;
          ch_vld_1 <= ch_vld_0;
          ch_vld_2 <= ch_vld_1;
        end
    end
    
    reg     data_done_0,data_done_1,data_done_2;
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
          data_done_0 <= 'd0;
          data_done_1 <= 'd0;
          data_done_2 <= 'd0;
        end else begin
          data_done_0 <= data_done;
          data_done_1 <= data_done_0;
          data_done_2 <= data_done_1;
        end
    end

    // ---------------- DSP 输出寄存 ----------------
    reg [31:0] dsp_P_reg[0:3];
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            dsp_P_reg[0] <= 0;
            dsp_P_reg[1] <= 0;
            dsp_P_reg[2] <= 0;
            dsp_P_reg[3] <= 0;
        end else if (ch_vld_2) begin
            dsp_P_reg[0] <= dsp_P_0[31:0];
            dsp_P_reg[1] <= dsp_P_1[31:0];
            dsp_P_reg[2] <= dsp_P_2[31:0];
            dsp_P_reg[3] <= dsp_P_3[31:0];
        end
    end
    
    // ---------------- 第一级流水线：部分和 ----------------
    reg [31:0] sum01_r, sum23_r;
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            sum01_r <= 32'd0;
            sum23_r <= 32'd0;
        end else if (ch_vld_2) begin
            sum01_r <= dsp_P_reg[0] + dsp_P_reg[1];
            sum23_r <= dsp_P_reg[2] + dsp_P_reg[3];
        end
    end
    
    // ---------------- 第二级流水线：累加 ----------------
    reg [31:0] acc;
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            acc <= 32'd0;
            result_out <= 32'd0;
            result_vld <= 1'b0;
        end else begin
            if (ch_vld_2) begin
                acc <= acc + sum01_r + sum23_r;
            end
    
            if (data_done_2) begin
                result_out <= acc;
                result_vld <= 1'b1;
                acc <= 32'd0;  // Clear
            end else begin
                result_vld <= 1'b0;
            end
        end
    end


endmodule
