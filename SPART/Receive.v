module Receive(output reg [7:0] DATA, output RDA, input RxD, Enable, clk);

	reg [3:0] Counter, Signal_C;

	always @(posedge clk)
		if ({Enable, Signal_C} == 5'h17)
			DATA <= {RxD, DATA[7:1]};
		else
			DATA <= DATA;

	always @(posedge clk)
		Signal_C <= Signal_C + (Enable & (|Counter));

	always @(posedge clk)
		if (Enable & ~|{RxD, Counter})
			Counter <= 4'h9;
		else
			Counter <= Counter - &{Enable, Signal_C};

	assign RDA  = &{Enable, Signal_C, Counter[0]} & ~|{Counter[3:1]};
	
endmodule //Receive