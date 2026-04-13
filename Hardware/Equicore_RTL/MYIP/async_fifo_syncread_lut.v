// ============================================================
// async_fifo_syncread_lut
// - Async FIFO, 1R/1W, equal width
// - Sync read data registered on rd_clk
// - Memory inferred as distributed RAM (no BRAM).
// ============================================================
module async_fifo_syncread_lut #(
    parameter integer WIDTH = 8,
    parameter integer DEPTH = 16   // must be power of 2
)(
    input  wire              wr_clk,
    input  wire              wr_rst_n,
    input  wire              wr_en,
    input  wire [WIDTH-1:0]  din,
    output wire              full,

    input  wire              rd_clk,
    input  wire              rd_rst_n,
    input  wire              rd_en,
    output reg  [WIDTH-1:0]  dout,
    output wire              empty
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

    (* ram_style = "distributed" *) reg [WIDTH-1:0] mem [0:DEPTH-1];

    function [PTR_BITS-1:0] bin2gray;
        input [PTR_BITS-1:0] b;
        begin
            bin2gray = (b >> 1) ^ b;
        end
    endfunction

    reg  [PTR_BITS-1:0] wr_ptr_bin, wr_ptr_gray;
    reg  [PTR_BITS-1:0] rd_ptr_bin, rd_ptr_gray;

    reg [PTR_BITS-1:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
    reg [PTR_BITS-1:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;

    wire [PTR_BITS-1:0] rd_ptr_gray_w = rd_ptr_gray_sync2;
    wire [PTR_BITS-1:0] wr_ptr_gray_r = wr_ptr_gray_sync2;

    // full
    wire [PTR_BITS-1:0] wr_ptr_bin_n  = wr_ptr_bin + (wr_en && !full);
    wire [PTR_BITS-1:0] wr_ptr_gray_n = bin2gray(wr_ptr_bin_n);

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

    // write
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

    // sync rd ptr into wr
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_ptr_gray_sync1 <= {PTR_BITS{1'b0}};
            rd_ptr_gray_sync2 <= {PTR_BITS{1'b0}};
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end

    // empty
    wire empty_n = (rd_ptr_gray == wr_ptr_gray_r);

    reg empty_r;
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n)
            empty_r <= 1'b1;
        else
            empty_r <= empty_n;
    end
    assign empty = empty_r;

    // read
    wire pop = rd_en && !empty;

    wire [PTR_BITS-1:0] rd_ptr_bin_n  = rd_ptr_bin + pop;
    wire [PTR_BITS-1:0] rd_ptr_gray_n = bin2gray(rd_ptr_bin_n);

    wire [ADDR_BITS-1:0] rd_addr = rd_ptr_bin[ADDR_BITS-1:0];

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin  <= {PTR_BITS{1'b0}};
            rd_ptr_gray <= {PTR_BITS{1'b0}};
            dout        <= {WIDTH{1'b0}};
        end else begin
            if (pop) begin
                dout        <= mem[rd_addr];
                rd_ptr_bin  <= rd_ptr_bin_n;
                rd_ptr_gray <= rd_ptr_gray_n;
            end
        end
    end

    // sync wr ptr into rd
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
