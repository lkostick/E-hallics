`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:52:04 01/29/2015 
// Design Name: 
// Module Name:    Receive 
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
module Receive(output reg [7:0] DATA, output reg RDA, input RxD, Enable, clk, rst, IORW, input[1:0] IOADDR);

	reg [8:0] Receive_Buffer;
	reg [3:0] Counter;
	reg [3:0] Signal_C;
	/**
	* Each bit has 16 samples, this Receive store the 7th sample of each bit.
	*
	* When the Receive get the start bit, it set Counter to 10 and start
	* receiving the following data bits.
	*
	*/

	always @(posedge clk, posedge rst)
		if ( rst )
			Receive_Buffer <= 9'hxxx;
		// Store bit when counter is not 4'h0, Enable is 1, and Signal_C is
		// 4'h7
		else if ({|Counter, Enable, Signal_C} == 6'h37)
			Receive_Buffer <= {RxD, Receive_Buffer[8:1]};
		else
			Receive_Buffer <= Receive_Buffer;

	always @(posedge clk, posedge rst)
		if ( rst )
			Signal_C <= 4'h0;
		// sample RxD
		else if ( Enable ) begin
			// idle status
			if ( Counter == 4'h0 )
				Signal_C <= 4'h0;
			// receiving data
			else
				Signal_C <= Signal_C + 1;
		end
		// not sample RxD
		else
			Signal_C <= Signal_C;

	always @(posedge clk, posedge rst)
		if ( rst )
			Counter <= 4'h0;
		// Receiving start bit, set counter to start receiving data
		else if ({Enable, RxD, Counter} == 6'h20)
			Counter <= 4'ha;
		// Store one bit, so decreasing Counter
		else if ({Enable, Signal_C}== 5'h17)
			Counter <= Counter - 1;
		else
			Counter <= Counter;

	always @(posedge clk, posedge rst)
		if (rst)
			RDA <= 0;
		else if ( RDA == 0 && {Signal_C,Counter} == 8'h80 ) //Finish receiving data
			RDA <= 1;
		else if ({IORW,IOADDR} == 3'b100) // Driver have read the data
			RDA <= 0;
		else
			RDA <= RDA;

	always @(*)
		DATA = Receive_Buffer[7:0];	

endmodule //Receive
