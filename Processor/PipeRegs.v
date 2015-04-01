module IF_ID(clk, rst, stall, instr_in, instr_out, PC_in, PC_out);

	input clk, rst, stall;
	input [15:0] instr_in, PC_in;
	output reg[15:0] instr_out, PC_out;

	always @(posedge clk, posedge rst) begin
		if (rst) begin
			PC_out <= 16'h1000;
			instr_out <= 16'h0000;
		end
		else if (stall) begin
			PC_out <= PC_out;
			instr_out <= instr_out;
		end
		else begin
			PC_out <= PC_in;
			instr_out <= instr_in;
		end
	end
endmodule

module ID_EX(clk, rst, stall, flush, Alu_Op_in, Alu_Op_out, we_in, we_out, dst_addr_in, dst_addr_out, Updateflag_in, Updateflag_out, p0_in, p0_out, p1_in, p1_out, condition_in, condition_out, taken_in, taken_out, branch_PC_in, branch_PC_out, source_sel_in, source_sel_out, Mem_re_in, Mem_re_out, Mem_we_in, Mem_we_out, Mem_sel_in, Mem_sel_out, p0_addr_in, p0_addr_out, p1_addr_in, p1_addr_out);

	input clk, rst, we_in, stall, flush;
	input [3:0] dst_addr_in;
	input [1:0] Updateflag_in;
	input [2:0] Alu_Op_in;
	input [15:0] p0_in, p1_in;
	output reg[3:0] dst_addr_out;
	output reg[1:0] Updateflag_out;
	output reg[2:0] Alu_Op_out;
	output reg[15:0] p0_out, p1_out;
	output reg we_out;
	input [2:0] condition_in;
	output reg[2:0] condition_out;
	input taken_in;
	output reg taken_out;
	input [15:0] branch_PC_in;
	output reg[15:0] branch_PC_out;
	input [1:0] source_sel_in;
	output reg [1:0] source_sel_out;
	input Mem_re_in, Mem_we_in, Mem_sel_in;
	output reg Mem_re_out, Mem_we_out, Mem_sel_out;
	input [3:0] p0_addr_in, p1_addr_in;
	output reg [3:0] p0_addr_out, p1_addr_out;

	always @(posedge clk, posedge rst) begin
		if (rst| flush) begin
			Alu_Op_out <= 0;
			dst_addr_out <= 0;
			we_out <= 0;
			Updateflag_out <= 0;
			p0_out <=0;
			p1_out <=0;
			condition_out <= 3'h7;
			taken_out <= 0;
			branch_PC_out <= 16'hxxxx;
			source_sel_out <= 2'b00;
			Mem_re_out <= 0;
			Mem_we_out <= 0;
			Mem_sel_out <= 0;
			p0_addr_out <= 0;
			p1_addr_out <= 0;
		end
		else if (stall) begin
			Alu_Op_out <= Alu_Op_out;
			dst_addr_out <= dst_addr_out;
			we_out <= we_out;
			Updateflag_out <= Updateflag_out;
			p0_out <= p0_out;
			p1_out <= p1_out;
			condition_out <= condition_out;
			taken_out <= taken_out;
			branch_PC_out <= branch_PC_out;
			source_sel_out <= source_sel_out;
			Mem_re_out <= Mem_re_out;
			Mem_we_out <= Mem_we_out;
			Mem_sel_out <= Mem_sel_out;
			p0_addr_out <= p0_addr_out;
			p1_addr_out <= p1_addr_out;
		end
		else begin
			Alu_Op_out <= Alu_Op_in;
			dst_addr_out <= dst_addr_in;
			we_out <= we_in;
			Updateflag_out <= Updateflag_in;
			p0_out <= p0_in;
			p1_out <= p1_in;
			condition_out <= condition_in;
			taken_out <= taken_in;
			branch_PC_out <= branch_PC_in;
			source_sel_out <= source_sel_in;
			Mem_re_out <= Mem_re_in;
			Mem_we_out <= Mem_we_in;
			Mem_sel_out <= Mem_sel_in;
			p0_addr_out <= p0_addr_in;
			p1_addr_out <= p1_addr_in;
		end
	end
endmodule

module EX_MEM(clk, rst, stall, alu_in, alu_out, we_in, we_out, dst_addr_in, dst_addr_out, Mem_re_in, Mem_re_out, Mem_we_in, Mem_we_out, Mem_sel_in, Mem_sel_out, d_addr_in, d_addr_out, wrt_data_in, wrt_data_out);
	input clk, rst, we_in, stall;
	output reg we_out;
	input [3:0] dst_addr_in;
	output reg[3:0] dst_addr_out;
	input [15:0] alu_in;
	output reg[15:0] alu_out;
	input Mem_re_in, Mem_we_in, Mem_sel_in;
	output reg Mem_re_out, Mem_we_out, Mem_sel_out;
	input [15:0] d_addr_in, wrt_data_in;
	output reg [15:0] d_addr_out, wrt_data_out;

	always @(posedge clk, posedge rst) begin
		if (rst) begin
			we_out <= 0;
			dst_addr_out <=0;
			alu_out <= 0;
			Mem_re_out <= 0;
			Mem_we_out <= 0;
			Mem_sel_out <= 0;
			d_addr_out <= 0;
			wrt_data_out <= 0;
		end
		else if (stall) begin
			we_out <= we_out;
			dst_addr_out <=dst_addr_out;
			alu_out <= alu_out;
			Mem_re_out <= Mem_re_out;
			Mem_we_out <= Mem_we_out;
			Mem_sel_out <= Mem_sel_out;
			d_addr_out <= d_addr_out;
			wrt_data_out <= wrt_data_out;
		end
		else begin
			we_out <= we_in;
			dst_addr_out <=dst_addr_in;
			alu_out <= alu_in;
			Mem_re_out <= Mem_re_in;
			Mem_we_out <= Mem_we_in;
			Mem_sel_out <= Mem_sel_in;
			d_addr_out <= d_addr_in;
			wrt_data_out <= wrt_data_in;
		end
	end
endmodule
	
module MEM_WB(clk, rst, stall, data_in, data_out, we_in, we_out, dst_addr_in, dst_addr_out);
	input clk, rst, we_in, stall;
	output reg we_out;
	input [3:0] dst_addr_in;
	output reg[3:0] dst_addr_out;
	input [15:0] data_in;
	output reg[15:0] data_out;

	always @(posedge clk, posedge rst) begin
		if (rst|stall) begin
			we_out <= 0;
			dst_addr_out <=0;
			data_out <= 0;
		end
		else begin
			we_out <= we_in;
			dst_addr_out <=dst_addr_in;
			data_out <= data_in;
		end
	end
endmodule
