module PC(input clk, rst, i_hit, jump, stall, input [15:0] J_R, output reg[15:0] PC);
	always @(posedge clk, posedge rst) begin
		if (rst)
			PC <= 16'h0000;
		else if (jump)
			PC <= J_R;
		else if (~i_hit || stall)
			PC <= PC;
		else
			PC <= PC + 1;
	end
endmodule
