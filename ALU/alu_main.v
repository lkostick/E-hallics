`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:07:31 03/24/2015 
// Design Name: 
// Module Name:    alu_main 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module alu_main(P1, P2, Opcode, Result, Z, OV, N);

	localparam Opcodeadd = 3'b000;
	localparam Opcodesub = 3'b001;
	localparam Opcodexor = 3'b010;
	localparam Opcodesll = 3'b011;	
	localparam Opcodesrl = 3'b100;	
	localparam Opcodesra = 3'b101;
	localparam Opcodell  = 3'b110;
	localparam Opcodelh	= 3'b111;
	
	
	input[15:0] P1,P2;
	input[2:0] Opcode;
	
	output reg OV;
	output Z, N;
	output reg[15:0] Result;
	
	wire pV;
	
	wire[15:0]  ALUresarith, ALUresshift;
	
	//Addition and subtraction 
	arithmetic a1(.P1(P1), .P2(P2), .select(Opcode[0]), .out(ALUresarith), .pV(pV));		
	
	//Shift operations
	shifter shft(.in(P1), .shamt(P2[3:0]), .select(Opcode[1:0]), .out(ALUresshift));
	
	assign Z = (Result == 0) ? 1:0;
	assign N = (Result[15] == 1'b1) ? 1:0;
	
	always@(*)	begin
		
		case(Opcode)
			Opcodeadd:	begin		//addition
			
								Result = ALUresarith;
								if(pV == 1'b1)	begin		//if overflow found, set the overflow flag to 1
									OV = 1'b1;
								end 
								else	begin			//if overflow does not exist, set Result and set the overflow flag to 0
									OV = 1'b0;
								end																		
							end		
			
			Opcodesub:	begin		//subtraction
				
								Result = ALUresarith;
								if(pV == 1'b1)	begin		//if overflow found, set the overflow flag to 1
									OV = 1'b1;
								end 
								else	begin			//if overflow does not exist, set Result and set the overflow flag to 0
									OV = 1'b0;
								end
							end
		
			Opcodexor:	begin	//bitwise xor operation
								Result = P1 ^ P2;
							end		
							
			Opcodell:	begin	//Load low
								Result = {8'h00, P2[7:0]};
							end
			Opcodelh:	begin	//Load high
								Result = {P2[7:0], P1[7:0]};
							end
		
			default: begin
							Result = ALUresshift;
						end
		endcase
	end
	
endmodule
	
		
