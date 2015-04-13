// Latch-based register file
// Write at clock high and read at clock low
module RF(input clk, rst, we, input[3:0] p0_addr, p1_addr, dst_addr, input[15:0] dst, output[15:0] p0, p1);
	
	reg [15:0] RF[0:15];
	
	assign	p0 = RF[p0_addr];
	assign 	p1 = RF[p1_addr];

	always @(posedge clk)
		if (we)
			RF[dst_addr] <= dst;
		else
			RF[dst_addr] <= RF[dst_addr];
			
endmodule
