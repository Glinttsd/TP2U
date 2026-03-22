module W_CH #(
    parameter DATA_WIDTH    = 8,  
    parameter SIM           = 0   // 1: 仿真版本, 0: DSP
)(
    input  wire                     clk         ,
    input  wire                     rst_n       ,
    // DATA
    input  wire [4*DATA_WIDTH-1:0]  opcg_data_in,
    input  wire [4*DATA_WIDTH-1:0]  w_data_in   ,
    input  wire                     data_vld    ,
    // CTRL
    input  wire                     data_done   ,
    // Output
    output wire [31:0]              result_out  ,
    output wire                     result_vld
);
   // -------------------------------
    // DSP 输入/输出信号
    wire signed [26:0] dsp_A[0:3];
    wire signed [17:0] dsp_B[0:3];
    wire signed [47:0] dsp_C[0:3];
    wire signed [26:0] dsp_D[0:3];
    (*use_dsp48 = "yes"*) wire signed [47:0] dsp_P[0:3];


    (* DONT_TOUCH = "yes" *) W_CH_CTRL#(
        .DATA_WIDTH(DATA_WIDTH)
    )u_W_CH_CTRL(
        .clk                        (clk          ),
        .rst_n                      (rst_n        ),
        .data_vld                   (data_vld     ),
        .dsp_P_0                    (dsp_P[0]     ),
        .dsp_P_1                    (dsp_P[1]     ),
        .dsp_P_2                    (dsp_P[2]     ),
        .dsp_P_3                    (dsp_P[3]     ),
        .data_done                  (data_done    ),
        .result_out                 (result_out   ),
        .result_vld                 (result_vld   )
    );


    genvar i;
    generate
        for(i=0;i<4;i=i+1) begin : dsp_assign
            assign dsp_A[i] = data_vld ? 
                              {{19{opcg_data_in[(i+1)*DATA_WIDTH-1]}}, opcg_data_in[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]} 
                              : 32'd0;
            assign dsp_B[i] = data_vld ? 
                              {{10{w_data_in[(i+1)*DATA_WIDTH-1]}}, w_data_in[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]} 
                              : 24'd0;
            assign dsp_C[i] = 48'd0;
            assign dsp_D[i] = 27'd0;

            if (SIM) begin : gen_sim
                DSP_Top_SIM u_dsp_sim (
                    .CLK(clk),
                    .SCLR(~rst_n),
                    .A(dsp_A[i]),
                    .B(dsp_B[i]),
                    .C(dsp_C[i]),
                    .D(dsp_D[i]),
                    .CEA3(1),
                    .CEA4(1),
                    .CEB3(1),
                    .CEB4(1),
                    .P(dsp_P[i])
                );
            end else begin : gen_real
            // 综合版本 DSP IP
 (*DONT_TOUCH= "yes"*) DSP48E2  dsp_inst(
	            .A(dsp_A[i]),
	            .B(dsp_B[i]),
                .C(dsp_C[i]),
                .D(dsp_D[i]),
	            .P(dsp_P[i]),
	            // control DSP
	            .ALUMODE(),
	            .INMODE(),
	            .OPMODE(), 

	            // clocking reset and enables.. control signals
	            .CLK(clk),
	            .RSTA(~rst_n),
	            .RSTALLCARRYIN(~rst_n),
	            .RSTALUMODE(~rst_n),
	            .RSTB(~rst_n),
	            .RSTC(~rst_n),
	            .RSTCTRL(~rst_n),
	            .RSTD(~rst_n),
	            .RSTINMODE(~rst_n),
	            .RSTM(~rst_n),
	            .RSTP(~rst_n),
	            .CEA1(1),
	            .CEA2(1),
	            .CEAD(1),
	            .CEALUMODE(1),
	            .CEB1(1),
	            .CEB2(1),
	            .CEC(1),
	            .CECARRYIN(1),
	            .CECTRL(1),
	            .CED(1),
	            .CEINMODE(1),
	            .CEM(1),
	            .CEP(1)
            );
            end
        end
    endgenerate


endmodule
