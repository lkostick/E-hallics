`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:51:17 01/29/2015 
// Design Name: 
// Module Name:    BAUD_Rate_Gen 
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

// Baud rate is fixed at 38400
module BAUD_Rate_Gen( input clk, output reg Enable);

	reg [7:0] Counter;

	/**
	* Count down and set enable signal.
	*/
	always @(posedge clk)
		if (Counter == 8'h00) begin
			Counter <= 8'ha2;
			Enable <= 1;
		end
		else begin
			Counter <= Counter - 1;
			Enable <= 0;
		end

endmodule //BAUD_Rate_Gen
