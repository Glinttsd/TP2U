module cg_parse #(
    parameter DATA_WIDTH = 8
)(
    input  wire                     clk,
    input  wire                     rst_n,
    // cg bram interface
    input  wire                     cg_load_en,
    output reg                      cg_bram_rd,
    output reg  [15:0]              cg_bram_addr,
    input  wire [3*DATA_WIDTH-1:0]  cg_data_3B,
    input  wire                     dst_ready,
    //load Ix Iy
    output reg  [DATA_WIDTH-1:0]    cg_r_1B  ,//cg_row_1B
    output reg  [DATA_WIDTH-1:0]    cg_c_1B  ,//cg_col_1B,
    output reg                      cg_rc_vld,//cg_rc_vld_1b,
    // transfer CG
    output reg  [DATA_WIDTH-1:0]    cg_v_1B   ,//cg_value_1B
    output reg  [DATA_WIDTH-1:0]    cg_s_1B   ,//cg_scaling_1B
    output reg  [DATA_WIDTH-1:0]    cg_d_1B   ,//cg_dimension_1B
    output reg                      cg_vsd_vld,//cg_body_vld_1b
    output reg                      cg_h_vld   //cg_head_1b
);

parameter [2:0]         S0 = 3'd0 ;//IDLE
parameter [2:0]         S1 = 3'd1 ;//loading
parameter [2:0]         S2 = 3'd2 ;//Frame End

  wire      frame_over;
  reg [7:0] cg_body_cnt,cg_body_num;
  assign    frame_over = (cg_body_cnt == cg_body_num) && (!cg_body_cnt);

  reg [2:0]  cur_state,nxt_state;
  always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
      cur_state <= S0;
    end else begin
      cur_state <= nxt_state;
    end
  end
  
  always @(*) begin
    if(~rst_n)begin
      nxt_state <= S0;
    end else begin
      case (cur_state)
        S0:begin
          nxt_state <= cg_load_en ? S1 : S0;
        end 
        S1: begin
          nxt_state <= frame_over ? S2 : S1;
        end
        S2: begin
          nxt_state <= dst_ready ? S1 : S0;
        end
        default: nxt_state <= S0;
      endcase
    end
  end

  // -------------------------------------------------------------------------
  always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
      cg_bram_rd <= 1'b0;
      cg_body_cnt <= 'd0;
    end else begin
      case (cur_state)
      S0: begin
        cg_bram_rd <= 1'b0;
        cg_body_cnt <= 'd0;
      end
      S1: begin
        cg_bram_rd <= frame_over ? 0 : 1;
        cg_body_cnt <= cg_body_cnt  + 1;
      end
      S2: begin
        cg_bram_rd <= 0;
        cg_body_cnt <='d0;
      end
      default:begin
        cg_bram_rd <= 0;
        cg_body_cnt <='d0;
      end
      endcase
    end
  end

  // -------------------------------------------------------------------------
  reg cg_bram_rd_r1,cg_bram_rd_r2;
  always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
          cg_bram_rd_r1 <= 1'b0;
          cg_bram_rd_r2 <= 1'b0;
      end else begin
          cg_bram_rd_r1 <= cg_bram_rd;
          cg_bram_rd_r2 <= cg_bram_rd_r1;
      end
  end

  wire cg_bram_rd_r1_pos;
  assign cg_bram_rd_r1_pos = ~cg_bram_rd_r2 & cg_bram_rd_r1;

  always @(*) begin
    if(~rst_n)begin
      cg_body_num <= 'd0;
    end else begin
      case (cur_state)
      S0: begin
        cg_body_num <= 'd0;
      end
      S1: begin
        cg_body_num <= cg_bram_rd_r1_pos ? cg_data_3B[1*DATA_WIDTH-1 : 0*DATA_WIDTH] : cg_body_num;
      end
      S2:begin
        cg_body_num <= 'd0;
      end
      default: begin
        cg_body_num <= 'd0;
      end
      endcase
    end
  end

  // -------------------------------------------------------------------------
  always @(posedge clk or negedge rst_n) begin
  if(~rst_n)begin
    cg_bram_addr <= 'd0;
  end else begin
    case (cur_state)
    S0: begin
      cg_bram_addr <= 'd0;
    end
    S1: begin
      cg_bram_addr <= frame_over ? cg_bram_addr : cg_bram_addr  + 1;
    end
    S2: begin
      cg_bram_addr <='d0;
    end
    default:begin
      cg_bram_addr <='d0;
    end
    endcase
  end
  end


  wire cg_head_vld;
  assign cg_head_vld = cg_bram_rd_r1_pos;


  // -------------------------------------------------------------------------
  wire [DATA_WIDTH-1:0] cg_row_w, cg_col_w;
  wire [DATA_WIDTH-1:0] cg_v_w, cg_s_w, cg_d_w;

  assign cg_col_w = cg_data_3B[3*DATA_WIDTH-1 : 2*DATA_WIDTH];
  assign cg_row_w = cg_data_3B[2*DATA_WIDTH-1 : 1*DATA_WIDTH];

  assign cg_v_w   = cg_data_3B[3*DATA_WIDTH-1 : 2*DATA_WIDTH];
  assign cg_s_w   = cg_data_3B[2*DATA_WIDTH-1 : 1*DATA_WIDTH];
  assign cg_d_w   = cg_data_3B[1*DATA_WIDTH-1 : 0*DATA_WIDTH];

  // -------------------------------------------------------------------------
  always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
          cg_c_1B <= {DATA_WIDTH{1'b0}};
          cg_r_1B <= {DATA_WIDTH{1'b0}};
          cg_rc_vld  <= 1'b0;
      end
      else begin
          cg_r_1B <= cg_row_w;
          cg_c_1B <= cg_col_w;
          cg_rc_vld  <= cg_head_vld;
      end
  end

  // -------------------------------------------------------------------------
  always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
          cg_v_1B <= {DATA_WIDTH{1'b0}};
          cg_s_1B <= {DATA_WIDTH{1'b0}};
          cg_d_1B <= {DATA_WIDTH{1'b0}};
          cg_vsd_vld <= 1'b0;
          cg_h_vld <= 1'b0;
      end
      else begin
          cg_v_1B <= cg_v_w;
          cg_s_1B <= cg_s_w;
          cg_d_1B <= cg_d_w;
          cg_vsd_vld  <= cg_bram_rd_r1 ^ cg_head_vld;
          cg_h_vld <= cg_head_vld;
      end
  end

endmodule
