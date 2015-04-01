module ID(input [15:0] instr, output reg we, p1_sel, output reg[3:0] p0_addr, p1_addr, dst_addr, output reg [2:0] Alu_Op, output reg [7:0] Imme, output reg[1:0] Updateflag, output reg jump, output reg[15:0] new_PC, branch_PC, input [15:0] i_addr, output reg[2:0] condition, output reg taken, output reg J_sel, output reg [1:0] source_sel);

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

always @(*) begin
	we = 0;
	p0_addr = instr[7:4];
	p1_addr = instr[3:0];
	dst_addr = instr[11:8];
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

	case (instr[15:12])
		ADD: begin
			we = |dst_addr;
			Updateflag = {|dst_addr,|dst_addr};
		end
		SUB: begin
			we = |dst_addr;
			Alu_Op = 3'h1;
			Updateflag = {|dst_addr,|dst_addr};
		end
		XOR: begin
			Alu_Op = 3'h2;
			we = |dst_addr;
			Updateflag = {|dst_addr,1'b0};
		end
		SHIFT: begin
			we = |dst_addr;
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
			we = |dst_addr;
			p0_addr = instr[11:8];
			Alu_Op = 3'h6;
			p1_sel = 1;
		end
		LHIGH: begin
			we = |dst_addr;
			p0_addr = instr[11:8];
			Alu_Op = 3'h7;
			p1_sel = 1;
		end
		BRANCH: begin
			if (instr[11:9] == 3'h7) begin // unconditional
				jump = 1;
				new_PC = i_addr + {{7{instr[8]}},instr[8:0]};
				branch_PC = 16'hxxxx;
				condition = 3'h7;
				taken = 0;
			end
			else if (instr[8] == 1'b1) begin
				jump = 1;
				new_PC = i_addr + {7'h7f,instr[8:0]};
				branch_PC = i_addr + 1;
				condition = instr[11:9];
				taken = 1;
			end
			else begin
				jump = 0;
				new_PC = 16'hxxxx;
				branch_PC = i_addr + instr[7:0];
				condition = instr[11:9];
				taken = 0;
			end
		end
		JREG: begin
			jump =1;
			J_sel = 1;
			p0_addr = instr[11:8];
		end
		JLINK: begin
			jump = 1;
			new_PC = i_addr + {{4{instr[11]}},instr[11:0]};
			branch_PC = i_addr + 1; // use branch_PC  to store current PC
			we = 1;
			dst_addr = 4'hc;
			Updateflag = 2'b00;
			source_sel = 2'b01;
		end
		default:
			we = 0;
	endcase
end

endmodule
