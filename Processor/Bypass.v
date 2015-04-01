module Bypass(input [3:0] p0_addr_ID, p1_addr_ID, dst_addr_EX, dst_addr_MEM, p0_addr_EX, p1_addr_EX, input we_ex, we_mem, input [15:0] dst_ex, dst_mem, output reg p0_ID_bypass, p1_ID_bypass, p0_EX_bypass, p1_EX_bypass, output reg [15:0] p0_bypass_in, p1_bypass_in);

always @(*) begin
	if (~|(dst_addr_EX ^ p0_addr_ID) & we_ex) begin
		p0_ID_bypass = 1;
		p0_bypass_in = dst_ex;
	end
	else if (~|(dst_addr_MEM ^ p0_addr_ID) & we_mem) begin
		p0_ID_bypass = 1;
		p0_bypass_in = dst_mem;
	end
	else begin
		p0_ID_bypass = 0;
		p0_bypass_in = 16'hxxxx;
	end
	if (~|(dst_addr_EX ^ p1_addr_ID) & we_ex) begin
		p1_ID_bypass = 1;
		p1_bypass_in = dst_ex;
	end
	else if (~|(dst_addr_MEM ^ p1_addr_ID) & we_mem) begin
		p1_ID_bypass = 1;
		p1_bypass_in = dst_mem;
	end
	else begin
		p1_ID_bypass = 0;
		p1_bypass_in = 16'hxxxx;
	end

	if (~|(p0_addr_EX ^ dst_addr_MEM) & we_mem) 
		p0_EX_bypass = 1;
	else
		p0_EX_bypass = 0;
	if (~|(p1_addr_EX ^ dst_addr_MEM) & we_mem) 
		p1_EX_bypass = 1;
	else
		p1_EX_bypass = 0;
end

endmodule
