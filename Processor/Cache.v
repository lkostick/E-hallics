module cache_unif (input clk, rst, we, re, wt, input [15:0] i_addr_pre, d_addr_pre, i_addr, d_addr, wrt_data, output i_hit, d_hit, output [15:0] instr, d_data);

reg [15:0] ROM[0:255];
reg [15:0] RAM[0:16383];

initial $readmemh("instr.asm", ROM);

reg [15:0] addr;

always @(posedge clk)
	addr <= i_addr_pre;

assign instr = (addr >= 16'h1000) ? RAM[addr[14:0]-16'h1000] : ROM[addr[7:0]];

always @(posedge clk)
	if (we & ~|d_addr[15:12])
		RAM[d_addr[14:0]-16'h1000] <= wrt_data;
	else
		RAM[d_addr[14:0]-16'h1000] <= RAM[d_addr[14:0]-16'h1000];

assign d_data = (d_addr >=16'h1000) ? RAM[d_addr[14:0]-16'h1000]: ROM[d_addr[7:0]];

assign i_hit = 1;
assign d_hit = 1;
endmodule
