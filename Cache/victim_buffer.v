`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:45:30 04/07/2015 
// Design Name: 
// Module Name:    victim_buffer 
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
module victim_buffer(clk, rst, we, re, addrIn_i, addrIn_d,  
					 victimWrt_data, writeLineInd, victimRd_data, 
					 hit_ind, hit, victimIndex, emptySlots, roll, victimEv_data, ihit);	
	input clk, rst, we, re; // ovWrt is the swap flag
	input [13:0] addrIn_i, addrIn_d;
	input [79:0] victimWrt_data;
	input [1:0] writeLineInd;
	input roll, ihit;
	output [79:0] victimRd_data; // {valid,dirty,addr[13:0],wdata[63:0]}
	output [1:0] hit_ind;
	output hit;
	output [1:0] victimIndex;
	output [3:0] emptySlots;
	output [79:0] victimEv_data;

	reg [79:0] mem[0:3];
	reg [2:0] setInd;
	reg [1:0] evict_cntr;
	always @ (posedge clk) begin
		if(rst) begin
			evict_cntr <= 0;
		end
		else if(roll) begin
			evict_cntr <= evict_cntr + 1;
		end
	end
	assign victimIndex = evict_cntr;

	assign emptySlots = {mem[0][79],mem[1][79],mem[2][79],mem[3][79]};
	always @ (posedge clk/*, posedge rst*/) begin
		if(rst) begin
			for(setInd = 0; setInd < 4; setInd = setInd + 1) begin
				mem[setInd] = {2'b00, 14'b0000, {64{1'bx}}};
			end
			//$readmemh("vbuff_init.hex",mem);
		end
		if(we) begin
				mem[writeLineInd] = victimWrt_data;
		end
	end
	
	initial begin
		evict_cntr = 0;
		for(setInd = 0; setInd < 4; setInd = setInd + 1) begin
			mem[setInd] = 0;
		end
	end
/*
	always @ (addrIn) begin
		victimRd_data = mem[evict_cntr];
		hit = 0;
		hit_ind = 2'bx;
		if(mem[0][77:64] == addrIn) begin
			victimRd_data = mem[0];
			hit = 1;
			hit_ind = 0;
		end
		if(mem[1][77:64] == addrIn) begin
			victimRd_data = mem[1];
			hit = 1;
			hit_ind = 1;
		end
		if(mem[2][77:64] == addrIn) begin
			victimRd_data = mem[2];
			hit = 1;
			hit_ind = 2;
		end
		if(mem[3][77:64] == addrIn) begin
			victimRd_data = mem[3];
			hit = 1;
			hit_ind = 3;
		end
	end		
*/		

	wand [79:0] rd_data_i;
	wire [79:0] rd_0 = (mem[0][77:64] == addrIn_i) ? mem[0] : 80'bz;
	wire [79:0] rd_1 = (mem[1][77:64] == addrIn_i) ? mem[1] : 80'bz;
	wire [79:0] rd_2 = (mem[2][77:64] == addrIn_i) ? mem[2] : 80'bz;
	wire [79:0] rd_3 = (mem[3][77:64] == addrIn_i) ? mem[3] : 80'bz;
	assign rd_data_i = rd_0;
	assign rd_data_i = rd_1;
	assign rd_data_i = rd_2;
	assign rd_data_i = rd_3;
	//assign victimRd_data = rd_data;
	
	wand [79:0] rd_data_d;
	wire [79:0] rd_00 = (mem[0][77:64] == addrIn_d) ? mem[0] : 80'bz;
	wire [79:0] rd_11 = (mem[1][77:64] == addrIn_d) ? mem[1] : 80'bz;
	wire [79:0] rd_22 = (mem[2][77:64] == addrIn_d) ? mem[2] : 80'bz;
	wire [79:0] rd_33 = (mem[3][77:64] == addrIn_d) ? mem[3] : 80'bz;
	assign rd_data_d = rd_00;
	assign rd_data_d = rd_11;
	assign rd_data_d = rd_22;
	assign rd_data_d = rd_33;
	assign victimRd_data = ihit ? rd_data_i : rd_data_d;
	//assign victimRd_data = mem[0][77:64];
	
	wand [79:0] evict_data;
	wire [79:0] rd_4 = (evict_cntr == 0) ? mem[0] : 80'bz;
	wire [79:0] rd_5 = (evict_cntr == 1) ? mem[1] : 80'bz;
	wire [79:0] rd_6 = (evict_cntr == 2) ? mem[2] : 80'bz;
	wire [79:0] rd_7 = (evict_cntr == 3) ? mem[3] : 80'bz;
	assign evict_data = rd_4;
	assign evict_data = rd_5;
	assign evict_data = rd_6;
	assign evict_data = rd_7;
	assign victimEv_data = evict_data;
	/*		
			assign victimRd_data = (mem[0][77:64] == addrIn) ?  mem[0] :
							(mem[1][77:64] == addrIn) ?  mem[1] :
							(mem[2][77:64] == addrIn) ?  mem[2] :
							(mem[3][77:64] == addrIn) ?  mem[3] : 
														 mem[evict_cntr];
	*/
			wire hit_i = (
					mem[0][77:64] == addrIn_i || 
				   mem[1][77:64] == addrIn_i || 
				   mem[2][77:64] == addrIn_i || 
				   mem[3][77:64] == addrIn_i) ? 1 : 0;
			wire hit_d = (
					mem[0][77:64] == addrIn_d || 
				   mem[1][77:64] == addrIn_d || 
				   mem[2][77:64] == addrIn_d || 
				   mem[3][77:64] == addrIn_d) ? 1 : 0;
					
			assign hit = ihit? hit_i : hit_d;
			
			assign hit_ind_i = 
					  (mem[0][77:64] == addrIn_i) ? 0 : 
					  (mem[1][77:64] == addrIn_i) ? 1 :
					  (mem[2][77:64] == addrIn_i) ? 2 :
					  (mem[3][77:64] == addrIn_i) ? 3 : 2'bx;
			assign hit_ind_d = 
					  (mem[0][77:64] == addrIn_d) ? 0 : 
					  (mem[1][77:64] == addrIn_d) ? 1 :
					  (mem[2][77:64] == addrIn_d) ? 2 :
					  (mem[3][77:64] == addrIn_d) ? 3 : 2'bx;
			assign hit_ind = ihit ? hit_ind_i : hit_ind_d;
				
endmodule
