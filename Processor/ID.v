module ID(input [15:0] instr, output reg we, p1_sel, output reg[3:0] p0_addr, p1_addr, dst_addr, output reg [2:0] Alu_Op, output reg [7:0] Imme, output reg[1:0] Updateflag, output reg jump, output reg[15:0] new_PC, branch_PC, input [15:0] i_addr, output reg[2:0] condition, output reg taken, output reg J_sel, output reg [1:0] source_sel, output reg Mem_re, Mem_we, output reg [1:0] Mode_Set, Mem_sel, input [1:0] Mode, output reg Bad_Instr, output reg send_sel, output reg send, output reg [2:0] spart_addr, output reg wt, output reg [1:0] Accelerator_mode, output reg[4:0] Accelerator_addr, output reg Accelerator_rst);

// Opcode of instruction
localparam ADD = 4'h0;
localparam SUB = 4'h1;
localparam XOR = 4'h2;
localparam LOAD = 4'h3;
localparam STORE = 4'h4;
localparam LHIGH = 4'h5;
localparam LLOW = 4'h6;
localparam SHIFT = 4'h7;
localparam BRANCH = 4'h8;
localparam JLINK = 4'h9;
localparam JREG = 4'ha;
localparam CTRL = 4'hb;
localparam SEND = 4'hc;
localparam SET = 4'hd;
localparam RECV = 4'he;
localparam ADDI = 4'hf;

reg p0_re, p1_re;

always @(*) begin
	we = 0;
	p0_addr = 0;
	p1_addr = 0;
	dst_addr = 0;
	Updateflag = 2'b00;
	Alu_Op = 3'h0;
	Imme = instr[7:0];
	p1_sel = 0;
	jump = 0;
	new_PC =16'hxxxx;
	branch_PC= 16'hxxxx;
	condition = 3'h7;
	taken = 0;
	J_sel = 0;
	source_sel = 2'b00;
	Mem_re = 0;
	Mem_we = 0;
	Mem_sel = 0;
	Mode_Set = 0;
	send_sel = 0;
	send = 0;
	spart_addr = 3'h0;
	Bad_Instr = 0;
	p0_re = 0;
	p1_re = 0;
	wt = 0;
	Accelerator_mode = 0; //do nothing
	Accelerator_addr = 0;
	Accelerator_rst = 0; // not reset
	
	case (instr[15:12])
		ADD: begin
			p0_addr = instr[7:4];
			p1_addr = instr[3:0];
			dst_addr = instr[11:8];
			we = |instr[11:8];
			Updateflag = {2{|instr[11:8]}};
			p0_re = 1;
			p1_re = 1;
		end
		SUB: begin
			p0_addr = instr[7:4];
			p1_addr = instr[3:0];
			dst_addr = instr[11:8];
			we = |instr[11:8];
			Alu_Op = 3'h1;
			Updateflag = {2{|instr[11:8]}};
			p0_re = 1;
			p1_re = 1;
		end
		XOR: begin
			p0_addr = instr[7:4];
			p1_addr = instr[3:0];
			dst_addr = instr[11:8];
			Alu_Op = 3'h2;
			we = |instr[11:8];
			Updateflag = {|instr[11:8],1'b0};
			p0_re = 1;
			p1_re = 1;
		end
		ADDI: begin
			p0_addr = instr[7:4];
			dst_addr = instr[11:8];
			we = |instr[11:8];
			p0_re = 1;
			Alu_Op = instr[3]; // 0 for add, 1 for sub
			if (instr[3] == 1'b1)
				Imme ={4'h0, ~instr[3:0]} + 1;
			else
				Imme = {4'h0, instr[3:0]};
			p1_sel = 1;
		end
		SHIFT: begin
			we = |instr[11:8];
			dst_addr = instr[11:8];
			p0_addr = instr[11:8];
			case (instr[5:4])
				2'h0: Alu_Op = 3'h3; // sll
				2'h1: Alu_Op = 3'h4; // srl
				default: Alu_Op = 3'h5; // sra
			endcase
			Imme = {4'h0,instr[3:0]};
			p1_sel = 1;
		end
		LLOW: begin
			we = |instr[11:8];
			dst_addr = instr[11:8];
			p0_addr = instr[11:8];
			Alu_Op = 3'h6;
			p1_sel = 1;
		end
		LHIGH: begin
			we = |instr[11:8];
			dst_addr = instr[11:8];
			p0_addr = instr[11:8];
			Alu_Op = 3'h7;
			p1_sel = 1;
		end
		BRANCH: begin
			if (instr[11:9] == 3'h7) begin // unconditional
				new_PC = i_addr + {{7{instr[8]}},instr[8:0]};
				branch_PC = 16'hxxxx;
			end
			else if (instr[8] == 1'b1) begin
				new_PC = i_addr + {7'h7f,instr[8:0]};
				branch_PC = i_addr + 1;
			end
			else begin
				new_PC = 16'hxxxx;
				branch_PC = i_addr + instr[7:0];
			end
			jump = &instr[11:9] | instr[8];
			taken = (~&instr[11:9]) & instr[8];
			condition = instr[11:9];
		end
		JREG: begin
			jump =1;
			J_sel = 1;
			p0_addr = instr[11:8];
			if (Mode[1] == 1) 
				Mode_Set = instr[1:0];
			else
				Mode_Set = 2'b00;
			p0_re = 1;
		end
		JLINK: begin
			jump = 1;
			new_PC = i_addr + {{4{instr[11]}},instr[11:0]};
			branch_PC = i_addr + 1; // use branch_PC  to store current PC
			we = 1;
			dst_addr = 4'hc;
			source_sel = 2'b01;
		end
		LOAD: begin
			p0_addr = instr[7:4];
			dst_addr = instr[11:8];
			Mem_re = 1;
			Mem_sel = 1;
			we = |instr[11:8];
			p0_re = 1;
		end
		STORE: begin
			Mem_we = 1;
			we = 0;
			p0_addr = instr[7:4];
			p1_addr = instr[11:8];
			p0_re = 1;
			p1_re = 1;
			wt = instr[0];
		end
		SEND: begin
			Imme = instr[11:4];
			p1_addr = instr[11:8];
			p1_sel = instr[1];
			send_sel = instr[0];
			send = 1;
			p1_re = ~instr[1];
		end
		RECV: begin
			dst_addr = instr[11:8];
			we = |instr[11:8];
			case (instr[7])
				1'b0: begin
					source_sel = 2'b10;
					spart_addr = instr[2:0];
				end
				default: begin
					source_sel = 2'b00;
					spart_addr = 3'h0;
				end
			endcase
		end
		SET: begin
			Mode_Set = instr[11:10];
		end
		CTRL: begin
			Accelerator_mode = (&instr[7:6]&instr[4:0])? 0 : instr[7:6];
			Accelerator_addr = instr[4:0];
			Accelerator_rst = &instr[7:6]&instr[4:0]; // stop and addr = 11111 reset accelerator
			p0_addr = instr[11:8];
			dst_addr = instr[11:8];
			we = (instr[7:6] ==2'b10)? 1 : 0; // read
			p0_re = (instr[7:6]==2'b01 && instr[4] != 1)? 1 : 0;
			Mem_sel = 0;
			source_sel = 2'b11;
		end
		default:
			we = 0;
	endcase

	if (Mode == 2'b01 && ((p0_re && p0_addr > 4'hc) || (p1_re && p1_addr > 4'hc) || (we && dst_addr >4'hc) || (instr[15:12] == RECV && instr[7] == 1'b0)))
		Bad_Instr = 1;
	else
		Bad_Instr = 0;
end
endmodule
