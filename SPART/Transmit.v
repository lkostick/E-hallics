module Transmit(output reg TxD, output reg TBR, input [7:0] DATA, input [1:0] IOADDR, input clk, rst, Enable, IORW);

	reg [7:0] Transmit_Buffer;
	reg [3:0] Counter;
	reg [3:0] Signal_C;
	
	always @(posedge clk)
		if ( rst )
			TxD <= 1;
		else if ( {TBR, Enable, Signal_C} == 3'b010 )
			case ( Counter )
				4'ha: // initial sending Start bit
					TxD <= 0;
				4'h1: // initial sending Stop bit
					TxD <= 1;
				default: //inital sending Data bit
					TxD <= Transmit_Buffer[0];
			endcase
		else
			TxD <= TxD;

	always @(posedge clk)
		if ( {Enable, TBR} == 2'b10 )
			Signal_C <= Signal_C + 1;
		else 
			Signal_C <= Signal_C;

	always @(posedge clk)
		if ( rst )
			TBR <= 1;
		// driver sends data to Transmit
		// set TBR to 0, start sending data bit
		else if ({TBR, IORW, IOADDR} == 4'h8)
			TBR <= 0;
		// Counter is 0 either means it is in idle status or it finishs
		// sending data. So set TBR to 1
		else if (Counter == 4'h0)
			TBR <= 1;
		else 
			TBR <= TBR;

	always @(posedge clk)
		if ( {TBR, IORW, IOADDR} == 4'h8 )
			Counter <= 4'ha;
		else if ( {Enable,Signal_C} == 5'h1f )
			Counter <= Counter -1;
		else
			Counter <= Counter;

	always @(posedge clk )
		if ({TBR, IORW, IOADDR} == 4'h8)
			Transmit_Buffer <= DATA;
		// Shift data
		else if ( {Enable, Signal_C} == 5'h1f )
			case (Counter)
				4'ha: Transmit_Buffer <= Transmit_Buffer;
				4'h0: Transmit_Buffer <= Transmit_Buffer;
				default: Transmit_Buffer <= {1'b0, Transmit_Buffer[7:1]};
			endcase
		else
			Transmit_Buffer <= Transmit_Buffer;
endmodule //Transmit

