module OP_CTRL #(
    parameter DATA_WIDTH = 8
)(
    input  wire                     clk,
    input  wire                     rst_n,
    // Ctrl
    input  wire                     src_cg_vld  ,// CG Frame is unfinished
    // LPE
    input wire [2*DATA_WIDTH-1:0]   lpe_dataout_0,
    input wire                      lpe_dataout_1,
    input wire                      lpe_dataout_vld,

    input  wire                     lpe_bram_en,
    input  wire [7:0]               lpe_bram_addr,
    input  wire [7:0]               lpe_bram_addr_max,// MAX = N1/4

    //PRE
    (* ram_style = "block" *) output wire [15:0]              lpe_2_rpe_2B,
    output wire                     lpe_2_rpe_vld,
    output wire                     dst_op_rdy  
);
    wire [7:0]  rpe_bram_addr;
    wire rpe_bram_en  ;
  
    (*DONT_TOUCH= "yes"*) OP_CTRL_FSM#(
      .DATA_WIDTH(DATA_WIDTH)
    )u_OP_CTRL_FSM(
      .clk                            (clk              ),
      .rst_n                          (rst_n            ),
  
      .src_cg_vld                     (src_cg_vld       ),
  
      .lpe_dataout_vld                (lpe_dataout_vld  ),
      .lpe_bram_addr_max              (lpe_bram_addr_max),
      
      .lpe_2_rpe_vld                  (lpe_2_rpe_vld    ),
      .dst_op_rdy                     (dst_op_rdy       ),
      .rpe_bram_addr                  (rpe_bram_addr ),
      .rpe_bram_en                    (rpe_bram_en   )
    );
    
    //----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
    //16b*104
    (*DONT_TOUCH= "yes"*) RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CLOCK_DOMAINS("COMMON"),
                        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
			.WRITE_WIDTH_A(18), .WRITE_WIDTH_B(18),
			.READ_WIDTH_A(18), .READ_WIDTH_B(18))
        	bram1 (
	                .ADDRARDADDR(rpe_bram_addr),
        	        .ADDRBWRADDR(lpe_bram_addr),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{rpe_bram_en}}),
	                .WEBWE({4{1'b1}}),
                  .DINBDIN({lpe_dataout_0,lpe_dataout_1}),
	                .DOUTADOUT(lpe_2_rpe_2B), 
	                .CLKARDCLK(clk),
	                .CLKBWRCLK(clk),
	                .ENARDEN(rpe_bram_en),
	                .ENBWREN(lpe_bram_en),
	                .REGCEAREGCE(rpe_bram_en),
	                .REGCEB(lpe_bram_en),
	                .RSTRAMARSTRAM(rst_n),
	                .RSTRAMB(rst_n),
	                .RSTREGARSTREG(rst_n),
	                .RSTREGB(rst_n) );

    endmodule