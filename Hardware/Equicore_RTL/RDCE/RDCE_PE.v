module RDCE_PE #(
    parameter BRAM_DATA_WIDTH   = 512,
    parameter DATA_WIDTH        = 8,
    parameter W_CH              = 16,
    parameter SIM               = 0
)(
    input  wire                                 clk             ,
    input  wire                                 rst_n           ,

    // OPCG & W
    input  wire [BRAM_DATA_WIDTH-1:0]          opcg_data       ,
    input  wire [BRAM_DATA_WIDTH-1:0]          w_data          ,
    input  wire                                 opcg_w_data_vld ,

    // CTRL
    input  wire                                 final_result_en ,

    // Output
    output wire [31:0]                          result_out      ,
    output wire                                 result_vld
);

    genvar i, j;

    // -------------------------
    // Flattened intermediate signals to avoid multi-dimensional array issues
    // -------------------------
    wire [W_CH*32-1:0] ch_result_flat;
    wire [W_CH-1:0]    ch_vld;

    // -------------------------
    // 16 W_CH instances
    // -------------------------
    generate
        for(i=0; i<W_CH; i=i+1) begin : W_CH_INST
            W_CH #(
                .DATA_WIDTH(DATA_WIDTH)
            ) u_w_ch (
                .clk            (clk),
                .rst_n          (rst_n),
                .opcg_data_in   (opcg_data[i*32 +: 32]),
                .w_data_in      (w_data[i*32 +: 32]),
                .data_vld       (opcg_w_data_vld),
                .data_done      (final_result_en),
                .result_out     (ch_result_flat[i*32 +: 32]),
                .result_vld     (ch_vld[i])
            );
        end
    endgenerate

    // -------------------------
    // Unflatten ch_result_flat to array for SUM16
    // -------------------------
    wire [31:0] ch_result[0:W_CH-1];
    generate
        for(j=0; j<W_CH; j=j+1) begin : UNFLATTEN
            assign ch_result[j] = ch_result_flat[j*32 +: 32];
        end
    endgenerate


    // -------------------------
    // SUM4
    // -------------------------
    SUM4 #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_SUM4 (
        .clk          (clk),
        .rst_n        (rst_n),
        .ch0_result   (ch_result[0]),
        .ch1_result   (ch_result[1]),
        .ch2_result   (ch_result[2]),
        .ch3_result   (ch_result[3]),
        .ch_vld_in    (&ch_vld),
        .result_out   (result_out),
        .result_vld   (result_vld)
    );


endmodule
