module Memory_Check (input [1:0] Mode, input [15:0] Current_PC, input memre, memwe, J, input[15:0] p0, output reg Illegal_PC, Illegal_Memory);

parameter RESERVE_AREA = 16'h0100;
reg Illegal_Jump, Illegal_Branch;


assign illegalPC = (Current_PC < RESERVE_AREA)? 1: 0;
assign illegal_p0 = (p0 < RESERVE_AREA)? 1: 0;

always @(*) begin
	Illegal_PC = ~J & ~Mode[1] & Mode[0] & illegalPC;
	Illegal_Memory = (memre|memwe) & ~Mode[1] & Mode[0] & illegal_p0;
end
endmodule
