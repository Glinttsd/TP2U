module DCE_TOP #(
    parameter LDCE_BRAM_ADDR_WIDTH      = 10,
    parameter RDCE_BRAM_OPCG_ADDR_WIDTH = 7,
    parameter RDCE_BRAM_W_ADDR_WIDTH    = 11,
    parameter BRAM_DATA_WIDTH           = 128,
    parameter DATA_WIDTH                = 8,
    parameter SIM                       = 0
)(
    input  wire                         clk,
    input  wire                         rst_n,

    // ==========================
    // Ix / Iy inputs to LDCE
    // ==========================
    input  wire [2*DATA_WIDTH-1:0]      Ix,          // 单路 X：2B
    input  wire                         src_Ix_vld,
    input  wire [DATA_WIDTH-1:0]        Iy,
    input  wire                         src_Iy_vld,

    // ==========================
    // CG inputs to LDCE
    // ==========================
    input  wire [DATA_WIDTH-1:0]        src_cg_1B,
    input  wire [DATA_WIDTH-1:0]        src_cg_scaling,
    input  wire [DATA_WIDTH-1:0]        src_cg_dim,
    input  wire                         src_cg_vld,

    // ==========================
    // CTRL
    // ==========================
    input  wire                         switch_req,
    output wire                         switch_ack,
    input  wire [2:0]                   opcg_len,
    input  wire [7:0]                   w_rounds,
    input  wire [3:0]                   cg_l3_len,

    // ==========================
    // W BRAM write
    // ==========================
    input  wire [BRAM_DATA_WIDTH-1:0]   w_wr_data,
    input  wire                         w_wr_en,
    input  wire [RDCE_BRAM_W_ADDR_WIDTH-1:0] w_wr_addr,

    // ==========================
    // Output
    // ==========================
    output wire [31:0]                  result_out,
    output wire                         result_vld
);

    // --------------------------
    // LDCE -> RDCE interface
    // --------------------------
    wire ldce_rd_en;
    wire [LDCE_BRAM_ADDR_WIDTH-1:0] ldce_rd_addr;
    wire [BRAM_DATA_WIDTH-1:0]      rdce_ldce_data;

    // --------------------------
    // LDCE (single-Ix version)
    // --------------------------
    LDCE #(
        .BRAM_ADDR_WIDTH (LDCE_BRAM_ADDR_WIDTH),
        .BRAM_DATA_WIDTH (BRAM_DATA_WIDTH),
        .DATA_WIDTH      (DATA_WIDTH),
        .SIM             (SIM)
    ) u_ldce (
        .clk                        (clk),
        .rst_n                      (rst_n),

        // 单路 Ix / Iy
        .Ix                         (Ix),
        .src_Ix_vld                 (src_Ix_vld),
        .Iy                         (Iy),
        .src_Iy_vld                 (src_Iy_vld),

        // CG
        .src_cg_1B                  (src_cg_1B),
        .src_cg_scaling             (src_cg_scaling),
        .src_cg_dim                 (src_cg_dim),
        .src_cg_vld                 (src_cg_vld),

        // handshake to RDCE
        .src_cg_rdy                 (),               // 若后续需要，可拉出来用
        .dst_RDCE_2_RAM_rd_en       (ldce_rd_en),
        .dst_RDCE_2_RAM_addr        (ldce_rd_addr),
        .dst_RDCE_2_RAM_rd_data     (rdce_ldce_data),

        // BRAM switch control
        .bram_switch_req            (switch_req),
        .bram_switch_ack            (switch_ack)
    );

    // --------------------------
    // RDCE（保持不变）
    // --------------------------
    RDCE #(
        .BRAM_OPCG_ADDR_WIDTH (RDCE_BRAM_OPCG_ADDR_WIDTH),
        .BRAM_W_ADDR_WIDTH    (RDCE_BRAM_W_ADDR_WIDTH),
        .BRAM_DATA_WIDTH      (BRAM_DATA_WIDTH),
        .SIM                  (SIM)
    ) u_rdce (
        .clk                        (clk),
        .rst_n                      (rst_n),

        // OPCG BRAM (from LDCE)
        .ldce_rd_data               (rdce_ldce_data),
        .ldce_rdy                   (switch_ack),
        .ldce_rd_en                 (ldce_rd_en),
        .ldce_rd_addr               (ldce_rd_addr),

        // W BRAM
        .w_wr_data                  (w_wr_data),
        .w_wr_en                    (w_wr_en),
        .w_wr_addr                  (w_wr_addr),

        // CTRL
        .opcg_len                   (opcg_len),
        .w_rounds                   (w_rounds),
        .cg_l3_len                  (cg_l3_len),

        // Output
        .result_out                 (result_out),
        .result_vld                 (result_vld)
    );

endmodule
