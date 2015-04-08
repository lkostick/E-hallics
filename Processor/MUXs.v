// IF stage MUX
module Instr_MUX(input clk, rst, i_hit, jump, Mode, input[15:0] instr_i, output reg [15:0] instr_o);
	reg counter;
	always @(posedge clk, posedge rst)
		if(rst)
			counter <= 0;
		else
			counter <= jump;
	always @(*)
		if (~i_hit|jump|~Mode|counter)
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
