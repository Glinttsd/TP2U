module SUM4 #(
    parameter DATA_WIDTH = 32
)(
    input  wire                     clk,
    input  wire                     rst_n,

    input  wire [DATA_WIDTH-1:0]    ch0_result,
    input  wire [DATA_WIDTH-1:0]    ch1_result,
    input  wire [DATA_WIDTH-1:0]    ch2_result,
    input  wire [DATA_WIDTH-1:0]    ch3_result,

    input  wire                     ch_vld_in, 

    output reg [DATA_WIDTH-1:0]     result_out,
    output reg                      result_vld
);

    // -------------------------
    // Stage 1
    // -------------------------
    integer i;
    reg [DATA_WIDTH-1:0] stage1 [0:1];
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0;i<1;i=i+1) begin
                stage1[i] <= {DATA_WIDTH{1'b0}};
            end
        end else if(ch_vld_in) begin
            stage1[0] <= ch0_result + ch1_result;
            stage1[1] <= ch2_result + ch3_result;
        end
    end

    // -------------------------
    // Stage 2a
    // -------------------------
    reg [DATA_WIDTH:0] sum1;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            sum1 <= 0;
        end else if(ch_vld_in) begin
            sum1 <= stage1[0] + stage1[1];
        end
    end


    // -------------------------
    // OUTPUT
    // -------------------------
    reg ch_vld_d1, ch_vld_d2;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ch_vld_d1  <= 0;
            ch_vld_d2  <= 0;
            result_out <= 0;
            result_vld <= 0;
        end else begin
            ch_vld_d1  <= ch_vld_in;
            ch_vld_d2  <= ch_vld_d1;
            result_out <= sum1;
            result_vld <= ch_vld_d1;
        end
    end

endmodule
