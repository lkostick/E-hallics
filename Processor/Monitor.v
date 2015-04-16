module Monitor(input clk, rst, miss, jump, input [15:0] new_PC, branch_PC, input [1:0] Mode_Set, output reg [15:0] J_R, output reg J, output reg [1:0] Mode, input Bad_Instr_in, input Illegal_PC_in, input Illegal_Memory_in, input Spart_RCV_in, output reg Store_Current, input IFID_Stall);

localparam Illegal_PC_Handler = 16'h0090;
localparam Illegal_Register_Access_Handler = 16'h0090;
localparam Illegal_Memory_Access_Handler = 16'h0100;
localparam Spart_Handler = 16'h0030;

reg bad_instr, illegal_pc, illegal_memory, spart_rcv;

always @(posedge clk) begin
	bad_instr <= Bad_Instr_in & ~miss & |Mode;
	illegal_pc <= Illegal_PC_in & ~miss & |Mode;
	illegal_memory <= Illegal_Memory_in & ~miss & |Mode;
	spart_rcv <= (Spart_RCV_in & (~Mode[1])) & ~miss;
end

always @(posedge clk) begin
	if (rst) 
		Mode <= 2'b11;
	else if (((Bad_Instr_in|Illegal_PC_in| Illegal_Memory_in) & |Mode) |(Spart_RCV_in & ~Mode[1])) 
		Mode <= {~miss, Mode[0]};
	else if (IFID_Stall)
		Mode <= Mode;
	else
		case (Mode_Set)
			2'b01: Mode <= 2'b00;
			2'b10: Mode <= 2'b01;
			2'b11: Mode <= {1'b0, Mode[0]};
			default: Mode <= Mode;
		endcase
end

always @(*) begin
	if (miss) begin
		J = 1;
		J_R = branch_PC;
		Store_Current = 0;
	end
	else if (IFID_Stall) begin
		J = 0;
		J_R = 0;
		Store_Current = 0;
	end
	else if (spart_rcv) begin
		J = 1;
		J_R = Spart_Handler;
		Store_Current = 1;
	end
	else if (illegal_pc) begin
		J = 1;
		J_R = Illegal_PC_Handler;
		Store_Current = 1;
	end
	else if (illegal_memory) begin
		J = 1;
		J_R = Illegal_Memory_Access_Handler;
		Store_Current = 1;
	end
	else if (bad_instr) begin
		J = 1;
		J_R = Illegal_Register_Access_Handler;
		Store_Current = 1;
	end
	else if (jump) begin
		J = 1;
		J_R = new_PC;
		Store_Current = 0;
	end
	else begin
		J = 0;
		J_R = 16'hxxxx;
		Store_Current = 0;
	end
end
endmodule
