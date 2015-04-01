module BR(input [2:0] condition, input z, ov, n, taken, output reg miss);

localparam Eq = 0;
localparam Gr = 1;
localparam GrEq = 2;
localparam Le = 3;
localparam LeEq = 4;
localparam NEq = 5;
localparam Ov = 6;

always @(*) begin
	case (condition)
		Eq:
			miss = z^taken;
		Gr: 
			miss = (~(z|n))^taken;
		GrEq:
			miss = (~n)^taken;
		Le:
			miss = n ^ taken;
		LeEq:
			miss = (z|n) ^ taken;
		NEq:
			miss = (~z) ^ taken;
		Ov:
			miss = ov ^ taken;
		default:
			miss = 0;
	endcase
end	
endmodule
