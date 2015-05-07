module Stall_Ctrl(input i_hit, d_hit, Mem_op, output reg PC_stall, IFID_stall, IDEX_stall, EXMEM_stall, MEMWB_stall, IDEX_flush, input Mem_re_EX, Mem_we_ID, input [3:0] dst_addr, p0_addr, p1_addr, input send, full, input accelerator_stall);
always @(*) begin
	if (~i_hit) begin
		PC_stall = 1;
		IFID_stall = 1;
		IDEX_stall = 1;
		EXMEM_stall = 1;
		MEMWB_stall = 1;
		IDEX_flush = 0;
	end
	else if ((Mem_op & ~d_hit) | accelerator_stall) begin //Mem read stall or accelerator read stall
		PC_stall = 1;
		IFID_stall = 1;
		IDEX_stall = 1;
		EXMEM_stall = 1;
		MEMWB_stall = 1;
		IDEX_flush = 0;
	end
	else if (Mem_re_EX & ~Mem_we_ID) begin // load use stall
		if (dst_addr == p0_addr || dst_addr == p1_addr) begin
			PC_stall = 1;
			IFID_stall = 1;
			IDEX_flush = 1;
		end
		else begin
			PC_stall = 0;
			IFID_stall = 0;
			IDEX_flush = 0;
		end
		IDEX_stall = 0;
		EXMEM_stall = 0;
		MEMWB_stall = 0;
	end
	else if (send & full) begin // send data to spart and spart queue is full
		PC_stall = 1;
		IFID_stall = 1;
		IDEX_stall = 1;
		IDEX_flush = 0;
		EXMEM_stall = 0;
		MEMWB_stall = 0;
	end
	else begin
		PC_stall = 0;
		IFID_stall = 0;
		IDEX_stall = 0;
		EXMEM_stall = 0;
		MEMWB_stall = 0;
		IDEX_flush = 0;
	end
end
endmodule
