`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:17:55 03/24/2015 
// Design Name: 
// Module Name:    arithshift 
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
module arithshift(in, shamt, out);
	input[15:0] in;
	input[3:0] shamt;
	output[15:0] out;
	wire[15:0] t0, t1, t2;
	
	assign t0 = shamt[0]? {in[15], in[15:1]} : in[15:0];
	assign t1 = shamt[1]? {{2{t0[15]}}, t0[15:2]} : t0[15:0];
	assign t2 = shamt[2]? {{4{t1[15]}}, t1[15:4]} : t1[15:0];
	assign out = shamt[3]? {{8{t2[15]}}, t2[15:8]} : t2[15:0];
	
endmodule
