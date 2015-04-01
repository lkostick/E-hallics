module Memory_Check(input Mode, input jump, miss, input [3:0] new_PC, branch_PC, input memre, memwe, input [3:0] p0, output reg jump_out, miss_out, Illegal_PC, Illegal_Memory);

reg Illegal_Jump, Illegal_Branch;

always @(*) begin
	if (jump & ~|new_PC & ~Mode) begin
		Illegal_Jump = 1;
		jump_out = 0;
	end
	else begin
		Illegal_Jump = 0;
		jump_out = jump;
	end
	if (miss & ~|branch_PC & ~Mode) begin
		Illegal_Branch = 1;
		miss_out = 0;
	end
	else begin
		Illegal_Branch = 0;
		miss_out = miss;
	end
	Illegal_PC = Illegal_Jump | Illegal_Branch;

	if ((memre|memwe) & ~Mode & ~|p0)
		Illegal_Memory = 1;
	else 
		Illegal_Memory = 0;
end
endmodule
