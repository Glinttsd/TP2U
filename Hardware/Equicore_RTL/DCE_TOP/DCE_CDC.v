// ============================================================
// DCE_CDC (updated)
// - Ix: 1 channel, 4B->2B, async CDC 200->500, no BRAM
// - Iy: 1B->1B, async CDC, no BRAM
// - CG: 3B->3B (24b->24b), async CDC, no BRAM
// - rd_en_dce asserted when all FIFOs have data
// ============================================================
module DCE_CDC #(
    parameter integer DATA_WIDTH  = 8,
    parameter integer FIFO_DEPTH  = 16
)(
    input  wire                     clk_rc,
    input  wire                     clk_dce,
    input  wire                     rst_n,

    // Ix input from RC (1 channel, 4B)
    input  wire [4*DATA_WIDTH-1:0]  Ix_rc,
    input  wire                     Ix_vld_rc,

    // Iy input from RC (1B)
    input  wire [DATA_WIDTH-1:0]    Iy_rc,
    input  wire                     Iy_vld_rc,

    // CG input from RC (3B, width unchanged)
    input  wire [3*DATA_WIDTH-1:0]  CG_rc,
    input  wire                     CG_vld_rc,

    // Outputs to DCE
    output wire [2*DATA_WIDTH-1:0]  Ix_dce,   // 2B
    output wire [DATA_WIDTH-1:0]    Iy_dce,   // 1B
    output wire [3*DATA_WIDTH-1:0]  CG_dce,   // 3B
    output wire                     rd_en_dce
);

    // ----------------------
    // Ix FIFO (4B -> 2B): 32b->16b LUTRAM async FIFO
    // ----------------------
    wire fifo_ix_empty, fifo_ix_full;
    async_fifo_32to16_lut #(.DEPTH(FIFO_DEPTH)) fifo_ix (
        .wr_clk   (clk_rc),
        .wr_rst_n (rst_n),
        .wr_en    (Ix_vld_rc),
        .din      (Ix_rc),
        .full     (fifo_ix_full),

        .rd_clk   (clk_dce),
        .rd_rst_n (rst_n),
        .rd_en    (rd_en_dce),
        .dout     (Ix_dce),
        .empty    (fifo_ix_empty)
    );

    // ----------------------
    // Iy FIFO (1B -> 1B): 8b LUTRAM async FIFO
    // ----------------------
    wire fifo_iy_empty, fifo_iy_full;
    async_fifo_syncread_lut #(
        .WIDTH(DATA_WIDTH),
        .DEPTH(FIFO_DEPTH)
    ) fifo_iy (
        .wr_clk   (clk_rc),
        .wr_rst_n (rst_n),
        .wr_en    (Iy_vld_rc),
        .din      (Iy_rc),
        .full     (fifo_iy_full),

        .rd_clk   (clk_dce),
        .rd_rst_n (rst_n),
        .rd_en    (rd_en_dce),
        .dout     (Iy_dce),
        .empty    (fifo_iy_empty)
    );

    // ----------------------
    // CG FIFO (3B -> 3B): 24b LUTRAM async FIFO
    // ----------------------
    wire fifo_cg_empty, fifo_cg_full;
    async_fifo_syncread_lut #(
        .WIDTH(3*DATA_WIDTH),
        .DEPTH(FIFO_DEPTH)
    ) fifo_cg (
        .wr_clk   (clk_rc),
        .wr_rst_n (rst_n),
        .wr_en    (CG_vld_rc),
        .din      (CG_rc),
        .full     (fifo_cg_full),

        .rd_clk   (clk_dce),
        .rd_rst_n (rst_n),
        .rd_en    (rd_en_dce),
        .dout     (CG_dce),
        .empty    (fifo_cg_empty)
    );

    // ----------------------
    // rd_en generation (lockstep)
    // ----------------------
    wire all_fifo_has_data = ~fifo_ix_empty & ~fifo_iy_empty & ~fifo_cg_empty;

    reg rd_en_reg;
    always @(posedge clk_dce or negedge rst_n) begin
        if (!rst_n)
            rd_en_reg <= 1'b0;
        else
            rd_en_reg <= all_fifo_has_data;
    end

    assign rd_en_dce = rd_en_reg;

endmodule