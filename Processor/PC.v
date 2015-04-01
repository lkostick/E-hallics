module PC(input clk, rst, i_hit, jump, stall, Mode, input [15:0] J_R, output reg[15:0] PC);
	always @(posedge clk, posedge rst) begin
		if (rst)
			PC <= 16'h1000;
		else if (jump)
			PC <= J_R;
		else if (~i_hit | stall | ~Mode)
			PC <= PC;
		else
			PC <= PC + 1;
	end
endmodule
