//*********************************
//***IxIy corresponding with each frame must transfer continue****
//***src_cg_vld: represent whether the CG frame has CG-NZ�? �?1�? is unfinished*
//*********************************
module PE_Channel #(
    parameter DATA_WIDTH        = 8,
    parameter SIM               = 0  // 1: RTL, 0: DSP
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // 输入数据
    input  wire [2*DATA_WIDTH-1:0]  src_Ix_2B   ,
    input  wire [DATA_WIDTH-1:0]    src_Iy_1B   ,
    input  wire                     src_IxIy_vld,

    input  wire [2*DATA_WIDTH-1:0]  src_cg_2B   ,// 2B: {cg_data,cg_scaling}
    input  wire                     src_cg_vld  ,// handshake: src_cg_vld & dst_opcg_rdy -> update CG-NZ
    output wire                     src_cg_rdy,//for current CG-NZ, OP data is ready, please launch RPE

    // 输出数据
    output wire [2*DATA_WIDTH-1:0]  dst_opcg_data,
    output wire                     dst_opcg_data_vld
);

    wire [2*DATA_WIDTH-1:0]  lpe_2_bram_dataout_0;
    wire                     lpe_2_bram_dataout_1;
    wire                     lpe_2_bram_dataout_vld;
    wire                     lpe_2_bram_en;
    wire [7:0]               lpe_2_bram_addr;
    wire [7:0]               lpe_2_bram_addr_max;

    LPE #(
        .DATA_WIDTH                     (DATA_WIDTH),
        .SIM                            (SIM)
    )u_LPE(
        .clk                            (clk       ),
        .rst_n                          (rst_n     ),

        .src_Ix_2B                      (src_Ix_2B   ),
        .src_Iy_1B                      (src_Iy_1B   ),
        .src_IxIy_vld                   (src_IxIy_vld),

        .lpe_dataout_0                  (lpe_2_bram_dataout_0  ),
        .lpe_dataout_1                  (lpe_2_bram_dataout_1  ),
        .lpe_dataout_vld                (lpe_2_bram_dataout_vld),

        .lpe_bram_en                    (lpe_2_bram_en      ),
        .lpe_bram_addr                  (lpe_2_bram_addr    ),
        .lpe_bram_addr_max              (lpe_2_bram_addr_max)
    );

    wire [15:0]              bram_2_rpe_2B;
    wire                     bram_2_rpe_vld;
    wire                     dst_op_rdy;

    OP_CTRL #(
        .DATA_WIDTH(DATA_WIDTH)
    )u_OP_CTRL(
        .clk                            (clk       ),
        .rst_n                          (rst_n     ),

        .src_cg_vld                     (src_cg_vld  ),
        .dst_op_rdy                     (dst_op_rdy  ),

        .lpe_dataout_0                  (lpe_2_bram_dataout_0  ),
        .lpe_dataout_1                  (lpe_2_bram_dataout_1  ),
        .lpe_dataout_vld                (lpe_2_bram_dataout_vld),

        .lpe_bram_en                    (lpe_2_bram_en      ),
        .lpe_bram_addr                  (lpe_2_bram_addr    ),
        .lpe_bram_addr_max              (lpe_2_bram_addr_max),

        .lpe_2_rpe_2B                   (bram_2_rpe_2B),
        .lpe_2_rpe_vld                  (bram_2_rpe_vld)
    );


    RPE #(
        .DATA_WIDTH                     (DATA_WIDTH),
        .SIM                            (SIM)
    )u_RPE(
        .clk                            (clk       ),
        .rst_n                          (rst_n     ),

        .lpe_2_rpe_2B                   (bram_2_rpe_2B),
        .lpe_2_rpe_vld                  (bram_2_rpe_vld),

        .src_cg_2B                      (src_cg_2B ),
        .src_cg_vld                     (src_cg_vld),
        .src_opcg_rdy                   (dst_op_rdy),

        .dst_opcg_data                  (dst_opcg_data),
        .dst_opcg_data_vld              (dst_opcg_data_vld)
    ); 

    assign src_cg_rdy = dst_op_rdy;
endmodule