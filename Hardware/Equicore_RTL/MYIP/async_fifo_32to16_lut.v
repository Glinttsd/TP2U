// ============================================================
// async_fifo_32to16_lut
// - Async FIFO with width conversion: WR=32b, RD=16b
// - Depth is in WR-words (32b words). DEPTH=16 words.
// - Read side outputs low16 then high16 for each stored 32b word.
// - Memory inferred as distributed RAM (no BRAM).
// ============================================================
module async_fifo_32to16_lut #(
    parameter integer DEPTH = 16  // number of 32b words, must be power of 2
)(
    input  wire         wr_clk,
    input  wire         wr_rst_n,
    input  wire         wr_en,
    input  wire [31:0]  din,
    output wire         full,

    input  wire         rd_clk,
    input  wire         rd_rst_n,
    input  wire         rd_en,
    output reg  [15:0]  dout,
    output wire         empty
);

    function integer clog2;
        input integer v;
        integer i;
        begin
            clog2 = 0;
            for (i = v-1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction

    localparam integer ADDR_BITS = clog2(DEPTH);
    localparam integer PTR_BITS  = ADDR_BITS + 1;

    (* ram_style = "distributed" *) reg [31:0] mem [0:DEPTH-1];

    // Pointer / Gray code
    reg  [PTR_BITS-1:0] wr_ptr_bin, wr_ptr_bin_n;
    reg  [PTR_BITS-1:0] wr_ptr_gray, wr_ptr_gray_n;

    reg  [PTR_BITS-1:0] rd_ptr_bin, rd_ptr_bin_n;
    reg  [PTR_BITS-1:0] rd_ptr_gray, rd_ptr_gray_n;

    function [PTR_BITS-1:0] bin2gray;
        input [PTR_BITS-1:0] b;
        begin
            bin2gray = (b >> 1) ^ b;
        end
    endfunction

    // Cross-domain pointer sync
    reg [PTR_BITS-1:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
    reg [PTR_BITS-1:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;

    // Read-side half-word state
    reg        rd_half;        // 0: output low16, 1: output high16
    reg [31:0] rd_word_hold;   // latch current 32b word for 2 reads

    // ------------------------
    // FULL detection (write domain)
    // ------------------------
    wire [PTR_BITS-1:0] rd_ptr_gray_w = rd_ptr_gray_sync2;

    always @(*) begin
        wr_ptr_bin_n  = wr_ptr_bin + (wr_en && !full);
        wr_ptr_gray_n = bin2gray(wr_ptr_bin_n);
    end

    wire full_n =
        (wr_ptr_gray_n == {~rd_ptr_gray_w[PTR_BITS-1:PTR_BITS-2],
                           rd_ptr_gray_w[PTR_BITS-3:0]});

    reg full_r;
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n)
            full_r <= 1'b0;
        else
            full_r <= full_n;
    end
    assign full = full_r;

    // Write memory + update ptr
    wire [ADDR_BITS-1:0] wr_addr = wr_ptr_bin[ADDR_BITS-1:0];

    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin  <= {PTR_BITS{1'b0}};
            wr_ptr_gray <= {PTR_BITS{1'b0}};
        end else begin
            if (wr_en && !full) begin
                mem[wr_addr] <= din;
                wr_ptr_bin   <= wr_ptr_bin_n;
                wr_ptr_gray  <= wr_ptr_gray_n;
            end
        end
    end

    // Sync RD ptr gray into WR clk
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_ptr_gray_sync1 <= {PTR_BITS{1'b0}};
            rd_ptr_gray_sync2 <= {PTR_BITS{1'b0}};
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end

    // ------------------------
    // EMPTY detection (read domain)
    // empty only when no 32b words AND no pending upper half
    // ------------------------
    wire [PTR_BITS-1:0] wr_ptr_gray_r = wr_ptr_gray_sync2;

    wire empty_raw = (rd_ptr_gray == wr_ptr_gray_r);
    wire empty_n   = empty_raw && (rd_half == 1'b0);

    reg empty_r;
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n)
            empty_r <= 1'b1;
        else
            empty_r <= empty_n;
    end
    assign empty = empty_r;

    // Update rd ptr only when consuming the HIGH half
    always @(*) begin
        rd_ptr_bin_n  = rd_ptr_bin;
        rd_ptr_gray_n = rd_ptr_gray;

        if (rd_en && !empty) begin
            if (rd_half == 1'b1) begin
                rd_ptr_bin_n  = rd_ptr_bin + 1'b1;
                rd_ptr_gray_n = bin2gray(rd_ptr_bin_n);
            end
        end
    end

    wire [ADDR_BITS-1:0] rd_addr = rd_ptr_bin[ADDR_BITS-1:0];

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin   <= {PTR_BITS{1'b0}};
            rd_ptr_gray  <= {PTR_BITS{1'b0}};
            rd_half      <= 1'b0;
            rd_word_hold <= 32'b0;
            dout         <= 16'b0;
        end else begin
            if (rd_en && !empty) begin
                if (rd_half == 1'b0) begin
                    // First half: fetch word and output low16
                    rd_word_hold <= mem[rd_addr];
                    dout         <= mem[rd_addr][15:0];
                    rd_half      <= 1'b1;
                end else begin
                    // Second half: output high16 and advance pointer
                    dout    <= rd_word_hold[31:16];
                    rd_half <= 1'b0;

                    rd_ptr_bin  <= rd_ptr_bin_n;
                    rd_ptr_gray <= rd_ptr_gray_n;
                end
            end
        end
    end

    // Sync WR ptr gray into RD clk
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_ptr_gray_sync1 <= {PTR_BITS{1'b0}};
            wr_ptr_gray_sync2 <= {PTR_BITS{1'b0}};
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end

endmodule