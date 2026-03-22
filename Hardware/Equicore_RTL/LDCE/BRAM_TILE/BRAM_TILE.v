module BRAM_TILE #(
    parameter BRAM_ADDR_WIDTH = 7,     // depth = 2^ADDR_WIDTH
    parameter BRAM_DATA_WIDTH = 128,   // 128-bit ping-pong buffer
    parameter SIM = 0                  // 1: RTL BRAM; 0: primitive BRAM
)(
    input  wire                         clk,
    input  wire                         rst_n,

    // SRC Interface
    input  wire                         src_rd_en,
    input  wire                         src_wr_en,
    input  wire [BRAM_ADDR_WIDTH-1:0]   src_rd_addr,
    input  wire [BRAM_ADDR_WIDTH-1:0]   src_wr_addr,
    output wire [BRAM_DATA_WIDTH-1:0]   src_rd_data,
    input  wire [BRAM_DATA_WIDTH-1:0]   src_wr_data,

    // DST Interface
    input  wire                         dst_rd_en,
    input  wire [BRAM_ADDR_WIDTH-1:0]   dst_addr,
    output wire [BRAM_DATA_WIDTH-1:0]   dst_rd_data,

    // CTRL (switch)
    input  wire                         tile_switch_req,
    output wire                         tile_switch_ack
);

    // ================= BRAM =================
    // RAM1
    wire  ram1_wr_en, ram1_rd_en;
    wire [BRAM_DATA_WIDTH-1:0] ram1_wr_data;
    (* ram_style = "block" *) wire [BRAM_DATA_WIDTH-1:0] ram1_rd_data;
    wire [BRAM_ADDR_WIDTH-1:0] ram1_wr_addr, ram1_rd_addr;

    // RAM2
    wire  ram2_wr_en, ram2_rd_en;
    wire [BRAM_DATA_WIDTH-1:0] ram2_wr_data;
    (* ram_style = "block" *) wire [BRAM_DATA_WIDTH-1:0] ram2_rd_data;
    wire [BRAM_ADDR_WIDTH-1:0] ram2_wr_addr, ram2_rd_addr;

    // ============= PingPang CTRL ==============
    BRAM_CTRL #(
        .BRAM_ADDR_WIDTH    (BRAM_ADDR_WIDTH),
        .BRAM_DATA_WIDTH    (BRAM_DATA_WIDTH)
    ) u_ctrl (
        .clk                (clk),
        .rst_n              (rst_n),

        .src_rd_en          (src_rd_en),
        .src_wr_en          (src_wr_en),
        .src_rd_addr        (src_rd_addr),
        .src_wr_addr        (src_wr_addr),
        .src_rd_data        (src_rd_data),
        .src_wr_data        (src_wr_data),

        .dst_rd_en          (dst_rd_en),
        .dst_addr           (dst_addr),
        .dst_rd_data        (dst_rd_data),

        .ram1_wr_en         (ram1_wr_en),
        .ram1_rd_en         (ram1_rd_en),
        .ram1_wr_addr       (ram1_wr_addr),
        .ram1_rd_addr       (ram1_rd_addr),
        .ram1_wr_data       (ram1_wr_data),
        .ram1_rd_data       (ram1_rd_data),

        .ram2_wr_en         (ram2_wr_en),
        .ram2_rd_en         (ram2_rd_en),
        .ram2_wr_addr       (ram2_wr_addr),
        .ram2_rd_addr       (ram2_rd_addr),
        .ram2_wr_data       (ram2_wr_data),
        .ram2_rd_data       (ram2_rd_data),

        .switch_req         (tile_switch_req),
        .switch_ack         (tile_switch_ack)
    );

    // ================= RAM implementation =================
    generate
        if (SIM) begin : gen_sim_bram
            // RTL BRAM1
            BRAM_SIM #(
                .ADDR_WIDTH (BRAM_ADDR_WIDTH),
                .DATA_WIDTH (BRAM_DATA_WIDTH)
            ) u_ram1_sim (
                .clk        (clk),
                .wr_en      (ram1_wr_en),
                .rd_en      (ram1_rd_en),
                .wr_addr    (ram1_wr_addr),
                .rd_addr    (ram1_rd_addr),
                .wr_data    (ram1_wr_data),
                .rd_data    (ram1_rd_data)
            );

            // RTL BRAM2
            BRAM_SIM #(
                .ADDR_WIDTH (BRAM_ADDR_WIDTH),
                .DATA_WIDTH (BRAM_DATA_WIDTH)
            ) u_ram2_sim (
                .clk        (clk),
                .wr_en      (ram2_wr_en),
                .rd_en      (ram2_rd_en),
                .wr_addr    (ram2_wr_addr),
                .rd_addr    (ram2_rd_addr),
                .wr_data    (ram2_wr_data),
                .rd_data    (ram2_rd_data)
            );

        end else begin : gen_prim_bram
            // ------------------------------------------------------------
            // Primitive BRAM (RAMB18E2) -> 128b
            // 每个 bank: 4 x RAMB18E2,  32b
            // Port A: Read (registered), Port B: Write
            // ------------------------------------------------------------
            genvar k;

            // lane outputs
            wire [31:0] ram1_lane_q [0:3];
            wire [31:0] ram2_lane_q [0:3];

            // stitch 128b read bus
            assign ram1_rd_data = {ram1_lane_q[3], ram1_lane_q[2], ram1_lane_q[1], ram1_lane_q[0]};
            assign ram2_rd_data = {ram2_lane_q[3], ram2_lane_q[2], ram2_lane_q[1], ram2_lane_q[0]};

            // Address mapping: RAMB18E2 expects 18-bit ADDR* buses.
            // For 36-bit width, LSBs are typically 2'b0 (word aligned).
            localparam integer PADW = 18 - BRAM_ADDR_WIDTH - 2;
            wire [17:0] ram1_rd_addr18 = {{PADW{1'b0}}, ram1_rd_addr, 2'b0};
            wire [17:0] ram1_wr_addr18 = {{PADW{1'b0}}, ram1_wr_addr, 2'b0};
            wire [17:0] ram2_rd_addr18 = {{PADW{1'b0}}, ram2_rd_addr, 2'b0};
            wire [17:0] ram2_wr_addr18 = {{PADW{1'b0}}, ram2_wr_addr, 2'b0};

            // ---------- RAM1 lanes ----------
            for (k = 0; k < 4; k = k + 1) begin : gen_ram1_lane
                wire [31:0] din32 = ram1_wr_data[32*k +: 32];
                wire [31:0] dout32;

                (* DONT_TOUCH = "yes" *)
                RAMB18E2 #(
                    .DOA_REG(1),
                    .DOB_REG(0),
                    .WRITE_MODE_A("WRITE_FIRST"),
                    .WRITE_MODE_B("WRITE_FIRST"),
                    .READ_WIDTH_A(36),
                    .WRITE_WIDTH_B(36),
                    .READ_WIDTH_B(0),
                    .WRITE_WIDTH_A(0)
                ) u_ram1_prim (
                    // Port A (RD)
                    .CLKARDCLK      (clk),
                    .ENARDEN        (ram1_rd_en),
                    .ADDRARDADDR    (ram1_rd_addr18),
                    .WEA            (4'b0),
                    .DINADIN        (32'b0),
                    .DINPADINP      (4'b0),
                    .DOUTADOUT      (dout32),
                    .DOUTPADOUTP    (),
                    .REGCEAREGCE    (1'b1),
                    .RSTRAMARSTRAM  (~rst_n),
                    .RSTREGARSTREG  (~rst_n),

                    // Port B (WR)
                    .CLKBWRCLK      (clk),
                    .ENBWREN        (ram1_wr_en),
                    .ADDRBWRADDR    (ram1_wr_addr18),
                    .WEBWE          (4'b1111),    // 36b: 4 byte lanes in 32b portion
                    .DINBDIN        (din32),
                    .DINPBDINP      (4'b0),
                    .DOUTBDOUT      (),
                    .DOUTPBDOUTP    (),
                    .REGCEB         (1'b0),
                    .RSTRAMB        (~rst_n),
                    .RSTREGB        (1'b0)
                );

                assign ram1_lane_q[k] = dout32;
            end

            // ---------- RAM2 lanes ----------
            for (k = 0; k < 4; k = k + 1) begin : gen_ram2_lane
                wire [31:0] din32 = ram2_wr_data[32*k +: 32];
                wire [31:0] dout32;

                (* DONT_TOUCH = "yes" *)
                RAMB18E2 #(
                    .DOA_REG(1),
                    .DOB_REG(0),
                    .WRITE_MODE_A("WRITE_FIRST"),
                    .WRITE_MODE_B("WRITE_FIRST"),
                    .READ_WIDTH_A(36),
                    .WRITE_WIDTH_B(36),
                    .READ_WIDTH_B(0),
                    .WRITE_WIDTH_A(0)
                ) u_ram2_prim (
                    // Port A (RD)
                    .CLKARDCLK      (clk),
                    .ENARDEN        (ram2_rd_en),
                    .ADDRARDADDR    (ram2_rd_addr18),
                    .WEA            (4'b0),
                    .DINADIN        (32'b0),
                    .DINPADINP      (4'b0),
                    .DOUTADOUT      (dout32),
                    .DOUTPADOUTP    (),
                    .REGCEAREGCE    (1'b1),
                    .RSTRAMARSTRAM  (~rst_n),
                    .RSTREGARSTREG  (~rst_n),

                    // Port B (WR)
                    .CLKBWRCLK      (clk),
                    .ENBWREN        (ram2_wr_en),
                    .ADDRBWRADDR    (ram2_wr_addr18),
                    .WEBWE          (4'b1111),
                    .DINBDIN        (din32),
                    .DINPBDINP      (4'b0),
                    .DOUTBDOUT      (),
                    .DOUTPBDOUTP    (),
                    .REGCEB         (1'b0),
                    .RSTRAMB        (~rst_n),
                    .RSTREGB        (1'b0)
                );

                assign ram2_lane_q[k] = dout32;
            end

        end
    endgenerate

endmodule
