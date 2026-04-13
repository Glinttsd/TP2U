module BRAM_CTRL #(
    parameter BRAM_ADDR_WIDTH = 10,    // BRAM 深度 = 2^ADDR_WIDTH
    parameter BRAM_BRAM_ADDR_WIDTH      = 10, // BRAM DEPTH = 2^BRAM_ADDR_WIDTH
    parameter BRAM_DATA_WIDTH           = 512 // BRAM WIDTH = 64B = 512bit
)(
    input  wire                                 clk,
    input  wire                                 rst_n,

    // SRC (wr + rd, 8B)
    input  wire                                 src_rd_en,
    input  wire                                 src_wr_en,
    input  wire [BRAM_ADDR_WIDTH-1:0]           src_rd_addr,
    input  wire [BRAM_ADDR_WIDTH-1:0]           src_wr_addr,
    output reg  [BRAM_DATA_WIDTH-1:0]           src_rd_data,
    input  wire [BRAM_DATA_WIDTH-1:0]           src_wr_data,

    // DST (rd, 64B)
    input  wire                                 dst_rd_en,
    input  wire [BRAM_ADDR_WIDTH-1:0]           dst_addr,
    output reg [BRAM_DATA_WIDTH-1:0]            dst_rd_data,

    // BRAM1
    output reg                                  ram1_wr_en,
    output reg                                  ram1_rd_en,
    output reg  [BRAM_ADDR_WIDTH-1:0]           ram1_wr_addr,
    output reg  [BRAM_ADDR_WIDTH-1:0]           ram1_rd_addr,
    output wire [BRAM_DATA_WIDTH-1:0]           ram1_wr_data,
    input  wire [BRAM_DATA_WIDTH-1:0]           ram1_rd_data,

    // BRAM2
    output reg                                  ram2_wr_en,
    output reg                                  ram2_rd_en,
    output reg  [BRAM_ADDR_WIDTH-1:0]           ram2_wr_addr,
    output reg  [BRAM_ADDR_WIDTH-1:0]           ram2_rd_addr,
    (* ram_style = "block"*) output wire [BRAM_DATA_WIDTH-1:0]           ram2_wr_data,
    (* ram_style = "block"*) input  wire [BRAM_DATA_WIDTH-1:0]           ram2_rd_data,

    // CTRL (switch)
    input  wire                                 switch_req, // switch req
    output reg                                  switch_ack
);

    // ========== pingpang bank sel ==========
    reg bank_sel;  // 0: bram0 wr & bram1 rd; 1: bram1 wr bram 0 rd

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            bank_sel   <= 1'b0;
            switch_ack <= 1'b0;
        end else if(switch_req) begin
            bank_sel   <= ~bank_sel;
            switch_ack <= 1'b1;
        end else begin
            switch_ack <= 1'b0;
        end
    end

    // ========== src wr ==========
    assign ram1_wr_data = src_wr_data;
    assign ram2_wr_data = src_wr_data;

    always @(*) begin
        ram1_wr_en   = 1'b0;
        ram2_wr_en   = 1'b0;
        ram1_wr_addr = {BRAM_ADDR_WIDTH{1'b0}};
        ram2_wr_addr = {BRAM_ADDR_WIDTH{1'b0}};

        if (src_wr_en) begin
            if (bank_sel == 1'b0) begin
                ram1_wr_en   = 1'b1;
                ram1_wr_addr = src_wr_addr;
            end else begin
                ram2_wr_en   = 1'b1;
                ram2_wr_addr = src_wr_addr;
            end
        end
    end

    // ======== src & dst rd ========
    always @(*) begin
        //default
        ram1_rd_en   = 1'b0;
        ram2_rd_en   = 1'b0;
        ram1_rd_addr = {BRAM_ADDR_WIDTH{1'b0}};
        ram2_rd_addr = {BRAM_ADDR_WIDTH{1'b0}};
        src_rd_data  = {BRAM_DATA_WIDTH{1'b0}};
        dst_rd_data  = {BRAM_DATA_WIDTH{1'b0}};

        // src rd
        if (src_rd_en) begin
            if (bank_sel == 1'b0) begin
                ram1_rd_en   = 1'b1;
                ram1_rd_addr = src_rd_addr;
                src_rd_data  = ram1_rd_data;
            end else begin
                ram2_rd_en   = 1'b1;
                ram2_rd_addr = src_rd_addr;
                src_rd_data  = ram2_rd_data;
            end
        end

        // dst rd
        if (dst_rd_en) begin
            if (bank_sel == 1'b0) begin
                ram2_rd_en   = 1'b1;
                ram2_rd_addr = dst_addr; 
                dst_rd_data  = ram2_rd_data;
            end else begin
                ram1_rd_en   = 1'b1;
                ram1_rd_addr = dst_addr;
                dst_rd_data  = ram1_rd_data;
            end
        end
    end

endmodule
