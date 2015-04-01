// Not include cache
module Processor(clk, rst, i_hit, instr, i_addr);

	input clk, rst, i_hit;
	input [15:0] instr;
	output [15:0] i_addr;
	
	wire jump, stall, J;
	wire [15:0] J_R, instr_ID, instr_IFID_out, PC_out,instr_out;

	// IF
	PC iPC(.clk(clk), .rst(rst), .i_hit(i_hit), .jump(J), .stall(stall), .J_R(J_R), .PC(i_addr));
	Instr_MUX iMUX1(.i_hit(i_hit), .jump(J), .instr_i(instr), .instr_o(instr_out));

	IF_ID iREG1(.clk(clk), .rst(rst), .instr_in(instr_out), .instr_out(instr_IFID_out), .PC_in(i_addr), .PC_out(PC_out));

	// ID
	
	wire we_IDEX_in, we_IDEX_out, p1_sel;
	wire [15:0] p0_IDEX_in, p0_IDEX_out, p1, p1_IDEX_in, p1_IDEX_out;
	wire [3:0] p0_addr, p1_addr, dst_addr_IDEX_in, dst_addr_IDEX_out;
	wire [2:0] Alu_Op_IDEX_in, Alu_Op_IDEX_out, condition_IDEX_in, condition_IDEX_out;
	wire [7:0] Imme;
	wire [1:0] Updateflag_IDEX_in, Updateflag_IDEX_out, source_sel_IDEX_in, source_sel_IDEX_out;
	wire [15:0] data_MEMWB_out, J_PC, J_PC_out, branch_PC_IDEX_in, branch_PC_IDEX_out;
	wire we_MEMWB_out, taken_IDEX_in, taken_IDEX_out, J_sel;
	wire[3:0] dst_addr_MEMWB_out;

	Flush_MUX iMUX3(.miss(miss), .instr_in(instr_IFID_out), .instr_out(instr_ID));
	ID iID(.instr(instr_ID), .we(we_IDEX_in), .p0_addr(p0_addr), .p1_addr(p1_addr), .dst_addr(dst_addr_IDEX_in),.Alu_Op(Alu_Op_IDEX_in), .Imme(Imme), .Updateflag(Updateflag_IDEX_in), .p1_sel(p1_sel), .jump(jump), .new_PC(J_PC), .branch_PC(branch_PC_IDEX_in), .i_addr(PC_out), .condition(condition_IDEX_in), .taken(taken_IDEX_in), .J_sel(J_sel), .source_sel(source_sel_IDEX_in));

	RF iRF(.clk(clk), .rst(rst), .we(we_MEMWB_out), .p0_addr(p0_addr), .p1_addr(p1_addr), .dst_addr(dst_addr_MEMWB_out), .dst(data_MEMWB_out), .p0(p0_IDEX_in), .p1(p1));

	P1_MUX iMUX2(.sel(p1_sel), .imme(Imme), .p1(p1), .data(p1_IDEX_in));

	JR_MUX iMUX4(.sel(J_sel), .imme(J_PC), .Reg(p0_IDEX_in), .J_R(J_PC_out));

	Monitor iMON(.miss(miss), .jump(jump), .new_PC(J_PC_out), .branch_PC(branch_PC_IDEX_out), .J_R(J_R), .J(J));

	ID_EX iREG2(.clk(clk), .rst(rst), .Alu_Op_in(Alu_Op_IDEX_in), .Alu_Op_out(Alu_Op_IDEX_out), .we_in(we_IDEX_in), .we_out(we_IDEX_out), .dst_addr_in(dst_addr_IDEX_in), .dst_addr_out(dst_addr_IDEX_out), .Updateflag_in(Updateflag_IDEX_in), .Updateflag_out(Updateflag_IDEX_out), .p0_in(p0_IDEX_in), .p0_out(p0_IDEX_out), .p1_in(p1_IDEX_in), .p1_out(p1_IDEX_out), .condition_in(condition_IDEX_in), .condition_out(condition_IDEX_out), .taken_in(taken_IDEX_in), .taken_out(taken_IDEX_out), .branch_PC_in(branch_PC_IDEX_in), .branch_PC_out(branch_PC_IDEX_out), .source_sel_in(source_sel_IDEX_in), .source_sel_out(source_sel_IDEX_out));

	// EX
	wire Z_in, Z_out, OV_in, OV_out, N_in, N_out;
	wire[15:0] alu_out, data_EXMEM_in, data_EXMEM_out;
	wire we_EXMEM_out;
	wire [3:0] dst_addr_EXMEM_out;

	alu_main iALU(.P1(p0_IDEX_out), .P2(p1_IDEX_out), .Opcode(Alu_Op_IDEX_out), .Result(alu_out), .Z(Z_in), .OV(OV_in), .N(N_in));
	Flags iFLAG(.clk(clk), .rst(rst), .Z(Z_in), .OV(OV_in), .N(N_in), .Update(Updateflag_IDEX_out), .z(Z_out), .ov(OV_out), .n(N_out));

	BR iBR(.condition(condition_IDEX_out), .z(Z_out), .ov(OV_out), .n(N_out), .taken(taken_IDEX_out), .miss(miss));

	Source_MUX iMUX5(.sel(source_sel_IDEX_out), .JL_PC(branch_PC_IDEX_out), .alu(alu_out), .data(data_EXMEM_in));

	EX_MEM iREG3(.clk(clk), .rst(rst), .alu_in(data_EXMEM_in), .alu_out(data_EXMEM_out), .we_in(we_IDEX_out), .we_out(we_EXMEM_out), .dst_addr_in(dst_addr_IDEX_out), .dst_addr_out(dst_addr_EXMEM_out));


	//MEM

	MEM_WB iREG4(.clk(clk), .rst(rst), .data_in(data_EXMEM_out), .data_out(data_MEMWB_out), .we_in(we_EXMEM_out), .we_out(we_MEMWB_out), .dst_addr_in(dst_addr_EXMEM_out), .dst_addr_out(dst_addr_MEMWB_out));
endmodule
