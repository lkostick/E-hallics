module Monitor(input miss, jump, input [15:0] new_PC, branch_PC, output reg [15:0] J_R, output reg J);

always @(*) begin
	if (miss) begin
		J = 1;
		J_R = branch_PC;
	end
	else if (jump) begin
		J = 1;
		J_R = new_PC;
	end
	else begin
		J = 0;
		J_R = 16'hxxxx;
	end
end
endmodule
