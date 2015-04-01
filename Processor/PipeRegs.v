module IF_ID(clk, rst, instr_in, instr_out, PC_in, PC_out);

	input clk, rst;
	input [15:0] instr_in, PC_in;
	output reg[15:0] instr_out, PC_out;

	always @(posedge clk, posedge rst) begin
		if (rst) begin
			PC_out <= 16'h1000;
			instr_out <= 16'h0000;
		end
		else begin
			PC_out <= PC_in;
			instr_out <= instr_in;
		end
	end
endmodule

module ID_EX(clk, rst, Alu_Op_in, Alu_Op_out, we_in, we_out, dst_addr_in, dst_addr_out, Updateflag_in, Updateflag_out, p0_in, p0_out, p1_in, p1_out, condition_in, condition_out, taken_in, taken_out, branch_PC_in, branch_PC_out, source_sel_in, source_sel_out);

	input clk, rst, we_in;
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

	always @(posedge clk, posedge rst) begin
		if (rst) begin
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
		end
	end
endmodule

module EX_MEM(clk, rst, alu_in, alu_out, we_in, we_out, dst_addr_in, dst_addr_out);
	input clk, rst, we_in;
	output reg we_out;
	input [3:0] dst_addr_in;
	output reg[3:0] dst_addr_out;
	input [15:0] alu_in;
	output reg[15:0] alu_out;

	always @(posedge clk, posedge rst) begin
		if (rst) begin
			we_out <= 0;
			dst_addr_out <=0;
			alu_out <= 0;
		end
		else begin
			we_out <= we_in;
			dst_addr_out <=dst_addr_in;
			alu_out <= alu_in;
		end
	end
endmodule
	
module MEM_WB(clk, rst, data_in, data_out, we_in, we_out, dst_addr_in, dst_addr_out);
	input clk, rst, we_in;
	output reg we_out;
	input [3:0] dst_addr_in;
	output reg[3:0] dst_addr_out;
	input [15:0] data_in;
	output reg[15:0] data_out;

	always @(posedge clk, posedge rst) begin
		if (rst) begin
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
