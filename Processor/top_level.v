module top_level (input clk, rst, rxd, output txd);

localparam RESERVED_AREA = 16'h0100;
localparam Illegal_PC_Handler = 16'h0090;
localparam Illegal_Register_Access_Handler = 16'h0090;
localparam Illegal_Memory_Access_Handler = 16'h0100;
localparam Spart_Handler = 16'h0030;


wire [15:0] i_addr, d_addr, wrt_data, spart_receive_data, rd_data, instr, i_addr_post, d_addr_post;
wire Mem_re, Mem_we, i_hit, d_hit, spart_send, spart_full, clk_100mhz, spart_RCV;
wire [7:0] spart_send_data;
wire [2:0] spart_addr;

clk_gen iCLK (.CLKIN_IN(clk), .RST_IN(~rst), .CLKIN_IBUFG_OUT(clk_100mhz));
	 
cache_unif iCASH(.clk(clk_100mhz), .rst(~rst), .we(Mem_we), .re(Mem_re), .wt(0), .i_addr_pre(i_addr), .i_addr(i_addr_post), .d_addr_pre(d_addr), .d_addr(d_addr_post), .wrt_data(wrt_data), .i_hit(i_hit), .d_hit(d_hit), .instr(instr), .d_data(rd_data));

Processor #(RESERVED_AREA, Illegal_PC_Handler, Illegal_Register_Access_Handler, Illegal_Memory_Access_Handler, Spart_Handler) iCPU(clk_100mhz, ~rst, i_hit, instr, i_addr, d_hit, d_addr, Mem_re, Mem_we, wrt_data, rd_data, spart_send, spart_send_data, spart_full, spart_RCV, spart_addr, spart_receive_data, i_addr_post, d_addr_post);

spart iSPART(clk_100mhz, ~rst, spart_full, spart_send, spart_send_data, spart_RCV, spart_addr, spart_receive_data, txd, rxd);

endmodule
