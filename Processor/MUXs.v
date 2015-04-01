// IF stage MUX
module Instr_MUX(input i_hit, jump, input[15:0] instr_i, output reg [15:0] instr_o);
	always @(*)
		if (~i_hit|jump)
			instr_o = 16'h0000;
		else
			instr_o = instr_i;
endmodule

module P1_MUX(input sel, input [7:0] imme, input [15:0] p1, output reg [15:0] data);

	always @(*) begin
		if (sel) 
			data = {8'h00,imme};
		else
			data = p1;
	end
endmodule

module Flush_MUX(input miss, input [15:0] instr_in, output reg [15:0] instr_out);

always @(*)
	if (miss)
		instr_out = 16'h0000;
	else
		instr_out = instr_in;
endmodule

module JR_MUX(input sel, input [15:0] imme, input [15:0] Reg, output reg [15:0] J_R);
always @(*)
	if (sel)
		J_R = Reg;
	else 
		J_R = imme;
endmodule

module Source_MUX(input[1:0] sel, input [15:0] JL_PC, input[15:0] alu, output reg [15:0] data);
always @(*)
	case (sel)
		2'b00:
			data = alu;
		2'b01:
			data = JL_PC;
		default:
			data = alu;
	endcase
endmodule
