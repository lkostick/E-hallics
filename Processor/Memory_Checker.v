module Memory_Check(input Mode, input jump, miss, input [15:0] new_PC, branch_PC, input memre, memwe, input [15:0] p0, output reg jump_out, miss_out, Illegal_PC, Illegal_Memory);

localparam RESERVE_AREA = 16'h0100;
reg Illegal_Jump, Illegal_Branch;


assign illegal_new_PC = (new_PC < RESERVE_AREA)? 1: 0;
assign illegal_branch_PC = (branch_PC < RESERVE_AREA)? 1: 0;
assign illegal_p0 = (p0 < RESERVE_AREA)? 1: 0;

always @(*) begin
	if (jump & illegal_new_PC & ~Mode) begin
		Illegal_Jump = 1;
		jump_out = 0;
	end
	else begin
		Illegal_Jump = 0;
		jump_out = jump;
	end
	if (miss & illegal_branch_PC & ~Mode) begin
		Illegal_Branch = 1;
		miss_out = 0;
	end
	else begin
		Illegal_Branch = 0;
		miss_out = miss;
	end
	Illegal_PC = Illegal_Jump | Illegal_Branch;

	if ((memre|memwe) & ~Mode & illegal_p0)
		Illegal_Memory = 1;
	else 
		Illegal_Memory = 0;
end
endmodule
