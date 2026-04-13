//------------------------------------------------------------------------------------------------------------
//CG Frame:
//  1) load IxIy (1th cycle) -> LPE(3th cycle) -> BRAM_OP(4th cycle)
//  2) OP -> RPE(6th cycle) -> output(8th)
//  CTRL: 
//      1. LOAD IxIy && src_cg_2B && src_cg_vld = '1' -> waiting for "src_cg_rdy"
//      2. update CG-NZ while src_cg_rdy is '1' until cur CG frame has no CG-NZ(set src_cg_vld = '0')
//          (if src_cg_rdy = 1 & src_cg_vld =0 -> cur CG frame is over please load new IxIy!)
//------------------------------------------------------------------------------------------------------------
module DCE_PE #(
    parameter DATA_WIDTH        = 8,
    parameter SIM               = 0  // 1: RTL, 0: DSP
)(
    input  wire                         clk,
    input  wire                         rst_n,

    // 来自 channel_rc 的 Ix/Iy 数据
    input  wire [2*DATA_WIDTH-1:0]      Ix_ch0,
    input  wire [2*DATA_WIDTH-1:0]      Ix_ch1,
    input  wire [2*DATA_WIDTH-1:0]      Ix_ch2,
    input  wire [2*DATA_WIDTH-1:0]      Ix_ch3,
    input  wire                         src_Ix_vld,

    input  wire [DATA_WIDTH-1:0]        Iy,
    input  wire                         src_Iy_vld,

    // CG 参数
    input  wire [DATA_WIDTH-1:0]        src_cg_1B,
    input  wire [DATA_WIDTH-1:0]        src_cg_scaling,
    input  wire [DATA_WIDTH-1:0]        src_cg_dim,
    input  wire                         src_cg_vld,
    output wire                         src_cg_rdy  ,

    // 合并输出向量
    output wire [15:0]                  vec_b,
    output wire [DATA_WIDTH-1:0]        vec_dim,
    output wire                         vec_b_valid
);
    wire src_cg_rdy_0, src_cg_rdy_1, src_cg_rdy_2, src_cg_rdy_3;
    // -------------------------------------------------------------------------
    // PE 通道实例
    PE_Channel #(
        .DATA_WIDTH        (DATA_WIDTH),
        .SIM               (SIM)
    ) u_PE_ch0 (
        .clk               (clk),
        .rst_n             (rst_n),
        .src_Ix_2B         (Ix_ch0),
        .src_Iy_1B         (Iy),
        .src_IxIy_vld      (src_Ix_vld&src_Iy_vld),
        .src_cg_2B         ({src_cg_1B,src_cg_scaling}),
        .src_cg_vld        (src_cg_vld),
        .src_cg_rdy        (src_cg_rdy_0),
        .dst_opcg_data     (dst_opcg_data_0),
        .dst_opcg_data_vld (dst_opcg_data_vld_0)
    );

    // PE_Channel #(
    //     .DATA_WIDTH        (DATA_WIDTH),
    //     .SIM               (SIM)
    // ) u_PE_ch1 (
    //     .clk               (clk),
    //     .rst_n             (rst_n),
    //     .src_Ix_2B         (Ix_ch1),
    //     .src_Iy_1B         (Iy),
    //     .src_IxIy_vld      (src_Ix_vld&src_Iy_vld),
    //     .src_cg_2B         ({src_cg_1B,src_cg_scaling}),
    //     .src_cg_vld        (src_cg_vld),
    //     .src_cg_rdy        (src_cg_rdy_1),
    //     .dst_opcg_data     (dst_opcg_data_1),
    //     .dst_opcg_data_vld (dst_opcg_data_vld_1)
    // );

    // PE_Channel #(
    //     .DATA_WIDTH        (DATA_WIDTH),
    //     .SIM               (SIM)
    // ) u_PE_ch2 (
    //     .clk               (clk),
    //     .rst_n             (rst_n),
    //     .src_Ix_2B         (Ix_ch2),
    //     .src_Iy_1B         (Iy),
    //     .src_IxIy_vld      (src_Ix_vld&src_Iy_vld),
    //     .src_cg_2B         ({src_cg_1B,src_cg_scaling}),
    //     .src_cg_vld        (src_cg_vld),
    //     .src_cg_rdy        (src_cg_rdy_2),
    //     .dst_opcg_data     (dst_opcg_data_2),
    //     .dst_opcg_data_vld (dst_opcg_data_vld_2)
    // );

    // PE_Channel #(
    //     .DATA_WIDTH        (DATA_WIDTH),
    //     .SIM               (SIM)
    // ) u_PE_ch3 (
    //     .clk               (clk),
    //     .rst_n             (rst_n),
    //     .src_Ix_2B         (Ix_ch3),
    //     .src_Iy_1B         (Iy),
    //     .src_IxIy_vld      (src_Ix_vld&src_Iy_vld),
    //     .src_cg_2B         ({src_cg_1B,src_cg_scaling}),
    //     .src_cg_vld        (src_cg_vld),
    //     .src_cg_rdy        (src_cg_rdy_3),
    //     .dst_opcg_data     (dst_opcg_data_3),
    //     .dst_opcg_data_vld (dst_opcg_data_vld_3)
    // );

    // // =================== 合并为64位数据 ===================
    // assign vec_b_valid = dst_opcg_data_vld_0 & dst_opcg_data_vld_1 &
    //                      dst_opcg_data_vld_2 & dst_opcg_data_vld_3;
 
    assign vec_b_valid = dst_opcg_data_vld_0;

    assign vec_b =  dst_opcg_data_0 ;// ch0

    assign src_cg_rdy = src_cg_rdy_0;
    assign vec_dim = src_cg_dim;
endmodule
