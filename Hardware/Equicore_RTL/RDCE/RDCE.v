module RDCE #(
    parameter BRAM_OPCG_ADDR_WIDTH = 7,
    parameter BRAM_W_ADDR_WIDTH = 11,
    parameter BRAM_DATA_WIDTH = 256,
    parameter DATA_WIDTH        = 8 ,
    parameter SIM               = 0
)(
    input  wire                             clk             ,
    input  wire                             rst_n           ,

    // OPCG BRAM
    input  wire [BRAM_DATA_WIDTH-1:0]       ldce_rd_data    ,
    input  wire                             ldce_rdy        ,
    output wire                             ldce_rd_en      ,
    output wire[BRAM_OPCG_ADDR_WIDTH-1:0]   ldce_rd_addr    ,
    // W BRAM
    input  wire [BRAM_DATA_WIDTH-1:0]       w_wr_data       ,
    input  wire                             w_wr_en         ,
    input  wire [BRAM_W_ADDR_WIDTH-1:0]     w_wr_addr       ,

    // CTRL
    input  wire [2:0]                       opcg_len        ,//len(N1)/64B -> max: 8
    input  wire [7:0]                       w_rounds        ,//len(N3)     -> max: 256
    input  wire [3:0]                       cg_l3_len       ,//len(2*L3+1) -> max: 13
    // Output
    output wire [31:0]                      result_out      ,
    output wire                             result_vld
);
    wire [BRAM_DATA_WIDTH-1:0]       w_rd_data       ;
    wire                             w_rdy           ;
    wire                             w_rd_en         ;
    wire [BRAM_W_ADDR_WIDTH-1:0]     w_rd_addr       ;
    // -------------------------
    // RDCE_CTRL
    // -------------------------
    wire [BRAM_DATA_WIDTH-1:0]      ctrl_2_CH_opcg_data ;
    wire [BRAM_DATA_WIDTH-1:0]      ctrl_2_CH_w_data    ;
    wire                            ctrl_2_CH_data_vld  ;
    wire                            ctrl_2_CH_final_en  ;

    RDCE_CTRL #(
        .BRAM_OPCG_ADDR_WIDTH(BRAM_OPCG_ADDR_WIDTH),
        .BRAM_W_ADDR_WIDTH(BRAM_W_ADDR_WIDTH),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH)
    ) u_rdce_ctrl (
        .clk                    (clk),
        .rst_n                  (rst_n),

        .ldce_rd_data           (ldce_rd_data),
        .ldce_rdy               (ldce_rdy),
        .ldce_rd_en             (ldce_rd_en),
        .ldce_rd_addr           (ldce_rd_addr),
        .w_rd_data              (w_rd_data),
        .w_rdy                  (w_rdy),
        .w_rd_en                (w_rd_en),
        .w_rd_addr              (w_rd_addr),
        .opcg_len               (opcg_len),
        .w_rounds               (w_rounds),
        .cg_l3_len              (cg_l3_len),

        .opcg_data              (ctrl_2_CH_opcg_data ),
        .w_data                 (ctrl_2_CH_w_data    ),
        .opcg_w_data_vld        (ctrl_2_CH_data_vld  ),
        .final_result_en        (ctrl_2_CH_final_en  )
    );

    RDCE_PE #(
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .DATA_WIDTH     (DATA_WIDTH     ),
        .W_CH           (8           ),
        .SIM            (SIM            )
    )u_RDCE_PE(
        .clk                    (clk      ),
        .rst_n                  (rst_n    ),
        .opcg_data              (ctrl_2_CH_opcg_data ),
        .w_data                 (ctrl_2_CH_w_data    ),
        .opcg_w_data_vld        (ctrl_2_CH_data_vld  ),
        .final_result_en        (ctrl_2_CH_final_en  ),
        .result_out             (result_out ),
        .result_vld             (result_vld)
    );
 
    // ================= RAM IP =================
    wire [71:0] uram_din_a [7:0];
    (* ram_style = "block" *) wire [71:0] uram_dout_b[7:0];

    genvar i;

    generate
        if (SIM) begin : gen_sim_bram
            // RTL BRAM
            BRAM_SIM #(
                .ADDR_WIDTH     (BRAM_W_ADDR_WIDTH),
                .DATA_WIDTH     (BRAM_DATA_WIDTH)
            ) u_W_BRAM (
                .clk            (clk),
                .wr_en          (w_wr_en),
                .rd_en          (w_rd_en),
                .wr_addr        (w_wr_addr),
                .rd_addr        (w_rd_addr),
                .wr_data        (w_wr_data),
                .rd_data        (w_rd_data)
            );
        end else for (i = 0; i < 4; i = i + 1) begin : URAM_LANE
            // BRAM 512*1024(default N3:128, N1:512)
            assign uram_din_a[i] = {8'b0, w_wr_data[ (i+1)*64-1 : i*64 ] }; // 高 8bit 填 0 -> 72bit

               (*DONT_TOUCH= "yes"*) URAM288_BASE #(
                  .AUTO_SLEEP_LATENCY(8),            // Latency requirement to enter sleep mode
                  .AVG_CONS_INACTIVE_CYCLES(10),     // Average consecutive inactive cycles when is SLEEP mode for power
                                                     // estimation
                  .BWE_MODE_A("PARITY_INTERLEAVED"), // Port A Byte write control
                  .BWE_MODE_B("PARITY_INTERLEAVED"), // Port B Byte write control
                  .EN_AUTO_SLEEP_MODE("FALSE"),      // Enable to automatically enter sleep mode
                  .EN_ECC_RD_A("FALSE"),             // Port A ECC encoder
                  .EN_ECC_RD_B("FALSE"),             // Port B ECC encoder
                  .EN_ECC_WR_A("FALSE"),             // Port A ECC decoder
                  .EN_ECC_WR_B("FALSE"),             // Port B ECC decoder
                  .IREG_PRE_A("FALSE"),              // Optional Port A input pipeline registers
                  .IREG_PRE_B("FALSE"),              // Optional Port B input pipeline registers
                  .IS_CLK_INVERTED(1'b0),            // Optional inverter for CLK
                  .IS_EN_A_INVERTED(1'b0),           // Optional inverter for Port A enable
                  .IS_EN_B_INVERTED(1'b0),           // Optional inverter for Port B enable
                  .IS_RDB_WR_A_INVERTED(1'b0),       // Optional inverter for Port A read/write select
                  .IS_RDB_WR_B_INVERTED(1'b0),       // Optional inverter for Port B read/write select
                  .IS_RST_A_INVERTED(1'b0),          // Optional inverter for Port A reset
                  .IS_RST_B_INVERTED(1'b0),          // Optional inverter for Port B reset
                  .OREG_A("FALSE"),                  // Optional Port A output pipeline registers
                  .OREG_B("FALSE"),                  // Optional Port B output pipeline registers
                  .OREG_ECC_A("FALSE"),              // Port A ECC decoder output
                  .OREG_ECC_B("FALSE"),              // Port B output ECC decoder
                  .RST_MODE_A("SYNC"),               // Port A reset mode
                  .RST_MODE_B("SYNC"),               // Port B reset mode
                  .USE_EXT_CE_A("FALSE"),            // Enable Port A external CE inputs for output registers
                  .USE_EXT_CE_B("FALSE")             // Enable Port B external CE inputs for output registers
               )
               URAM288_BASE_inst (
                  .DBITERR_A(),               // 1-bit output: Port A double-bit error flag status
                  .DBITERR_B(),               // 1-bit output: Port B double-bit error flag status
                  .DOUT_A(),                  // 72-bit output: Port A read data output
                  .DOUT_B(uram_dout_b[i]),    // 72-bit output: Port B read data output
                  .SBITERR_A(),               // 1-bit output: Port A single-bit error flag status
                  .SBITERR_B(),               // 1-bit output: Port B single-bit error flag status
                  .ADDR_A({12'b0, w_wr_addr}),// 23-bit input: Port A address
                  .ADDR_B({12'b0, w_rd_addr}),// 23-bit input: Port B address
                  .BWE_A(9'h1FF),             // 9-bit input: Port A Byte-write enable
                  .BWE_B(9'b0),               // 9-bit input: Port B Byte-write enable
                  .CLK(clk),                  // 1-bit input: Clock source
                  .DIN_A(uram_din_a[i]),      // 72-bit input: Port A write data input
                  .DIN_B(72'b0),              // 72-bit input: Port B write data input
                  .EN_A(w_wr_en),             // 1-bit input: Port A enable
                  .EN_B(w_rd_en),             // 1-bit input: Port B enable
                  .INJECT_DBITERR_A(1'b0),    // 1-bit input: Port A double-bit error injection
                  .INJECT_DBITERR_B(1'b0),    // 1-bit input: Port B double-bit error injection
                  .INJECT_SBITERR_A(1'b0),    // 1-bit input: Port A single-bit error injection
                  .INJECT_SBITERR_B(1'b0),    // 1-bit input: Port B single-bit error injection
                  .OREG_CE_A(),               // 1-bit input: Port A output register clock enable
                  .OREG_CE_B(),               // 1-bit input: Port B output register clock enable
                  .OREG_ECC_CE_A(),           // 1-bit input: Port A ECC decoder output register clock enable
                  .OREG_ECC_CE_B(),           // 1-bit input: Port B ECC decoder output register clock enable
                  .RDB_WR_A(1'b1),            // 1-bit input: Port A read/write select
                  .RDB_WR_B(1'b0),            // 1-bit input: Port B read/write select
                  .RST_A(rst_n),              // 1-bit input: Port A asynchronous or synchronous reset for output
                                              // registers

                  .RST_B(rst_n),              // 1-bit input: Port B asynchronous or synchronous reset for output
                                              // registers
                  .SLEEP(1'b0)                // 1-bit input: Dynamic power gating control
               );

               // End of URAM288_BASE_inst instantiation
            end
    endgenerate


    generate
      for (i = 0; i < 4; i = i + 1) begin : PACK_OUT
        assign w_rd_data[ (i+1)*64-1 : i*64 ] = uram_dout_b[i][63:0];
      end
    endgenerate

endmodule