module OP_CTRL_FSM #(
    parameter DATA_WIDTH = 8
)(
    input  wire                     clk                 ,
    input  wire                     rst_n               ,
    // Ctrl
    input  wire                     src_cg_vld          ,// CG Frame is unfinished
    // LPE
    input  wire                     lpe_dataout_vld     ,
    input  wire [7:0]               lpe_bram_addr_max   ,// MAX = N1/4
    //PRE
    output wire                     lpe_2_rpe_vld       ,
    output reg                      dst_op_rdy          ,
    output reg [7:0]                rpe_bram_addr       ,
    output reg                      rpe_bram_en
);
    localparam [2:0]     IDLE = 3'd0;
    localparam [2:0]     S0   = 3'd1;
    localparam [2:0]     S1   = 3'd2;
    localparam [2:0]     S2   = 3'd3;

    wire        op_over;
    assign      op_over = (rpe_bram_addr == lpe_bram_addr_max);

    reg [2:0]   cur_state,nxt_state;
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
          cur_state <= IDLE;
        end else begin
          cur_state <= nxt_state;
        end
    end

    always @(*) begin
        if(~rst_n)begin
          nxt_state <= IDLE;
        end else begin
          case (cur_state)
            IDLE: begin
              nxt_state <= lpe_dataout_vld ? S0 : IDLE;
            end 
            S0: begin
              nxt_state <= op_over ? S1 : S0;
            end
            S1: begin
              nxt_state <= src_cg_vld ? S0 : IDLE;
            end
            default: nxt_state <= IDLE;
          endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
          rpe_bram_addr <= 'd0;
          rpe_bram_en  <= 'd0;
        end else begin
          case (cur_state)
            IDLE: begin
              rpe_bram_addr <= 'd0;
              rpe_bram_en  <= lpe_dataout_vld ? 'd1 : 'd0;
            end 
            S0: begin
              rpe_bram_addr <= op_over ? rpe_bram_addr : rpe_bram_addr + 'd1;
              rpe_bram_en   <= op_over ?'d0 : 'd1;
            end
            S1: begin
              rpe_bram_addr <= 'd0;
              rpe_bram_en  <= 'd0;
            end
            default: begin
              rpe_bram_addr <= 'd0;
              rpe_bram_en  <= 'd0;
            end
          endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
          dst_op_rdy <= 'd0;
        end else begin
          case (cur_state)
            IDLE: begin
              dst_op_rdy <= 'd0;
            end 
            S0: begin
              dst_op_rdy <= op_over ? 'd1 : 'd0;
            end
            S1: begin
              dst_op_rdy <= 'd0;
            end
            default: dst_op_rdy <= 'd0;
          endcase
        end
    end

    // -------------------------------
    // 数据有效信号打拍
    reg bram_vld_0, bram_vld_1, bram_vld_2, bram_vld_3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bram_vld_0 <= 1'b0;
            bram_vld_1 <= 1'b0;
        end else begin
            bram_vld_0 <= rpe_bram_en;
            bram_vld_1 <= bram_vld_0;//两拍取出OP数据
        end
    end
    assign lpe_2_rpe_vld = bram_vld_1;
    endmodule