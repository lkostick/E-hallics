module top_level (input clk, rst, rxd, output txd);

reg [15:0] i_addr_read;
wire [15:0] i_addr, d_addr, wrt_data, spart_receive_data, rd_data, instr;
wire Mem_re, Mem_we, spart_send, spart_full, clk_100mhz, spart_RCV;
wire [7:0] spart_send_data;
wire [2:0] spart_addr;

reg [15:0] ROM[0:255];
reg [15:0] RAM[0:255];
reg rst_1, rst_2;

always @(posedge clk_100mhz) begin
	rst_1 <= rst;
	rst_2 <= rst_1;
end

clk_gen iCLK (.CLKIN_IN(clk), .RST_IN(rst_2), .CLKIN_IBUFG_OUT(clk_100mhz));
	 
Processor iCPU(clk_100mhz, rst_2, 1'b1, instr, i_addr, 1'b1, d_addr, Mem_re, Mem_we, wrt_data, rd_data, spart_send, spart_send_data, spart_full, spart_RCV, spart_addr, spart_receive_data);

spart iSPART(clk_100mhz, rst_2, spart_full, spart_send, spart_send_data, spart_RCV, spart_addr, spart_receive_data, txd, rxd);



initial 
	$readmemh("instr.asm", ROM);

always @(posedge clk_100mhz)
	i_addr_read<= i_addr;
	
assign instr = (i_addr_read[8]) ? RAM[i_addr_read[7:0]]: ROM[i_addr_read[7:0]];
		
always @(posedge clk_100mhz)
	if( Mem_we & d_addr[8])
		RAM[d_addr[7:0]] <= wrt_data;
	else
		RAM[d_addr[7:0]] <= RAM[d_addr[7:0]];

assign	rd_data = (d_addr[8])? RAM[d_addr[7:0]] : ROM[d_addr[7:0]];

endmodule
