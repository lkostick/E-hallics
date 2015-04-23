`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:23:14 03/24/2015 
// Design Name: 
// Module Name:    arithmetic 
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
module arithmetic(P1, P2, select, out, pV);

	input[15:0] P1, P2;
	input select;	//if select is 0, addition is performed else subtraction is performed
	output reg[15:0] out;
	output reg pV;
	reg nV;
	reg[15:0] x;
	
	always@(*) begin
		x = P2 ^ {16{select}};
		out = P1 + x + select;
		pV = out[15] & ~P1[15] & ~x[15];
		nV = ~out[15] & P1[15] & x[15];
		if(pV == 1'b1)	begin		//if overflow found, saturate result to 16'h7FFF and set the overflow flag to 1
			out = 16'h7FFF;
		end 
		if(nV == 1'b1)	begin	//if underflow found, saturate ALUresult to 16'h8000 and set the overflow flag to 0
			out = 16'h8000;
		end
	end

endmodule
