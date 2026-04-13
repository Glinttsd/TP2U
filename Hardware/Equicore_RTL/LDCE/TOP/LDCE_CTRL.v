//src_opcg_data_vld timing:
//     -----------------------  -----------------------  -----------------------
//------                     --                        --
module LDCE_CTRL#(
    parameter BRAM_ADDR_WIDTH = 8,   
    parameter BRAM_DATA_WIDTH = 128 //RDCE:LDCE=2:16
)(
    input  wire                         clk                 ,
    input  wire                         rst_n               ,
    //DCE_PE
    input wire [15:0]                   src_opcg_data       ,
    input wire [7:0]                    src_cg_dim          ,
    input wire                          src_opcg_data_vld   ,
    //CTRL
    //BRAM
    output reg                          RAM_rd_en           ,
    output reg                          RAM_wr_en           ,
    output wire [BRAM_ADDR_WIDTH-1:0]   RAM_rd_addr         ,
    output wire [BRAM_ADDR_WIDTH-1:0]   RAM_wr_addr         ,
    input  wire [BRAM_DATA_WIDTH-1:0]   RAM_rd_data         ,
    output reg  [BRAM_DATA_WIDTH-1:0]   RAM_wr_data         
);
    reg [6:0]   opcg_cnt;//maxnum = 2^6(64) , because 8B*64 = 512B corresponding to MAX(N1*N2)
    reg         src_opcg_data_vld_r1,src_opcg_data_vld_r2;
    wire        src_opcg_data_vld_pos;
    wire [3:0]  addr_low;
    // 8 x 64-bit accumulators
    reg [15:0] acc;
    integer i;
    // ----------------------
    // Address
    // ----------------------
    assign RAM_rd_addr = {src_cg_dim[3:0], opcg_cnt[6:3]};
    assign RAM_wr_addr = {src_cg_dim[3:0], (opcg_cnt[6:3]==0)?0:(opcg_cnt[6:3]-1)};

    assign src_opcg_data_vld_pos = !src_opcg_data_vld_r1 & src_opcg_data_vld;
    assign src_opcg_data_vld_neg =  src_opcg_data_vld_r1 & !src_opcg_data_vld;

    //Require: opcg data & data vld is sustain HIGH for single CG-NZ
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
          opcg_cnt <= 'd0;
        end else if(src_opcg_data_vld)begin
          opcg_cnt <= opcg_cnt + 1;
        end else begin
          opcg_cnt <= 'd0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
          src_opcg_data_vld_r1 <= 'd0;
          src_opcg_data_vld_r2 <= 'd0;
        end else begin
          src_opcg_data_vld_r1 <= src_opcg_data_vld;
          src_opcg_data_vld_r2 <= src_opcg_data_vld_r1;
        end
    end

    reg RAM_wr_en_d1,RAM_wr_en_d2;
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
          RAM_wr_en_d1  <= 0;
          RAM_wr_en     <= 0;
        end else begin
          RAM_wr_en_d1  <= RAM_wr_en_d2;
          RAM_wr_en     <= RAM_wr_en_d1;
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
          RAM_rd_en <= 0;
          RAM_wr_en_d2 <= 0;
        end else begin 
            RAM_rd_en <= 0;
            RAM_wr_en_d2 <= 0;
            if(src_opcg_data_vld_pos)begin//cnt == 'd0 while vld is HIGH
                RAM_rd_en <= 1;
                RAM_wr_en_d2 <= 0;
            end else if (src_opcg_data_vld_neg)begin 
                RAM_rd_en <= 0;
                RAM_wr_en_d2 <= 1;
            end else if((opcg_cnt[2:0]==3'b000) && (src_opcg_data_vld))begin//cnt != 'd0
                RAM_rd_en <= 1;
                RAM_wr_en_d2 <= 1;
            end
        end
    end

    // ----------------------
    // Accumulate
    // ----------------------
    reg [15:0]      src_opcg_data_r1,src_opcg_data_r2;
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
          src_opcg_data_r1 <= 'd0;
          src_opcg_data_r2 <= 'd0;
        end else begin
          src_opcg_data_r1 <= src_opcg_data;
          src_opcg_data_r2 <= src_opcg_data_r1;
        end
    end

    // ----------------------
    // Accumulate 8B segments & Pack accumulators into 512-bit RAM_wr_data
    // ----------------------
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
              acc <= 16'd0;
        end else begin
              acc <= $signed(RAM_rd_data[7:0]) + $signed(src_opcg_data_r1[7:0]);
              RAM_wr_data[7:0] <= acc[7:0];
        end
    end

endmodule