
// ===========================================================
// Distributed RAM 1R1W (sync read, write-first via bypass)
// - Intended to replace RAMB18E2-based small scratchpads
// - BRAM: 0 (uses LUTRAM/SRL depending on synthesis)
// ===========================================================
module dist_mem_1r1w #(
    parameter integer WIDTH  = 36,
    parameter integer DEPTH  = 512,
    parameter integer ADDR_W = 9
) (
    input  wire                 clk,
    input  wire                 rst_n,

    input  wire                 rd_en,
    input  wire [ADDR_W-1:0]    rd_addr,
    output reg  [WIDTH-1:0]     rd_data,

    input  wire                 wr_en,
    input  wire [ADDR_W-1:0]    wr_addr,
    input  wire [WIDTH-1:0]     wr_data
);
    // Inferred distributed RAM
    (* ram_style = "distributed" *) reg [WIDTH-1:0] mem [0:DEPTH-1];

    reg [ADDR_W-1:0] rd_addr_q;

    integer i;
    initial begin
        rd_data   = {WIDTH{1'b0}};
        rd_addr_q = {ADDR_W{1'b0}};
        // Optional init for simulation determinism (synthesis ignores)
        for (i = 0; i < DEPTH; i = i + 1) begin
            mem[i] = {WIDTH{1'b0}};
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            rd_data   <= {WIDTH{1'b0}};
            rd_addr_q <= {ADDR_W{1'b0}};
        end else begin
            // Write
            if (wr_en) begin
                mem[wr_addr] <= wr_data;
            end

            // Register read address when enabled (1-cycle latency)
            if (rd_en) begin
                rd_addr_q <= rd_addr;
            end

            // Read data (registered)
            // WRITE_FIRST behavior when a write hits the address being read out.
            rd_data <= mem[rd_addr_q];
            if (wr_en && (wr_addr == rd_addr_q)) begin
                rd_data <= wr_data;
            end
        end
    end
endmodule

