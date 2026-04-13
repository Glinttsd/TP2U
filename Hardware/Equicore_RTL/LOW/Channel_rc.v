module channel_rc #(
    parameter DATA_WIDTH = 8
)(
    input  wire                     clk,
    input  wire                     rst_n,
    // CG
    input  wire [DATA_WIDTH-1:0]    cg_r_1B,
    input  wire [DATA_WIDTH-1:0]    cg_c_1B,
    input  wire                     cg_rc_vld,
    // channel_rc state
    output wire                     channel_rc_busy,
    input  wire                     n1_align_16,   //

    // Ix & Iy bram interface
    input  wire [4*DATA_WIDTH-1:0]  bram_Ix_4_data,   // X: 4B
    output reg                      bram_Ix_rd_en,
    output wire [15:0]              bram_Ix_addr_4,

    input  wire [DATA_WIDTH-1:0]    bram_Iy_data,      // Y: 1B
    output wire                     bram_Iy_rd_en,
    output wire [15:0]              bram_Iy_addr_1,

    // Ix ,Iy data
    output reg  [4*DATA_WIDTH-1:0]  Ix,                // 单路 X: 4B
    output reg                      dst_Ix_vld,

    output reg  [DATA_WIDTH-1:0]    Iy,
    output reg                      dst_Iy_vld
);

    // -------------------------------------------------------------------------
    // -------------------------------------------------------------------------
    wire [15:0] N1_ALIGN_16_DIV_4;
    assign N1_ALIGN_16_DIV_4 = n1_align_16 >> 2;

    // -------------------------------------------------------------------------
    reg [15:0] addr_cnt;
    reg        working;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            working <= 1'b0;
        end else if (cg_rc_vld) begin
            working <= 1'b1;
        end else if (addr_cnt == N1_ALIGN_16_DIV_4 - 1) begin
            working <= 1'b0;
        end else begin
            working <= working;
        end
    end

    // channel_rc_busy
    assign channel_rc_busy = working;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_cnt      <= 16'd0;
            bram_Ix_rd_en <= 1'b0;
        end else if (cg_rc_vld | working) begin
            addr_cnt      <= (addr_cnt == N1_ALIGN_16_DIV_4 - 1) ? 16'd0 : (addr_cnt + 16'd1);
            bram_Ix_rd_en <= (addr_cnt == N1_ALIGN_16_DIV_4 - 1) ? 1'b0  : 1'b1;
        end else begin
            addr_cnt      <= 16'd0;
            bram_Ix_rd_en <= 1'b0;
        end
    end

    // -------------------------------------------------------------------------
    // 地址生成
    // -------------------------------------------------------------------------
    assign bram_Ix_addr_4 = N1_ALIGN_16_DIV_4 * (cg_r_1B - 1'b1) + addr_cnt;
    assign bram_Iy_addr_1 = cg_c_1B - 1'b1;

    // -------------------------------------------------------------------------
    // Ix data: 4B
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Ix <= {4*DATA_WIDTH{1'b0}};
        end else begin
            Ix <= bram_Ix_4_data;
        end
    end

    // dst_Ix_vld
    reg dst_Ix_vld_d;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dst_Ix_vld_d <= 1'b0;
            dst_Ix_vld   <= 1'b0;
        end else begin
            dst_Ix_vld_d <= bram_Ix_rd_en;
            dst_Ix_vld   <= dst_Ix_vld_d;
        end
    end

    // -------------------------------------------------------------------------
    // Iy data
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Iy <= {DATA_WIDTH{1'b0}};
        end else begin
            Iy <= bram_Iy_data;
        end
    end

    // Iy vld 
    reg dst_Iy_vld_d;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dst_Iy_vld_d <= 1'b0;
            dst_Iy_vld   <= 1'b0;
        end else begin
            dst_Iy_vld_d <= bram_Iy_rd_en;
            dst_Iy_vld   <= dst_Iy_vld_d;
        end
    end

    assign bram_Iy_rd_en = cg_rc_vld;

endmodule
