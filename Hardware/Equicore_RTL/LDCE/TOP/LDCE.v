module LDCE#(
    parameter BRAM_ADDR_WIDTH = 10  ,   
    parameter BRAM_DATA_WIDTH = 128 ,  //RDCE:LDCE=2:16
    parameter DATA_WIDTH        = 8 ,
    parameter SIM               = 0  // 1: RTL, 0: IP
)(
    input  wire                         clk,
    input  wire                         rst_n,

    // Ix/Iy 
    input  wire [2*DATA_WIDTH-1:0]      Ix,
    // input  wire [2*DATA_WIDTH-1:0]      Ix_ch1,
    // input  wire [2*DATA_WIDTH-1:0]      Ix_ch2,
    // input  wire [2*DATA_WIDTH-1:0]      Ix_ch3,
    input  wire                         src_Ix_vld,

    input  wire [DATA_WIDTH-1:0]        Iy,
    input  wire                         src_Iy_vld,

    // CG
    input  wire [DATA_WIDTH-1:0]        src_cg_1B             ,
    input  wire [DATA_WIDTH-1:0]        src_cg_scaling        ,
    input  wire [DATA_WIDTH-1:0]        src_cg_dim            ,
    input  wire                         src_cg_vld            ,
    output wire                         src_cg_rdy            ,

    // dst: W
    //output wire                         dst_opcg_valid        ,// all (2*L3+1)*N1*N2 opcg is ready -> "opcg*w" can be launch if w is ready
    input  wire                         dst_RDCE_2_RAM_rd_en  ,
    input  wire [BRAM_ADDR_WIDTH-1:0]   dst_RDCE_2_RAM_addr   ,
    output wire [BRAM_DATA_WIDTH-1:0]   dst_RDCE_2_RAM_rd_data,

    // CTRL (switch)
    input  wire                         bram_switch_req,
    output wire                         bram_switch_ack
);

//-------------------------------------------------------------
wire [15:0]             LDCE_2_RAM_OPCG_DATA_2B;
wire [DATA_WIDTH-1:0]   LDCE_2_RAM_CG_DIM;
wire                    LDCE_2_RAM_OPCG_DATA_vld;
//DCE_PE
DCE_PE #(
    .DATA_WIDTH                         (DATA_WIDTH),
    .SIM                                (SIM)
)u_DCE_PE(
    .clk                                (clk  ),
    .rst_n                              (rst_n),

    .Ix_ch0                             (Ix     ),
    .Ix_ch1                             (     ),
    .Ix_ch2                             (     ),
    .Ix_ch3                             (     ),
    .src_Ix_vld                         (src_Ix_vld ),

    .Iy                                 (Iy         ),
    .src_Iy_vld                         (src_Iy_vld ),

    .src_cg_1B                          (src_cg_1B     ),
    .src_cg_scaling                     (src_cg_scaling),
    .src_cg_dim                         (src_cg_dim),
    .src_cg_vld                         (src_cg_vld    ),
    .src_cg_rdy                         (src_cg_rdy    ),
    
    .vec_b                              (LDCE_2_RAM_OPCG_DATA_2B   ),
    .vec_dim                            (LDCE_2_RAM_CG_DIM         ),
    .vec_b_valid                        (LDCE_2_RAM_OPCG_DATA_vld  )
);

//------------------------------------------------------------
//LDCE_CTRL
wire                                    LDCE_2_RAM_rd_en  ;
wire                                    LDCE_2_RAM_wr_en  ;
wire [BRAM_ADDR_WIDTH-1:0]              LDCE_2_RAM_rd_addr;
wire [BRAM_ADDR_WIDTH-1:0]              LDCE_2_RAM_wr_addr;
wire [BRAM_DATA_WIDTH-1:0]              LDCE_2_RAM_rd_data;
wire [BRAM_DATA_WIDTH-1:0]              LDCE_2_RAM_wr_data;

LDCE_CTRL#(
    .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
    .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH)
)u_LDCE_CTRL(
    .clk                                (clk        ),
    .rst_n                              (rst_n      ),

    .src_opcg_data                      (LDCE_2_RAM_OPCG_DATA_2B),
    .src_cg_dim                         (LDCE_2_RAM_CG_DIM),
    .src_opcg_data_vld                  (LDCE_2_RAM_OPCG_DATA_vld),

    .RAM_rd_en                          (LDCE_2_RAM_rd_en  ),
    .RAM_wr_en                          (LDCE_2_RAM_wr_en  ),
    .RAM_rd_addr                        (LDCE_2_RAM_rd_addr),
    .RAM_wr_addr                        (LDCE_2_RAM_wr_addr),
    .RAM_rd_data                        (LDCE_2_RAM_rd_data),
    .RAM_wr_data                        (LDCE_2_RAM_wr_data)
);



//-------------------------------------------------------------
//BRAM Tile
BRAM_TILE #(
    .BRAM_ADDR_WIDTH                    (BRAM_ADDR_WIDTH),
    .BRAM_DATA_WIDTH                    (BRAM_DATA_WIDTH),
    .SIM                                (SIM)
)u_bram_tile(
    .clk                                (clk       ),
    .rst_n                              (rst_n     ),

    .src_rd_en                          (LDCE_2_RAM_rd_en  ),
    .src_wr_en                          (LDCE_2_RAM_wr_en  ),
    .src_rd_addr                        (LDCE_2_RAM_rd_addr   ),
    .src_wr_addr                        (LDCE_2_RAM_wr_addr   ),
    .src_rd_data                        (LDCE_2_RAM_rd_data),
    .src_wr_data                        (LDCE_2_RAM_wr_data),

    .dst_rd_en                          (dst_RDCE_2_RAM_rd_en  ),
    .dst_addr                           (dst_RDCE_2_RAM_addr   ),
    .dst_rd_data                        (dst_RDCE_2_RAM_rd_data),

    .tile_switch_req                    (bram_switch_req   ),
    .tile_switch_ack                    (bram_switch_ack   )
);
endmodule