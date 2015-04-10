// Not include cache
module Processor(clk, rst, i_hit, instr, i_addr, d_hit, d_addr, Mem_re, Mem_we, wrt_data, rd_data, send, send_data, full, Spart_RCV, spart_addr, spart_data);

	input clk, rst, i_hit, d_hit, full, Spart_RCV;
	input [15:0] instr, rd_data, spart_data;
	output [15:0] i_addr, d_addr, wrt_data;
	output Mem_re, Mem_we, send;
	output [7:0] send_data;
	output [2:0] spart_addr;
	

	wire jump, PC_stall, IFID_stall, IDEX_stall, EXMEM_stall, MEMWB_stall, IDEX_flush, J, we_IDEX_in, we_IDEX_out, p1_sel, p0_ID_bypass, p1_ID_bypass, we_MEMWB_out, taken_IDEX_in, taken_IDEX_out, J_sel, Mem_re_IDEX_in, Mem_re_IDEX_out, Mem_we_IDEX_in, Mem_we_IDEX_out, Mem_sel_IDEX_in, Mem_sel_IDEX_out, Z_in, Z_out, OV_in, OV_out, N_in, N_out, p0_EX_bypass, p1_EX_bypass, we_EXMEM_out, Mem_sel_EXMEM_out, Bad_Instr, Store_Current, jump_out, miss_out, Illegal_PC, Illegal_Memory, send_sel_IDEX_in, send_sel_IDEX_out, send_IDEX_in;
	wire [15:0] J_R, instr_ID, instr_IFID_out, PC_out,instr_out, p0_IDEX_in, p0_IDEX_out, p0, p0_bypass_in, p1, p1_bypass_in, p1_bypass_out, p1_IDEX_in, p1_IDEX_out, alu_out, data_EXMEM_in, data_EXMEM_out, p0_EXMEM_in, p1_EXMEM_in, data_MEMWB_out, J_PC, J_PC_out, branch_PC_IDEX_in, branch_PC_IDEX_out, data_MEMWB_in;
	wire [3:0] p0_addr, p1_addr, dst_addr_IDEX_in, dst_addr_IDEX_out, dst_addr_MEMWB_out, p0_addr_IDEX_out, p1_addr_IDEX_out, dst_addr_EXMEM_out;
	wire [2:0] Alu_Op_IDEX_in, Alu_Op_IDEX_out, condition_IDEX_in, condition_IDEX_out, spart_addr_IDEX_in;
	wire [7:0] Imme;
	wire [1:0] Updateflag_IDEX_in, Updateflag_IDEX_out, source_sel_IDEX_in, source_sel_IDEX_out, Mode_Set, Mode, Mode_IDEX_out;

	// IF
	PC iPC(.clk(clk), .rst(rst), .i_hit(i_hit), .jump(J), .stall(PC_stall), .Mode(|Mode), .J_R(J_R), .PC(i_addr));
	Instr_MUX iMUX1(.i_hit(i_hit), .jump(J), .Mode(|Mode), .instr_i(instr), .instr_o(instr_out));

	IF_ID iREG1(.clk(clk), .rst(rst), .stall(IFID_stall), .instr_in(instr_out), .instr_out(instr_IFID_out), .PC_in(i_addr), .PC_out(PC_out));

	// ID
	

	Flush_MUX iMUX3(.miss(miss|~|Mode|Store_Current), .instr_in(instr_IFID_out), .instr_out(instr_ID));
	ID iID(.instr(instr_ID), .we(we_IDEX_in), .p0_addr(p0_addr), .p1_addr(p1_addr), .dst_addr(dst_addr_IDEX_in),.Alu_Op(Alu_Op_IDEX_in), .Imme(Imme), .Updateflag(Updateflag_IDEX_in), .p1_sel(p1_sel), .jump(jump), .new_PC(J_PC), .branch_PC(branch_PC_IDEX_in), .i_addr(PC_out), .condition(condition_IDEX_in), .taken(taken_IDEX_in), .J_sel(J_sel), .source_sel(source_sel_IDEX_in), .Mem_re(Mem_re_IDEX_in), .Mem_we(Mem_we_IDEX_in), .Mem_sel(Mem_sel_IDEX_in), .Mode_Set(Mode_Set), .Mode(Mode), .Bad_Instr(Bad_Instr), .Store_Current(Store_Current), .send_sel(send_sel_IDEX_in), .send(send_IDEX_in), .spart_addr(spart_addr_IDEX_in));

	RF iRF(.clk(clk), .rst(rst), .we(we_MEMWB_out), .p0_addr(p0_addr), .p1_addr(p1_addr), .dst_addr(dst_addr_MEMWB_out), .dst(data_MEMWB_out), .p0(p0), .p1(p1));

	Bypass_MUX ip0IDBY(.sel(p0_ID_bypass), .in(p0), .bypass(p0_bypass_in), .out(p0_IDEX_in));
	Bypass_MUX ip1IDBY(.sel(p1_ID_bypass), .in(p1), .bypass(p1_bypass_in), .out(p1_bypass_out));
	

	P1_MUX iMUX2(.sel(p1_sel), .imme(Imme), .p1(p1_bypass_out), .data(p1_IDEX_in));

	JR_MUX iMUX4(.sel(J_sel), .imme(J_PC), .Reg(p0_IDEX_in), .J_R(J_PC_out));

	Memory_Check iMC(.Mode(Mode[1]), .jump(jump), .miss(miss), .new_PC(J_PC_out), .branch_PC(branch_PC_IDEX_out), .memre(Mem_re_IDEX_in), .memwe(Mem_we_IDEX_in), .p0(p0_IDEX_in), .jump_out(jump_out), .miss_out(miss_out), .Illegal_PC(Illegal_PC), .Illegal_Memory(Illegal_Memory));

	Monitor iMON(.clk(clk), .rst(rst), .miss(miss), .jump(jump), .new_PC(J_PC_out), .branch_PC(branch_PC_IDEX_out), .Mode_Set(Mode_Set), .J_R(J_R), .J(J), .Mode(Mode), .Bad_Instr_in(Bad_Instr), .Illegal_PC_in(Illegal_PC), .Illegal_Memory_in(Illegal_Memory), .Spart_RCV_in(Spart_RCV), .Store_Current(Store_Current));

	ID_EX iREG2(.clk(clk), .rst(rst), .stall(IDEX_stall), .flush(IDEX_flush|Bad_Instr|Illegal_PC|Illegal_Memory), .full(full), .Alu_Op_in(Alu_Op_IDEX_in), .Alu_Op_out(Alu_Op_IDEX_out), .we_in(we_IDEX_in), .we_out(we_IDEX_out), .dst_addr_in(dst_addr_IDEX_in), .dst_addr_out(dst_addr_IDEX_out), .Updateflag_in(Updateflag_IDEX_in), .Updateflag_out(Updateflag_IDEX_out), .p0_in(p0_IDEX_in), .p0_out(p0_IDEX_out), .p1_in(p1_IDEX_in), .p1_out(p1_IDEX_out), .condition_in(condition_IDEX_in), .condition_out(condition_IDEX_out), .taken_in(taken_IDEX_in), .taken_out(taken_IDEX_out), .branch_PC_in(branch_PC_IDEX_in), .branch_PC_out(branch_PC_IDEX_out), .source_sel_in(source_sel_IDEX_in), .source_sel_out(source_sel_IDEX_out), .Mem_re_in(Mem_re_IDEX_in), .Mem_re_out(Mem_re_IDEX_out), .Mem_we_in(Mem_we_IDEX_in), .Mem_we_out(Mem_we_IDEX_out), .Mem_sel_in(Mem_sel_IDEX_in), .Mem_sel_out(Mem_sel_IDEX_out), .p0_addr_in(p0_addr), .p0_addr_out(p0_addr_IDEX_out), .p1_addr_in(p1_addr), .p1_addr_out(p1_addr_IDEX_out), .Mode_in(Mode), .Mode_out(Mode_IDEX_out), .send_sel_in(send_sel_IDEX_in), .send_sel_out(send_sel_IDEX_out), .send_in(send_IDEX_in), .send_out(send), .spart_addr_in(spart_addr_IDEX_in), .spart_addr_out(spart_addr));

	// EX

	alu iALU(.src0(p0_IDEX_out), .src1(p1_IDEX_out), .opcode(Alu_Op_IDEX_out), .dst(alu_out), .zr(Z_in), .ov(OV_in), .n(N_in));
	Flags iFLAG(.clk(clk), .rst(rst), .Z(Z_in), .OV(OV_in), .N(N_in), .Mode(Mode_IDEX_out), .Update(Updateflag_IDEX_out), .z_out(Z_out), .ov_out(OV_out), .n_out(N_out));

	BR iBR(.condition(condition_IDEX_out), .z(Z_out), .ov(OV_out), .n(N_out), .taken(taken_IDEX_out), .miss(miss));

	Source_MUX iMUX5(.sel(source_sel_IDEX_out), .JL_PC(branch_PC_IDEX_out), .alu(alu_out), .spart(spart_data), .data(data_EXMEM_in));

	// SPART send data
	SPART_MUX iSPART(.sel(send_sel_IDEX_out), .p1(p1_IDEX_out), .out(send_data));
	
	// Mem to EX bypass
	Bypass_MUX ip0EX(.sel(p0_EX_bypass), .in(p0_IDEX_out), .bypass(data_MEMWB_in), .out(p0_EXMEM_in));
	Bypass_MUX ip1EX(.sel(p1_EX_bypass), .in(p1_IDEX_out), .bypass(data_MEMWB_in), .out(p1_EXMEM_in));
	
	EX_MEM iREG3(.clk(clk), .rst(rst), .stall(EXMEM_stall), .alu_in(data_EXMEM_in), .alu_out(data_EXMEM_out), .we_in(we_IDEX_out), .we_out(we_EXMEM_out), .dst_addr_in(dst_addr_IDEX_out), .dst_addr_out(dst_addr_EXMEM_out), .Mem_re_in(Mem_re_IDEX_out), .Mem_re_out(Mem_re), .Mem_we_in(Mem_we_IDEX_out), .Mem_we_out(Mem_we), .Mem_sel_in(Mem_sel_IDEX_out), .Mem_sel_out(Mem_sel_EXMEM_out), .d_addr_in(p0_EXMEM_in), .d_addr_out(d_addr), .wrt_data_in(p1_EXMEM_in), .wrt_data_out(wrt_data));

	//MEM
	Memory_MUX iMUX6(.sel(Mem_sel_EXMEM_out), .alu(data_EXMEM_out), .mem(rd_data), .data(data_MEMWB_in));

	MEM_WB iREG4(.clk(clk), .rst(rst), .stall(MEMWB_stall), .data_in(data_MEMWB_in), .data_out(data_MEMWB_out), .we_in(we_EXMEM_out), .we_out(we_MEMWB_out), .dst_addr_in(dst_addr_EXMEM_out), .dst_addr_out(dst_addr_MEMWB_out));


	// Stall Controller
	Stall_Ctrl iSTL(.d_hit(d_hit), .Mem_op(Mem_re|Mem_we), .PC_stall(PC_stall), .IFID_stall(IFID_stall), .IDEX_stall(IDEX_stall), .EXMEM_stall(EXMEM_stall), .MEMWB_stall(MEMWB_stall), .IDEX_flush(IDEX_flush), .Mem_re_EX(Mem_re_IDEX_out), .Mem_we_ID(Mem_we_IDEX_in), .dst_addr(dst_addr_IDEX_out), .p0_addr(p0_addr), .p1_addr(p1_addr), .send(send), .full(full));

	// Bypass
	Bypass iBY(.p0_addr_ID(p0_addr), .p1_addr_ID(p1_addr), .dst_addr_EX(dst_addr_IDEX_out), .dst_addr_MEM(dst_addr_EXMEM_out), .p0_addr_EX(p0_addr_IDEX_out), .p1_addr_EX(p1_addr_IDEX_out), .we_ex(we_IDEX_out), .we_mem(we_EXMEM_out), .dst_ex(data_EXMEM_in), .dst_mem(data_MEMWB_in), .p0_ID_bypass(p0_ID_bypass), .p1_ID_bypass(p1_ID_bypass), .p0_bypass_in(p0_bypass_in), .p1_bypass_in(p1_bypass_in), .p0_EX_bypass(p0_EX_bypass), .p1_EX_bypass(p1_EX_bypass));
endmodule
