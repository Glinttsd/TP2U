module RPE #(
    parameter DATA_WIDTH        = 8,
    parameter SIM               = 0  // 1: RTL, 0: DSP
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // 输入数据
    input  wire [15:0]              lpe_2_rpe_2B,
    input  wire                     lpe_2_rpe_vld,

    input  wire [2*DATA_WIDTH-1:0]  src_cg_2B   ,// 2B: {cg_data,cg_scaling}
    input  wire                     src_cg_vld  ,
    input  wire                     src_opcg_rdy  ,

    // 输出数据
    output wire [2*DATA_WIDTH-1:0]  dst_opcg_data,
    output wire                     dst_opcg_data_vld
);

    // -------------------------------
    // CG data
    wire [DATA_WIDTH-1:0]    src_cg_data,src_cg_scaling;


    // -------------------------------
    // RPE 运算阶段
    wire [2*DATA_WIDTH-1:0] rpe_dataout_0,rpe_dataout_1;
    
    (*DONT_TOUCH= "yes"*) Packing u_rpe_packing (
        .data_in_L      (lpe_2_rpe_2B[2*DATA_WIDTH-1:DATA_WIDTH]),
        .data_in_H      (lpe_2_rpe_2B[DATA_WIDTH-1:0]),
        .data_in_W      (src_cg_data),
        .data_in_vld    (lpe_2_rpe_vld),
        .data_out_0     (rpe_dataout_0),
        .data_out_1     (rpe_dataout_1)
    );


    // -------------------------------
    (*DONT_TOUCH= "yes"*) RPE_CTRL RPE_CTRL_u(
      .clk                (clk),
      .rst_n              (rst_n),
      .lpe_2_rpe_2B       (lpe_2_rpe_2B),
      .lpe_2_rpe_vld      (lpe_2_rpe_vld),
      .src_cg_2B          (src_cg_2B),
      .src_cg_vld         (src_cg_vld),
      .src_cg_rdy         (src_cg_rdy),
      .rpe_dataout_0      (rpe_dataout_0),
      .rpe_dataout_1      (rpe_dataout_1),
      .dst_opcg_data      (dst_opcg_data),
      .dst_opcg_data_vld  (dst_opcg_data_vld),
      .src_cg_data        (src_cg_data),
      .src_cg_scaling     (src_cg_scaling)

    );
endmodule