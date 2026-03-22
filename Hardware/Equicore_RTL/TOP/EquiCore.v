// ============================================================
// Top-level: cg_parse -> channel_rc -> (CDC async FIFOs) -> dce
// ============================================================
module EquiCore #(
    parameter integer DATA_WIDTH = 8
)(
    // CLK & RST
    input  wire                     clk_200m,
    input  wire                     clk_500m,
    input  wire                     rst_n,

    // CTRL
    input  wire                     cg_load_en,

    // "BRAM" write ports from host/RC
    input  wire                     wr_Ix_bram_en,
    input  wire [4*DATA_WIDTH-1:0]  wr_Ix_bram_data,   // X = LDCE通道数 * 4B(packing + cdc)
    input  wire [15:0]              wr_Ix_bram_addr,

    input  wire                     wr_Iy_bram_en,
    input  wire [1*DATA_WIDTH-1:0]  wr_Iy_bram_data,   // Y: 1B
    input  wire [15:0]              wr_Iy_bram_addr,

    input  wire                     wr_cg_bram_en,
    input  wire [3*DATA_WIDTH-1:0]  wr_cg_bram_data,   // CG: 3B
    input  wire [15:0]              wr_cg_bram_addr,

    input  wire                     wr_w_bram_en,
    input  wire [64*DATA_WIDTH-1:0] wr_w_bram_data,     // W 位宽 = 
    input  wire [15:0]              wr_w_bram_addr,

    // Output
    output wire [31:0]              result_out,
    output wire                     result_vld
);

    // ============================
    // cg_parse to channel_rc
    // ============================

    // cg_bram (24b)
    wire            cg_bram_rd;
    wire [15:0]     cg_bram_addr;
    wire [35:0]     cg_rd_data_36;
    wire [3*DATA_WIDTH-1:0] cg_data_3B;

    // NOTE:
    // - Original design used RAMB18E2 (36b SDP, DOA_REG=1).
    // - Here replaced by distributed RAM: BRAM=0.
    dist_mem_1r1w #(
        .WIDTH (36),
        .DEPTH (512),
        .ADDR_W(9)
    ) u_cg_mem (
        .clk     (clk_200m),
        .rst_n   (rst_n),
        .rd_en   (cg_bram_rd),
        .rd_addr (cg_bram_addr[8:0]),
        .rd_data (cg_rd_data_36),
        .wr_en   (wr_cg_bram_en),
        .wr_addr (wr_cg_bram_addr[8:0]),
        .wr_data ({4'b0, wr_cg_bram_data})
    );

    assign cg_data_3B = cg_rd_data_36[3*DATA_WIDTH-1:0];

    wire [DATA_WIDTH-1:0] cg_r_2_rc;
    wire [DATA_WIDTH-1:0] cg_c_2_rc;
    wire                  cg_rl_vld_2_rc;

    wire [DATA_WIDTH-1:0] cg_v_2_rc;
    wire [DATA_WIDTH-1:0] cg_s_2_rc;
    wire [DATA_WIDTH-1:0] cg_d_2_rc;
    wire                  cg_vsd_vld_2_rc;
    wire                  cg_h_vld_2_rc;

    wire                  channel_rc_busy;

    cg_parse #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_cg_parse (
        .clk          (clk_200m),
        .rst_n        (rst_n),

        .cg_load_en   (cg_load_en),
        .cg_bram_rd   (cg_bram_rd),
        .cg_bram_addr (cg_bram_addr),
        .cg_data_3B   (cg_data_3B),

        .dst_ready    (!channel_rc_busy),

        .cg_r_1B      (cg_r_2_rc),
        .cg_c_1B      (cg_c_2_rc),
        .cg_rc_vld    (cg_rl_vld_2_rc),

        .cg_v_1B      (cg_v_2_rc),
        .cg_s_1B      (cg_s_2_rc),
        .cg_d_1B      (cg_d_2_rc),
        .cg_vsd_vld   (cg_vsd_vld_2_rc),
        .cg_h_vld     (cg_h_vld_2_rc)
    );

    // ============================
    // channel_rc
    // ============================

    // Ix_bram (now 4B wide)
    wire [4*DATA_WIDTH-1:0] bram_Ix_4_data;
    wire                    bram_Ix_rd_en;
    wire [15:0]             bram_Ix_addr_4;

    // Iy_bram (1B wide)
    wire [DATA_WIDTH-1:0]   bram_Iy_data;
    wire                    bram_Iy_rd_en;
    wire [15:0]             bram_Iy_addr_1;

    // Ix scratchpad using distributed RAM (replaces RAMB18E2, BRAM=0)
    // Keep 36-bit internal width for minimal downstream changes.
    wire [35:0] ix_rd_data_36;
    dist_mem_1r1w #(
        .WIDTH (36),
        .DEPTH (512),
        .ADDR_W(9)
    ) u_ix_mem (
        .clk     (clk_200m),
        .rst_n   (rst_n),
        .rd_en   (bram_Ix_rd_en),
        .rd_addr (bram_Ix_addr_4[8:0]),
        .rd_data (ix_rd_data_36),
        .wr_en   (wr_Ix_bram_en),
        .wr_addr (wr_Ix_bram_addr[8:0]),
        .wr_data ({4'b0, wr_Ix_bram_data})
    );
    assign bram_Ix_4_data = ix_rd_data_36[31:0];

    // Iy scratchpad using distributed RAM (replaces RAMB18E2, BRAM=0)
    wire [7:0] iy_rd_data_8;
    dist_mem_1r1w #(
        .WIDTH (8),
        .DEPTH (512),
        .ADDR_W(9)
    ) u_iy_mem (
        .clk     (clk_200m),
        .rst_n   (rst_n),
        .rd_en   (bram_Iy_rd_en),
        .rd_addr (bram_Iy_addr_1[8:0]),
        .rd_data (iy_rd_data_8),
        .wr_en   (wr_Iy_bram_en),
        .wr_addr (wr_Iy_bram_addr[8:0]),
        .wr_data (wr_Iy_bram_data)
    );
    assign bram_Iy_data = iy_rd_data_8;

    // channel_rc outputs (updated: Ix single 4B)
    wire [4*DATA_WIDTH-1:0] Ix_rc_4B;
    wire                    dst_Ix_vld_rc;

    wire [DATA_WIDTH-1:0]   Iy_rc_1B;
    wire                    dst_Iy_vld_rc;

    // NOTE:
    // - This top-level assumes channel_rc has been updated accordingly:
    //   * bram_Ix_4_data / bram_Ix_addr_4
    //   * single Ix output (4B)
    channel_rc #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_channel_rc (
        .clk             (clk_200m),
        .rst_n           (rst_n),

        .cg_r_1B         (cg_r_2_rc),
        .cg_c_1B         (cg_c_2_rc),
        .cg_rc_vld       (cg_rl_vld_2_rc),

        .channel_rc_busy (channel_rc_busy),

        .bram_Ix_4_data  (bram_Ix_4_data),
        .bram_Ix_rd_en   (bram_Ix_rd_en),
        .bram_Ix_addr_4  (bram_Ix_addr_4),

        .bram_Iy_data    (bram_Iy_data),
        .bram_Iy_rd_en   (bram_Iy_rd_en),
        .bram_Iy_addr_1  (bram_Iy_addr_1),

        .Ix              (Ix_rc_4B),
        .dst_Ix_vld      (dst_Ix_vld_rc),

        .Iy              (Iy_rc_1B),
        .dst_Iy_vld      (dst_Iy_vld_rc)
    );

    // ============================
    // CDC Module (Async FIFO for RC -> DCE)
    // ============================

    // CG stream into CDC (24b)
    // If you already have a packed CG stream + valid in RC domain, hook it here.
    // For now, tie-off is provided as a safe default.
    wire [3*DATA_WIDTH-1:0] CG_rc_3B  = {3*DATA_WIDTH{1'b0}};
    wire                    CG_vld_rc = 1'b0;

    wire [2*DATA_WIDTH-1:0] Ix_dce_2B;
    wire [DATA_WIDTH-1:0]   Iy_dce_1B;
    wire [3*DATA_WIDTH-1:0] CG_dce_3B;
    wire                    rd_en_dce;

    DCE_CDC #(
        .DATA_WIDTH (DATA_WIDTH),
        .FIFO_DEPTH (16)
    ) u_dce_cdc (
        .clk_rc    (clk_200m),
        .clk_dce   (clk_500m),
        .rst_n     (rst_n),

        .Ix_rc     (Ix_rc_4B),
        .Ix_vld_rc (dst_Ix_vld_rc),

        .Iy_rc     (Iy_rc_1B),
        .Iy_vld_rc (dst_Iy_vld_rc),

        .CG_rc     (CG_rc_3B),
        .CG_vld_rc (CG_vld_rc),

        .Ix_dce    (Ix_dce_2B),
        .Iy_dce    (Iy_dce_1B),
        .CG_dce    (CG_dce_3B),
        .rd_en_dce (rd_en_dce)
    );

    // ============================
    // DCE
    // ============================
    wire src_Ix_vld_dce = rd_en_dce;
    wire src_Iy_vld_dce = rd_en_dce;

    wire [DATA_WIDTH-1:0] src_cg_1B_dce      = CG_dce_3B[8*3-1:8*2];
    wire [DATA_WIDTH-1:0] src_cg_scaling_dce = CG_dce_3B[8*2-1:8*1];
    wire [DATA_WIDTH-1:0] src_cg_dim         = CG_dce_3B[8*1-1:0];
    wire                  src_cg_vld_dce     = 1'b0;

    // NOTE:
    // - DCE_TOP interface kept unchanged; Ix_ch1..3 are tied off.
    DCE_TOP #(
        .LDCE_BRAM_ADDR_WIDTH     (10),
        .RDCE_BRAM_OPCG_ADDR_WIDTH(7),
        .RDCE_BRAM_W_ADDR_WIDTH   (11),
        .BRAM_DATA_WIDTH          (256),
        .DATA_WIDTH               (8),
        .SIM                      (0)
    ) u_dce_top (
        .clk        (clk_500m),
        .rst_n      (rst_n),

        .Ix     (Ix_dce_2B),
        .src_Ix_vld (src_Ix_vld_dce),

        .Iy         (Iy_dce_1B),
        .src_Iy_vld (src_Iy_vld_dce),

        .src_cg_1B      (src_cg_1B_dce),
        .src_cg_scaling (src_cg_scaling_dce),
        .src_cg_dim     (src_cg_dim),
        .src_cg_vld     (src_cg_vld_dce),

        // Control (left as-is; may be driven elsewhere)
        .switch_req (switch_req),
        .switch_ack (switch_ack),
        .opcg_len   (opcg_len),
        .w_rounds   (w_rounds),
        .cg_l3_len  (cg_l3_len),

        // W BRAM interface
        .w_wr_data  (wr_w_bram_data),
        .w_wr_en    (wr_w_bram_en),
        .w_wr_addr  (wr_w_bram_addr),

        .result_out (result_out),
        .result_vld (result_vld)
    );

endmodule
