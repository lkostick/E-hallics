module Flags(input clk, rst, Z, OV, N, input [1:0] Update, output reg z, ov, n);

	always @(posedge clk, posedge rst) begin
		if (rst) begin
			z <= 0;
			ov <= 0;
			n <= 0;
		end
		else begin
			z <= (Update[1])? Z:z;
			ov <= (Update[0])? OV: ov;
			n <= (Update[0])? N: n ;
		end
	end
endmodule
