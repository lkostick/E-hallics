module Receive(output reg [7:0] DATA, output reg RDA, input RxD, Enable, clk, IORW, input[1:0] IOADDR);

	reg [8:0] Receive_Buffer;
	reg [3:0] Counter;
	reg [3:0] Signal_C;

	always @(posedge clk)
		if ({|Counter, Enable, Signal_C} == 6'h37)
			Receive_Buffer <= {RxD, Receive_Buffer[8:1]};
		else
			Receive_Buffer <= Receive_Buffer;

	always @(posedge clk)
		if ( Enable ) begin
			if ( Counter == 4'h0 )
				Signal_C <= 4'h0;
			else
				Signal_C <= Signal_C + 1;
		end
		else
			Signal_C <= Signal_C;

	always @(posedge clk)
		if ({Enable, RxD, Counter} == 6'h20)
			Counter <= 4'ha;
		else if ({Enable, Signal_C}== 5'h17)
			Counter <= Counter - 1;
		else
			Counter <= Counter;

	always @(posedge clk)
		if ( RDA == 0 && {Enable,Signal_C,Counter} == 9'h180 ) //Finish receiving data
			RDA <= 1;
		else if ({IORW,IOADDR} == 3'b100) // Driver have read the data
			RDA <= 0;
		else
			RDA <= RDA;

	always @(*)
		DATA = Receive_Buffer[7:0];
endmodule //Receive
