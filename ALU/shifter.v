`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:07:46 03/24/2015 
// Design Name: 
// Module Name:    shifter 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module shifter(in, shamt, select, out);
	localparam logicleft = 2'b11;
	localparam logicright = 2'b00;
	localparam arithright = 2'b01;
	
	input[15:0] in;
	input[3:0] shamt;
	input[1:0] select;
	wire[15:0] aout;
	output reg[15:0] out;
	
	arithshift asr(.in(in), .shamt(shamt), .out(aout));
	
	always@(*) begin
		case(select)
			
			logicleft: begin
				out = (in << shamt);
			end
			
			logicright: begin
				out = (in >> shamt);
			end
			
			arithright: begin
				out = aout;
			end
			
			default: begin
				out = 16'hxxxx;
			end
		endcase

	end

endmodule
