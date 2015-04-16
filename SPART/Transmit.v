module Transmit(output TxD, output TBR, input [7:0] DATA, input clk, Enable, write);

	reg [8:0] Transmit_Buffer;
	reg [3:0] Counter, Signal_C;
	
	assign TxD = TBR | Transmit_Buffer[0];
	// Counter is not 0 when spart is sending data
	assign TBR = ~|Counter;

	always @(posedge clk)
		Signal_C <= Signal_C + (Enable & ~TBR);
		
	always @(posedge clk)
		if (write)
			Counter <= 4'ha;
		else
			Counter <= Counter - (&{Enable, Signal_C});
			
	always @(posedge clk)
		if (write)
			Transmit_Buffer <= {DATA, 1'b0};
		else if (&{Enable, Signal_C})
			Transmit_Buffer <= {1'b1, Transmit_Buffer[8:1]}; // Shift data
		else
			Transmit_Buffer <= Transmit_Buffer;
endmodule //Transmit