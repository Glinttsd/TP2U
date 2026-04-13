module RPE_CTRL #(
    parameter DATA_WIDTH = 8
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // 输入数据
    input  wire [15:0]              lpe_2_rpe_2B,
    input  wire                     lpe_2_rpe_vld,

    input  wire [2*DATA_WIDTH-1:0]  src_cg_2B   ,// 2B: {cg_data,cg_scaling}
    input  wire                     src_cg_vld  ,
    input  wire                     src_cg_rdy  ,

    input  wire [2*DATA_WIDTH-1:0]  rpe_dataout_0,
    input  wire [2*DATA_WIDTH-1:0]  rpe_dataout_1,

    // 输出数据
    output reg  [2*DATA_WIDTH-1:0]  dst_opcg_data,
    output reg                      dst_opcg_data_vld,

    output reg  [DATA_WIDTH-1:0]    src_cg_data,
    output reg  [DATA_WIDTH-1:0]    src_cg_scaling
);

always @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
          src_cg_data <= 'd0;
          src_cg_scaling <='d0;
        end else if(src_cg_rdy & src_cg_vld)begin
          {src_cg_data,src_cg_scaling} <= src_cg_2B;
        end else begin
          {src_cg_data,src_cg_scaling} <= {src_cg_data,src_cg_scaling};
        end
    end

    reg rpe_vld_0, rpe_vld_1, rpe_vld_2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rpe_vld_0 <= 1'b0;
            rpe_vld_1 <= 1'b0;
            rpe_vld_2 <= 1'b0;
        end else begin
            rpe_vld_0 <= lpe_2_rpe_vld;
            rpe_vld_1 <= rpe_vld_0;//两拍得到OPCG结果
            rpe_vld_2 <= rpe_vld_1;//一拍拼接
        end
    end

reg [DATA_WIDTH-1:0] rpe_out_s0, rpe_out_s1;
    always @(posedge clk or negedge rst_n) begin
      if (~rst_n) begin
        rpe_out_s0  <= 'd0;
        rpe_out_s1  <= 'd0;
      end else begin
        rpe_out_s0  <= rpe_dataout_0 >> src_cg_scaling[2:0];
        rpe_out_s1  <= rpe_dataout_1 >> src_cg_scaling[2:0];
      end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dst_opcg_data     <= {2*DATA_WIDTH{1'b0}};
            dst_opcg_data_vld <= 1'b0;
        end else begin
            dst_opcg_data     <= {rpe_out_s0,rpe_out_s1};
            dst_opcg_data_vld <= rpe_vld_2;
        end
    end


endmodule