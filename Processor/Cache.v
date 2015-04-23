module cache_unif (input clk, rst, we, re, wt, input [15:0] i_addr_pre, d_addr_pre, i_addr, d_addr, wrt_data, output i_hit, d_hit, output [15:0] instr, d_data);

reg [15:0] ROM[0:255];
reg [15:0] RAM[0:255];

initial $readmemh("instr.asm", ROM);

reg [15:0] addr;

always @(posedge clk)
	addr <= i_addr_pre;

assign instr = (addr[8]) ? RAM[addr[7:0]] : ROM[addr[7:0]];

always @(posedge clk)
	if (we & d_addr_pre[8] & ~|d_addr_pre[15:9])
		RAM[d_addr_pre[7:0]] <= wrt_data;
	else
		RAM[d_addr_pre[7:0]] <= RAM[d_addr_pre[7:0]];

assign d_data = (d_addr_pre[8]) ? RAM[d_addr_pre[7:0]]: ROM[d_addr_pre[7:0]];

assign i_hit = 1;
assign d_hit = 1;
endmodule
