`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:42:58 04/07/2015 
// Design Name: 
// Module Name:    cache 
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
/* cache controller */
module cache(clk, rst, i_addr_pre, i_addr, instr, i_hit, d_data, d_hit, d_addr_pre, d_addr, we, re, wrt_data, wt);

	output [15:0] instr, d_data;
	output i_hit, d_hit;
	input [15:0] i_addr_pre, d_addr, wrt_data, i_addr, d_addr_pre;
	input rst, clk, re, we, wt;

	wire [74:0] d_rd_line0, d_rd_line1;
	wire lru_in;
	wire [73:0] i_rd_data;
	wire [79:0] v_rd_data, victimEv_data;
	wire [63:0] m_rd_data;
	wire [3:0] emptySlots;
	wire [1:0] v_hit_line;
	wire [1:0] evict_index;
	wire v_hit, v_hit_i, v_hit_d;//, m_rdy;

	reg setOffset, d_we, d_re, lru_out, i_we, i_re, v_we, v_re, m_re, m_we;
	reg [13:0] m_addr;
	reg [79:0] v_wr_data;
	reg [74:0] dcache_wr_data;
	reg [73:0] icache_wr_data;
	reg [63:0] m_wr_data;
	//reg [31:0] lru_mem;
	//reg [13:0] v_addr;
	reg [1:0] writeLineInd;
	reg lru_we;
	reg freez;
	reg roll;
	reg wt_sel;
	reg d_we_lru;
	//integer probe;

	assign i_hit = ~freez;
	assign d_hit = ~freez;
	wire we0 = (setOffset == 0 && d_we == 1) ? 1 : 0;
	wire we1 = (setOffset == 1 && d_we == 1) ? 1 : 0;
	
	wire [5:0] i_wr_addr_sel = (i_we==1 && wt_sel == 0) ? i_addr[7:2] : 
										wt_sel ? d_addr[7:2] : i_addr_pre[7:2];
	wire [5:0] i_check = i_addr_pre[7:2];
	wire [4:0] d_wr_addr_sel = d_we? d_addr[6:2] : d_addr_pre[6:2];
	wire i_hitIn;
	/* initialize subcomponents */

	//dcache d_cache(clk, rst, d_addr[15:2], setOffset, dcache_wr_data, d_we, d_re, lru_out, lru_we,
	              /* output */
	             //d_rd_line1, d_rd_line0, lru_in);
	dcache_s0 dset0 (
							.clka(clk), // input clka
							.wea(we0), // input [0 : 0] wea
							.addra(d_wr_addr_sel), // input [4 : 0] addra
							.dina(dcache_wr_data), // input [74 : 0] dina
							.douta(d_rd_line0) // output [74 : 0] douta
							);
	dcache_s0 dset1 (
							.clka(clk), // input clka
							.wea(we1), // input [0 : 0] wea
							.addra(d_wr_addr_sel), // input [4 : 0] addra
							.dina(dcache_wr_data), // input [74 : 0] dina
							.douta(d_rd_line1) // output [74 : 0] douta
							);
	lru d_lru_set (
						  .clka(clk), // input clka
						  .wea(lru_we), // input [0 : 0] wea
						  .addra(d_wr_addr_sel), // input [4 : 0] addra
						  .dina(lru_out), // input [0 : 0] dina
						  .douta(lru_in) // output [0 : 0] douta
						);
						
	icache icache_dt (
						  .clka(clk), // input clka
						  .wea(i_we), // input [0 : 0] wea
						  .addra(i_wr_addr_sel), // input [5 : 0] addra
						  .dina(icache_wr_data), // input [73 : 0] dina
						  .douta(i_rd_data) // output [73 : 0] douta
						);
	
	//icache i_cache(clk, rst, i_addr[15:2], icache_wr_data, i_we, i_re, i_rd_data);

	victim_buffer v_buffer(clk, rst, v_we, v_re, i_addr[15:2], d_addr[15:2], 
						 v_wr_data, writeLineInd, v_rd_data, 
						 v_hit_line, v_hit_i, v_hit_d, evict_index, emptySlots, roll, victimEv_data, ~i_hitIn);

	//unified_mem u_mem(clk,rst,m_addr,m_re,m_we,m_wr_data,m_rd_data,m_rdy);	
	main_mem u_mem(clk, m_we, m_addr, m_wr_data, m_rd_data);

	// memory delay simulation!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	reg [1:0] mem_cntr;
	reg mem_state, mem_nxtState;
	reg mem_cntr_en;
	localparam waitc = 1'b0;
	localparam count = 1'b1;
	wire m_rdy = (mem_state == waitc) ? 1 : 0;
	
	always @ (posedge clk/*, posedge rst*/) begin
		if(rst) begin
			mem_cntr <= 0;
		end
		else if(mem_cntr_en) begin
			mem_cntr <= mem_cntr+1;
		end
	end
	always @ (posedge clk/*, posedge rst*/) begin
		if(rst) begin
			mem_state <= 0;
		end
		else begin
			mem_state <= mem_nxtState;
		end
	end
	always @ (*) begin
		mem_cntr_en = 0;
		mem_nxtState = waitc;
		
		case(mem_state)
			waitc: begin
				if(m_re | m_we) begin
					mem_nxtState = count;
					mem_cntr_en = 1;
				end
			end
			count: begin
				if(mem_cntr == 0) begin
					mem_nxtState = waitc;
				end
				else begin
					mem_nxtState = count;
					mem_cntr_en = 1;
				end
			end
		endcase
	end
	

	// state defn
	localparam
	 	normal=4'b0000,
		dfetch=4'b0001,
		ifetch=4'b0010,
		ievict=4'b0011,
		devict=4'b0100,
		hDetect=4'b0101,
		write_through=4'b0110,
		hdevict = 4'b0111,
		mem_write = 4'b1000,
		spin = 4'b1001;
	reg [3:0] state, nextState;
	reg [3:0] emptySlots_reg;
	always @(posedge clk/*, posedge rst*/) begin
		if(rst) begin
			emptySlots_reg <= 0;
		end
		else begin
			emptySlots_reg<=emptySlots;
		end
	end
	// state ff reset and state transition
	always @(posedge clk/*, posedge rst*/) begin
		if(rst) begin
			//$display("reset @%d",$time);
			state <= 0;
		end
		else begin
		//$display("change @%d",$time);
			state<=nextState;
		end
	end

	//reg d_update;
	wire [7:0] i_tag = i_rd_data[71:64];
	wire [7:0] i_dst_tag = i_addr[15:8];
	wire [8:0] d_tag0 = d_rd_line0[72:64];
	wire [8:0] d_tag1 = d_rd_line1[72:64];
	wire [8:0] d_dst_tag = d_addr[15:7];
	wire d_dirty0 = d_rd_line0[73];
	wire d_dirty1 = d_rd_line1[73];
	wire d_valid0 = d_rd_line0[74];
	wire d_valid1 = d_rd_line1[74];
	wire i_valid = i_rd_data[73];
	wire v_valid = v_rd_data[79];
	wire v_dirty = v_rd_data[78];
	//wire [13:0] v_tag = v_rd_data[77:64];

	assign i_hitIn = (i_valid==1 && i_tag==i_dst_tag) ? 1 : 0;
	wire d_hitIn = ((d_valid0==1 && d_tag0==d_dst_tag) || (d_valid1==1 && d_tag1==d_dst_tag)) ? 1 : 0;
	wire d_hit_ind = (d_valid0==1 && d_tag0==d_dst_tag) ? 0 : 1;
	wire v_hitIn = /*(v_valid == 1 && */(v_hit == 1) ? 1 : 0;


	/* select word */
	reg i_output_sel, i_output_sel2;
	//wire [63:0] i_cacheLine = i_output_sel ? v_rd_data : 
		//							  i_output_sel2 ? m_rd_data: i_rd_data;
	wire [63:0] i_cacheLine = i_output_sel ? v_rd_data : i_rd_data;
	wire [1:0] i_mux = i_addr[1:0];
	assign instr = (i_mux == 2'b11) ? i_cacheLine[63:48] :
					   (i_mux == 2'b10) ? i_cacheLine[47:32] :
					   (i_mux == 2'b01) ? i_cacheLine[31:16] :
					   i_cacheLine[15:0];

	reg d_output_sel;
	wire [63:0] d_selected_line = (d_hit_ind == 0) ? d_rd_line0 : d_rd_line1;
	wire [63:0] d_cacheLine = (d_output_sel == 1) ? v_rd_data : d_selected_line;
	wire [1:0] d_mux = d_addr[1:0];
	assign d_data = (d_mux == 2'b11) ? d_cacheLine[63:48] :
					   (d_mux == 2'b10) ? d_cacheLine[47:32] :
					   (d_mux == 2'b01) ? d_cacheLine[31:16] :
					   d_cacheLine[15:0];

	/* make dcache write data */
	reg w_output_sel;
	wire [63:0] writeLine = w_output_sel ? v_rd_data : d_selected_line;
	//wire [1:0] d_mux = d_addr[1:0];
	wire [15:0] d_wrt_word0 = (d_mux == 2'b11) ? wrt_data : writeLine[63:48];
	wire [15:0] d_wrt_word1 = (d_mux == 2'b10) ? wrt_data : writeLine[47:32];
	wire [15:0] d_wrt_word2 = (d_mux == 2'b01) ? wrt_data : writeLine[31:16];
	wire [15:0] d_wrt_word3 = (d_mux == 2'b00) ? wrt_data : writeLine[15:0];
	wire [63:0] replacement = {d_wrt_word0, d_wrt_word1, d_wrt_word2, d_wrt_word3};
	
	initial begin
		mem_cntr = 0;
		mem_state = 0;
		emptySlots_reg = 0;
		state = 0;
	end

	/* start of FSM */
	always @(*) begin
		i_re = 1;
		// v_re default to be active
		v_re = 1;
		setOffset = 1'bx;
		d_we = 0;
		d_re = 0;
		lru_out = 1'bx;
		lru_we = 0;
		i_we = 0;
		v_we = 0;
		m_re = 0;
		m_we = 0;
		m_addr = i_addr[15:2];
		v_wr_data = 80'bx;
		dcache_wr_data = 75'bx;
		//dcache_wr_data = 75'b0;
		icache_wr_data = 74'bx;
		m_wr_data = 64'bx;
		//v_addr = i_addr[15:2];
		writeLineInd = 2'bx;
		freez = 0;
		i_output_sel = 0;
		d_output_sel = 0;
		w_output_sel = 0;
		roll = 1;
		nextState = normal;
		//probe = 0;
		i_output_sel2 = 0;
		wt_sel = 0;
		d_we_lru = 0;

		case(state)
			normal: begin
				/* handle the case that there is no data re/we 
				if(we == 1) begin
					d_we_lru = 1;
				end*/
				if(i_hitIn == 0 && wt == 0) begin
					if(v_hit_i == 0) begin
						freez = 1;
						if(i_valid == 0) begin
							//m_addr = i_addr[15:2];
							m_re = 1;
							nextState = ifetch;
							//probe = 1;
						end
						else begin
							nextState = ievict;
							roll = 0;
							m_addr = victimEv_data[77:64];
							m_wr_data = victimEv_data[63:0];
							//probe = 2;
							if(v_dirty == 1) begin
								m_we = 1;
								//m_wr_data = victimEv_data[63:0];
								//m_addr = victimEv_data[77:64];
								//probe = 3;
							end
						end
					end
					else begin
						i_output_sel = 1;
						v_wr_data = {i_rd_data[73:72], i_rd_data[71:64], i_addr[7:2], i_rd_data[63:0]};					
						writeLineInd = v_hit_line;
						v_we = 1;
						i_we = 1;
						icache_wr_data = {v_rd_data[79:78], v_rd_data[77:70], v_rd_data[63:0]};
						nextState = spin;
						//probe = 4;
					end
				end
				else if(re == 1 && wt == 0) begin
					d_re = 1;
					//v_addr = d_addr[15:2];
					if(d_hitIn == 1) begin
						nextState = normal;
						lru_we = 1;
						lru_out = d_hit_ind; // might be redundant
						//probe = 5;
					end
					else begin						
						lru_we = 1;
						lru_out = (d_valid0 == 0) ? 0 :
								  (d_valid1 == 0) ? 1 :
								  ~lru_in;
								  //probe = 6;
						dcache_wr_data = {v_rd_data[79:78], v_rd_data[77:69], v_rd_data[63:0]};
						if(v_hit_d == 0) begin
							freez = 1;
							//probe = 7;
							if((d_valid0 == 0) || (d_valid1 == 0)) begin
								nextState = dfetch;
								m_addr = d_addr[15:2];
								m_re = 1;
								//probe = 8;
							end
							else begin
								nextState = devict;
								roll = 0;
								m_wr_data = victimEv_data[63:0];
								m_addr = victimEv_data[77:64];
								//probe = 9;
								if(v_dirty == 1) begin
									m_we = 1;
									//m_wr_data = victimEv_data[63:0];
									//m_addr = victimEv_data[77:64];
									//probe = 10;
								end
							end
						end
						else begin
							//probe = 11;
							d_output_sel = 1;
							if(~lru_in == 0) begin
								v_wr_data = {d_rd_line0[74:73], d_rd_line0[72:64], d_addr[6:2], d_rd_line0[63:0]};
							end
							else begin
								v_wr_data = {d_rd_line1[74:73], d_rd_line1[72:64], d_addr[6:2], d_rd_line1[63:0]};
							end
							v_we = 1;
							writeLineInd = v_hit_line;
							setOffset = ~lru_in;
							d_we = 1;
							//dcache_wr_data = {v_rd_data[79:78], v_rd_data[77:69], v_rd_data[63:0]};
							nextState = spin;
						end
					end
				end
				// write case;
				else if (we == 1 && wt == 0) begin
					d_re = 1;
					//v_addr = d_addr[15:2];
					if(d_hitIn == 1) begin
						lru_we = 1;
						lru_out = d_hit_ind;
						d_we = 1;
						dcache_wr_data = (d_hit_ind == 0) ? {2'b11, d_rd_line0[72:64], replacement} :
															{d_rd_line1[74], 1'b1, d_rd_line1[72:64], replacement}; // mark dirty
						setOffset = d_hit_ind;
						nextState = spin;
						//probe = 12;
					end
					else begin	
						dcache_wr_data = {v_rd_data[79], 1'b1, v_rd_data[77:69], replacement};
						lru_we = 1;
						lru_out = (d_valid0 == 0) ? 0 :
								  (d_valid1 == 0) ? 1 :
								  ~lru_in;
						//probe = 13;
						if(v_hit_d == 0) begin
							freez = 1;
							if((d_valid0 == 0) || (d_valid1 == 0)) begin
								nextState = dfetch;
								m_addr = d_addr[15:2];
								m_re = 1;
								//probe = 14;
							end
							else begin
								nextState = devict;
								roll = 0;
								m_wr_data = victimEv_data[63:0];
								m_addr = victimEv_data[77:64];
								//probe = 15;
								if(v_dirty == 1) begin
									m_we = 1;
									//m_wr_data = victimEv_data[63:0];
									//m_addr = victimEv_data[77:64];
									//probe = 16;
								end
							end
						end
						else begin
							//probe = 17;
							w_output_sel = 1;
							if(~lru_in == 0) begin
								v_wr_data = {d_rd_line0[74:73], d_rd_line0[72:64], d_addr[6:2], d_rd_line0[63:0]};
							end
							else begin
								v_wr_data = {d_rd_line1[74:73], d_rd_line1[72:64], d_addr[6:2], d_rd_line1[63:0]};
							end
							v_we = 1;
							d_we = 1;
							writeLineInd = v_hit_line;
							setOffset = ~lru_in;
							//dcache_wr_data = {v_rd_data[79], 1'b1, v_rd_data[77:69], replacement};
							nextState = spin;
						end
					end
				end
				else if (wt == 1) begin
					freez = 1;
					nextState = hDetect;
					wt_sel = 1;
					d_re = 1;
				end
				else begin
					//probe = 18;
					nextState = normal;
				end
			end
			hDetect: begin
				freez = 1;
				wt_sel = 1;
				if(i_hitIn == 1) begin
					i_we = 1;
					icache_wr_data = {1'b0, 73'b0};
				end
				if(d_hitIn == 1) begin
				// if dcache hit, write back to memory if dirty;
					if(d_dirty0==1 && d_hit_ind==0) begin
						//write this line to mem and invalidate itself and write direct
						m_we = 1;
						m_addr = d_addr[15:2];
						//m_wr_data = d_rd_line0;
						w_output_sel = 0;
						m_wr_data = replacement;
						nextState = hdevict;
					end
					else if(d_dirty1==1 && d_hit_ind == 0) begin
						//write this line to mem and invalidate itself and write direct
						m_we = 1;
						m_addr = d_addr[15:2];
						w_output_sel = 0;
						m_wr_data = replacement;
						nextState = hdevict;
					end
					else begin
						//invalidate dline and goto write directly
						d_we = 1;
						dcache_wr_data = 0;
						m_re = 1;
						m_addr = d_addr[15:2];
						nextState = write_through;
					end
				end
				else if(v_hit_d == 1) begin	
					// write this line to mem and invalidate itself if dirty
					if(v_dirty == 1) begin
						m_we = 1;
						m_addr = d_addr[15:2];
						w_output_sel = 1;
						m_wr_data = replacement;
						nextState = hdevict;
					end
					else begin
						v_we = 1;
						v_wr_data=0;
						m_re = 1;
						m_addr = d_addr[15:2];
						nextState = write_through;
					end
				end
				else begin
					m_re = 1;
					m_addr = d_addr[15:2];
					nextState = write_through;
					//m_re = 1;
					//m_addr = d_addr[15:2];
				end					
			end
			
			write_through: begin
				freez = 1;
				if(m_rdy == 0) begin
					m_re = 1;
					//m_wr_data = v_rd_data[63:0];
					m_addr = d_addr[15:2];
					nextState = write_through;					
				end
				else begin
					nextState = mem_write;
					case(d_addr[1:0])
						2'b00: m_wr_data = {m_rd_data[63:16], wrt_data};
						2'b01: m_wr_data = {m_rd_data[63:32], wrt_data, m_rd_data[15:0]};
						2'b10: m_wr_data = {m_rd_data[63:48], wrt_data, m_rd_data[31:0]};
						2'b11: m_wr_data = {wrt_data, m_rd_data[47:0]};
					endcase
					m_we = 1;
					m_addr = d_addr[15:2];
				end
			end
			
			mem_write: begin
				freez = 1;
				if(m_rdy == 0) begin
					m_we = 1;
					//m_wr_data = v_rd_data[63:0];
					m_addr = d_addr[15:2];
					case(d_addr[1:0])
						2'b00: m_wr_data = {m_rd_data[63:16], wrt_data};
						2'b01: m_wr_data = {m_rd_data[63:32], wrt_data, m_rd_data[15:0]};
						2'b10: m_wr_data = {m_rd_data[63:48], wrt_data, m_rd_data[31:0]};
						2'b11: m_wr_data = {wrt_data, m_rd_data[47:0]};
					endcase
					nextState = mem_write;					
				end
				else begin
					nextState = normal;
				end
			end
			
			hdevict: begin
				freez = 1;
				if(m_rdy == 0) begin
					m_we = 1;
					m_addr = d_addr[15:2];
					m_wr_data = replacement;
					if(d_hitIn == 1) begin
						w_output_sel = 0;
					end
					else begin
						w_output_sel = 1;
					end
					nextState = hdevict;
				end
				else begin
					nextState = spin;
					if(d_hitIn == 1) begin
						d_we = 1;
						dcache_wr_data = 0;
						setOffset = d_hit_ind;
					end
					else begin
						v_we = 1;
						v_wr_data = 0;
						writeLineInd = v_hit_line;
					end
				end				
			end
			
			/* Evict Routine */
			ievict: begin
				freez = 1;	
				roll = 0;		
				if(emptySlots_reg != 4'b1111) begin
					v_we = 1;
					v_wr_data = {i_rd_data[73:72], i_rd_data[71:64], i_addr[7:2], i_rd_data[63:0]};
					case(emptySlots_reg)
						4'b0000: writeLineInd = 0;
						4'b1000: writeLineInd = 1;
						4'b1100: writeLineInd = 2;
						4'b1110: writeLineInd = 3;
						default: writeLineInd = 0;
					endcase
					nextState = ifetch;	
					m_addr = i_addr[15:2];
					m_re = 1;		
				end
				else begin
					if(v_dirty == 1) begin
						if(m_rdy == 0) begin
							m_we = 1;
							m_wr_data = victimEv_data[63:0];
							m_addr = victimEv_data[77:64];
							nextState = ievict;
						end
						else begin
							v_we = 1;
							v_wr_data = {i_rd_data[73:72], i_rd_data[71:64], i_addr[7:2], i_rd_data[63:0]};
							writeLineInd = evict_index;
							nextState = ifetch;
							m_addr = i_addr[15:2];
							m_re = 1;
						end
					end
					else begin
						v_we = 1;
						v_wr_data = {i_rd_data[73:72], i_rd_data[71:64], i_addr[7:2], i_rd_data[63:0]};
						writeLineInd = evict_index;
						nextState = ifetch;
						m_addr = i_addr[15:2];
						m_re = 1;
					end
				end
			end
			devict: begin
				freez = 1;	
				roll = 0;		
				if(emptySlots_reg != 4'b1111) begin
					v_we = 1;
					v_wr_data = (lru_in == 0) ? {d_rd_line0[74:73], d_rd_line0[72:64], d_addr[6:2], d_rd_line0[63:0]} :
												{d_rd_line1[74:73], d_rd_line1[72:64], d_addr[6:2], d_rd_line1[63:0]};
					case(emptySlots_reg)
						4'b0000: writeLineInd = 0;
						4'b1000: writeLineInd = 1;
						4'b1100: writeLineInd = 2;
						4'b1110: writeLineInd = 3;
						default: writeLineInd = 0;
					endcase
					//if(wt == 1)
					//	nextState = normal;
					//else begin
						nextState = dfetch;	
						m_addr = d_addr[15:2];
						m_re = 1;
					//end
				end
				else begin
					if(v_dirty == 1) begin
						if(m_rdy == 0) begin
							m_we = 1;
							m_wr_data = victimEv_data[63:0];
							m_addr = victimEv_data[77:64];
							nextState = devict;
						end
						else begin
							v_we = 1;
							v_wr_data = (lru_in == 0) ? {d_rd_line0[74:73], d_rd_line0[72:64], d_addr[6:2], d_rd_line0[63:0]} :
														{d_rd_line1[74:73], d_rd_line1[72:64], d_addr[6:2], d_rd_line1[63:0]};
							writeLineInd = evict_index;
							m_addr = d_addr[15:2];
							//if(wt == 1)
							//	nextState = normal;
							//else begin
								nextState = dfetch;								
								m_re = 1;
							//end
						end
					end
					else begin
						v_we = 1;
						v_wr_data = (lru_in == 0) ? {d_rd_line0[74:73], d_rd_line0[72:64], d_addr[6:2], d_rd_line0[63:0]} :
													{d_rd_line1[74:73], d_rd_line1[72:64], d_addr[6:2], d_rd_line1[63:0]};
						writeLineInd = evict_index;
						m_addr = d_addr[15:2];
						//if(wt == 1)
						//	nextState = normal;
						//else begin
							nextState = dfetch;							
							m_re = 1;
						//end
					end
				end
			end
			/* data re/we miss, dirty 0 routine */
			dfetch: begin
				freez = 1;
				m_addr = d_addr[15:2];
				if(m_rdy == 0) begin				
					m_re = 1;
					nextState = dfetch;					
				end
				else begin					
					m_re = 0;
					d_we = 1;
					setOffset = (d_valid0 == 0) ? 1'b0 :
								(d_valid1 == 0) ? 1'b1 :
								lru_in;
					dcache_wr_data = {2'b10, d_addr[15:7], m_rd_data};					
					nextState = normal;
				end
			end
			/* instr re miss routine */
			ifetch: begin
				freez = 1;
				m_addr = i_addr[15:2];
				if(m_rdy == 0) begin					
					m_re = 1;				
					nextState = ifetch;
					
				end
				else begin
					//freez = 0;
					i_output_sel2 = 1;					
					m_re = 0;	
					i_we = 1;
					icache_wr_data = {2'b10, i_addr[15:8], m_rd_data};					
					nextState = normal;
				end
			end
			spin: begin
				freez = 1;
				nextState = normal;
			end
		endcase
	end
endmodule
