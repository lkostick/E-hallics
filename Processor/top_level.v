module top_level (input clk, rst, rxd, output txd);

localparam RESERVED_AREA = 16'h1000;
localparam Illegal_PC_Handler = 16'h0300;
localparam Illegal_Register_Access_Handler = 16'h0200;
localparam Illegal_Memory_Access_Handler = 16'h0400;
localparam Spart_Handler = 16'h0030;
localparam Accelerator_Handler = 16'h0500;


wire [15:0] i_addr, d_addr, wrt_data, spart_receive_data, rd_data, instr, i_addr_post, d_addr_post;
wire Mem_re, Mem_we, i_hit, d_hit, spart_send, spart_full, clk_100mhz, spart_RCV, wt, clk_50mhz;
wire [7:0] spart_send_data;
wire [2:0] spart_addr;
wire [1:0] Accelerator_mode;
wire [4:0] Accelerator_addr;
wire Accelerator_rst, Accelerator_keyfound, Accelerator_stall;
wire [15:0] Accelerator_send_data, Accelerator_receive_data;
reg [7:0] counter;
reg RST_1, RST_2;

always @(posedge clk_50mhz)
	counter <= counter + 1;
	
always @(posedge clk_50mhz)
	if (&counter) begin
		RST_1 <= ~rst;
		RST_2 <= RST_1;
	end
	else begin
		RST_1 <= RST_1;
		RST_2 <= RST_2;
	end

clk_gen iCLK (.CLKIN_IN(clk), .CLKDV_OUT(clk_50mhz), .CLKIN_IBUFG_OUT(clk_100mhz));
	 
cache iCASH(.clk(clk_50mhz), .rst(RST_1 |RST_2), .we(Mem_we), .re(Mem_re), .wt(wt), .i_addr_pre(i_addr), .i_addr(i_addr_post), .d_addr_pre(d_addr_post), .d_addr(d_addr), .wrt_data(wrt_data), .i_hit(i_hit), .d_hit(d_hit), .instr(instr), .d_data(rd_data));

Processor #(RESERVED_AREA, Illegal_PC_Handler, Illegal_Register_Access_Handler, Illegal_Memory_Access_Handler, Spart_Handler, Accelerator_Handler) iCPU(clk_50mhz, RST_1 |RST_2, i_hit, instr, i_addr, d_hit, d_addr, Mem_re, Mem_we, wrt_data, rd_data, 
	spart_send, spart_send_data, spart_full, spart_RCV, spart_addr, spart_receive_data, i_addr_post, d_addr_post, wt, Accelerator_mode, Accelerator_rst, Accelerator_addr, Accelerator_send_data, Accelerator_receive_data,
	Accelerator_stall, Accelerator_keyfound);

spart iSPART(clk_50mhz, spart_full, spart_send, spart_send_data, spart_RCV, spart_addr, spart_receive_data, txd, rxd);

ac_group iACC(clk_50mhz, Accelerator_rst, Accelerator_mode, Accelerator_addr, Accelerator_send_data, Accelerator_receive_data, Accelerator_stall, Accelerator_keyfound);
endmodule
