module PC(input clk, rst, i_hit, jump, stall, Mode, input [15:0] J_R, output reg[15:0] PC, output [15:0] next_PC);
	assign next_PC = (jump)? J_R:
						  (~i_hit|stall|~Mode) ? PC:
						  PC + 1;
						  
	always @(posedge clk)
		if (rst)
			PC <= 16'h0000;
		else
			PC <= next_PC;
		
endmodule
