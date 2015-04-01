// Latch-based register file
// Write at clock high and read at clock low
module RF(input clk, rst, we, input[3:0] p0_addr, p1_addr, dst_addr, input[15:0] dst, output reg[15:0] p0, p1);
	
	reg [15:0] RF[15:0];
	
	always @(clk, p0_addr, p1_addr)
		if (~clk) begin
			p0 <= RF[p0_addr];
			p1 <= RF[p1_addr];
		end
	
	integer indx;
	always @(clk, dst_addr, dst, we, rst)
		if ( rst )
			for (indx = 0; indx < 16; indx = indx + 1)
				RF[indx] <= 0;
		else if (clk && we && |dst_addr)
			RF[dst_addr] <= dst;
	
endmodule
