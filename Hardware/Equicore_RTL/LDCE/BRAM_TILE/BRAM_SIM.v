module BRAM_SIM #(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 512
)(
    input  wire                     clk,
    input  wire                     wr_en,
    input  wire                     rd_en,
    input  wire [ADDR_WIDTH-1:0]    wr_addr,
    input  wire [ADDR_WIDTH-1:0]    rd_addr,
    input  wire [DATA_WIDTH-1:0]    wr_data,
    output reg  [DATA_WIDTH-1:0]    rd_data
);
    localparam DEPTH = 1 << ADDR_WIDTH;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge clk) begin
        if (wr_en)
            mem[wr_addr] <= wr_data;
        if (rd_en)
            rd_data <= mem[rd_addr];
    end
endmodule
