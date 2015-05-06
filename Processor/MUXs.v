module Instr_MUX(input i_hit, jump, input[15:0] instr_i, output reg [15:0] instr_o);
	always @(*)
		if (jump)
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

module JR_MUX(input sel, input [15:0] imme, input [15:0] Reg, output reg [15:0] J_R);
always @(*)
	if (sel)
		J_R = Reg;
	else 
		J_R = imme;
endmodule

module Source_MUX(input[1:0] sel, input [15:0] JL_PC, input[15:0] alu, input [15:0] spart, output reg [15:0] data);
always @(*)
	case (sel)
		2'b00:
			data = alu;
		2'b01:
			data = JL_PC;
		2'b10:
			data = spart;
		default:
			data = alu;
	endcase
endmodule

module Memory_MUX(input sel, input [15:0]  alu, input [15:0] mem, output reg [15:0] data);
always @(*)
	if (sel)
		data = mem;
	else
		data = alu;
endmodule

module Bypass_MUX(input sel, input [15:0] in, input [15:0] bypass, output reg [15:0] out);
always @(*)
	if (sel)
		out = bypass;
	else
		out = in;
endmodule

module SPART_MUX(input sel, input[15:0] p1, output reg[7:0] out);
always @(*)
	if (sel)
		out = p1[15:8];
	else
		out = p1[7:0];
endmodule
