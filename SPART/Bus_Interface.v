`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:50:25 01/29/2015 
// Design Name: 
// Module Name:    Bus_Interface 
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
module Bus_Interface (input RDA, TBR, IORW, inout[7:0] DATABUS, input[1:0] IOADDR, input[7:0] R_BUFFER, output reg [7:0] DATAOUT);
	
	/*
	* Change the Address Mappings
	* When IOADDR = 2'b10 or 2'b11, the IORW is required to be 1'b0.
	* This can simplify the logic for DATABUS
	* When IORW = 1, it is always send data to DATABUS
	* When IORW = 0, it is always receive data from DATABUS
	*/
	assign DATABUS = ( ~IORW ) ? 8'hzz : ( ~|IOADDR )? R_BUFFER : {6'h00, TBR, RDA};
	always @ (*)
		DATAOUT = DATABUS;

endmodule // Bus_Interface
