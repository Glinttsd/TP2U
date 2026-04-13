module RDCE_CTRL #(
    parameter BRAM_OPCG_ADDR_WIDTH = 7,
    parameter BRAM_W_ADDR_WIDTH = 11,
    parameter BRAM_DATA_WIDTH = 512
)(
    input  wire                             clk             ,
    input  wire                             rst_n           ,

    // OPCG BRAM
    input  wire [BRAM_DATA_WIDTH-1:0]       ldce_rd_data    ,
    input  wire                             ldce_rdy        ,
    output reg                              ldce_rd_en      ,
    output wire[BRAM_OPCG_ADDR_WIDTH-1:0]   ldce_rd_addr    ,

    // W BRAM
    input  wire [BRAM_DATA_WIDTH-1:0]       w_rd_data       ,
    input  wire                             w_rdy           ,
    output reg                              w_rd_en         ,
    output wire [BRAM_W_ADDR_WIDTH-1:0]     w_rd_addr       ,

    // CTRL
    input  wire [2:0]                       opcg_len        ,//len(N1)/64B -> max: 8
    input  wire [7:0]                       w_rounds        ,//len(N3)     -> max: 256
    input  wire [3:0]                       cg_l3_len       ,//len(2*L3+1) -> max: 13

    // OUTPUT DATA
    output wire [BRAM_DATA_WIDTH-1:0]       opcg_data       ,
    output wire [BRAM_DATA_WIDTH-1:0]       w_data          ,
    output reg                              opcg_w_data_vld ,
    //OUTPUT CTRL
    output wire                             final_result_en
);

    assign opcg_data = ldce_rd_data;
    assign w_data    = w_rd_data;

    reg [2:0]   opcg_cnt;
    reg [7:0]   w_cnt;
    reg [3:0]   cg_l3_cnt;

    // -------------------------
    // State logic
    // -------------------------
    localparam [1:0] IDLE    = 2'b00;
    localparam [1:0] S0      = 2'b01;
    localparam [1:0] S1      = 2'b10;
    localparam [1:0] S2      = 2'b11;

    reg [1:0] cur_state, nxt_state;

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)
            cur_state <= IDLE;
        else
            cur_state <= nxt_state;
    end


    always @(*) begin
        nxt_state = IDLE;
        case(cur_state)
            IDLE: begin
                nxt_state = ldce_rdy ? S0 : IDLE;
            end
            S0: begin
                nxt_state = (opcg_cnt == opcg_len) ? S1 : S0;
            end
            S1: begin
                nxt_state = (w_cnt == w_rounds) ? S2 : S0;
            end
            S2: begin
                nxt_state = (cg_l3_cnt == cg_l3_len) ? IDLE : S0;
            end
            default: nxt_state = IDLE;
        endcase
    end

    // opcg_cnt & w_cnt & cg_l3_cnt
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
          opcg_cnt  <= 'd0;
          w_cnt     <= 'd0;
          cg_l3_cnt <= 'd0;
        end else begin
          case(cur_state)
          IDLE: begin
            opcg_cnt  <= 'd0;
            w_cnt     <= 'd0;
            cg_l3_cnt <= 'd0;
          end
          S0: begin
            opcg_cnt  <= opcg_cnt + 1;
            w_cnt     <= 'd0;
            cg_l3_cnt <= 'd0;
          end
          S1: begin
            opcg_cnt  <= 'd0;
            w_cnt     <= w_cnt + 1;
            cg_l3_cnt <= 'd0;
          end
          S2: begin
            opcg_cnt  <= 'd0;
            w_cnt     <= 'd0;
            cg_l3_cnt <= cg_l3_cnt + 1;
          end
          default:begin
            opcg_cnt  <= 'd0;
            w_cnt     <= 'd0;
            cg_l3_cnt <= 'd0;
          end
          endcase
        end
    end

    // ldce_rd_en
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
          ldce_rd_en  <= 0;
          w_rd_en     <= 0;
        end else begin
          case(cur_state)
          IDLE: begin
            ldce_rd_en  <= 0;
            w_rd_en     <= 0;
          end
          S0: begin
            ldce_rd_en  <= 1;
            w_rd_en     <= 1;
          end
          S1: begin
            ldce_rd_en  <= 0;
            w_rd_en     <= 0;
          end
          S2: begin
            ldce_rd_en  <= 0;
            w_rd_en     <= 0;
          end
          default:begin
            ldce_rd_en  <= 0;
            w_rd_en     <= 0;
          end
          endcase
        end
    end
reg     opcg_w_data_vld_d1, opcg_w_data_vld_d2;
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            opcg_w_data_vld_d2  <= 0;
            opcg_w_data_vld_d1  <= 0;
            opcg_w_data_vld     <= 0;
        end else begin
            opcg_w_data_vld_d2  <= ldce_rd_en;
            opcg_w_data_vld_d1  <= opcg_w_data_vld_d2;
            opcg_w_data_vld     <= opcg_w_data_vld_d1;
        end
    end

    assign ldce_rd_addr[6:0] = {cg_l3_cnt[3:0],opcg_cnt[2:0]}; //L3*N1
    assign w_rd_addr[10:0]   = {w_cnt[7:0], opcg_cnt[2:0]};    //N3*N1
    assign final_result_en   = (cur_state == S1);

endmodule
