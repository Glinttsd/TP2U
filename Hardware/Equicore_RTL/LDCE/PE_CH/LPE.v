module LPE #(
    parameter DATA_WIDTH        = 8,
    parameter SIM               = 0  // 1: RTL, 0: DSP
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // 输入数据
    input  wire [2*DATA_WIDTH-1:0]  src_Ix_2B   ,
    input  wire [DATA_WIDTH-1:0]    src_Iy_1B   ,
    input  wire                     src_IxIy_vld,

    // 输出数据
    output wire [2*DATA_WIDTH-1:0]  lpe_dataout_0,
    output wire                     lpe_dataout_1,
    output wire                     lpe_dataout_vld,

    output wire                     lpe_bram_en,
    output wire [7:0]               lpe_bram_addr,
    output wire [7:0]               lpe_bram_addr_max
);
    (*DONT_TOUCH= "yes"*)  Packing #(
        .DATA_WIDTH     (DATA_WIDTH),
        .SIM            (SIM)
    )u_lpe_packing (
        .data_in_L      (src_Ix_2B[2*DATA_WIDTH-1:DATA_WIDTH]),
        .data_in_H      (src_Ix_2B[DATA_WIDTH-1:0]),
        .data_in_W      (src_Iy_1B),
        .data_in_vld    (src_IxIy_vld),
        .data_out_0     (lpe_dataout_0),
        .data_out_1     (lpe_dataout_1)
    );

    (*DONT_TOUCH= "yes"*) LPE_CTRL LPE_CTRL_u(
        .clk                      (clk                ),
        .rst_n                    (rst_n              ),
        .src_IxIy_vld             (src_IxIy_vld       ),
        .lpe_dataout_vld          (lpe_dataout_vld    ),
        .lpe_bram_en              (lpe_bram_en        ),
        .lpe_bram_addr            (lpe_bram_addr      ),
        .lpe_bram_addr_max        (lpe_bram_addr_max  )
    );


    endmodule