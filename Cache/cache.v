`timescale 1ns / 1ps
/* cache controller */
module cache(clk, rst, i_addr_pre, i_addr, instr, i_hit, d_data, d_hit, d_addr_pre, d_addr, we, re, wrt_data, wt);

	output [15:0] instr, d_data;
	output i_hit, d_hit;
	input [15:0] i_addr_pre, d_addr, wrt_data, i_addr, d_addr_pre;
	input rst, clk, re, we, wt;

	reg [79:0] v_wr_data;          // vbuffer write bus
	reg [74:0] dcache_wr_data;	   // dcache write bus
	reg [73:0] icache_wr_data;     // icache write bus
	reg [63:0] m_wr_data;          // memory write bus
	reg [13:0] m_addr;             // mem address
	reg [1:0] writeLineInd;        // vbuffer write addr
	reg lru_we, freez, roll, wt_sel, d_we_lru, 
		setOffset, d_we, d_re, lru_out, i_we, 
		i_re, v_we, v_re, m_re, m_we;

	assign i_hit = ~freez;
	assign d_hit = ~freez;          // freez = 1 and stall the whole pipeline
	wire [79:0] v_rd_data, victimEv_data;
	wire [79:0] v_rd_data_i,v_rd_data_d;
	wire [74:0] d_rd_line0, d_rd_line1;
	wire [73:0] i_rd_data;	
	wire [63:0] m_rd_data;
	// mux for select which address to feed the icache
	// when there is a write through, feed d addr
	// when there is a write, feed current i addr
	wire [5:0] i_wr_addr_sel = (i_we==1 && wt_sel == 0) ? i_addr[7:2] : 
								wt_sel ? d_addr[7:2] : i_addr_pre[7:2];
	// when there is a write, feed current d addr
	wire [4:0] lru_addr = lru_we ? d_addr[7:2] : d_addr_pre[7:2];
	wire [5:0] i_check = i_addr_pre[7:2];
	// when there is a write, feed current d addr
	wire [4:0] d_wr_addr_sel = d_we? d_addr[6:2] : d_addr_pre[6:2];
	// record the state of occupation in vbuffer
	wire [3:0] emptySlots;
	// record the evict line number of vbuffer
	wire [1:0] evict_index;  
	wire [1:0] v_hit_line_d, v_hit_line_i;
	wire v_hit, v_hit_i, v_hit_d, lru_in, i_hitIn;
	// controls the write of dcache line1 and line2
	wire we0 = (setOffset == 0 && d_we == 1) ? 1 : 0;
	wire we1 = (setOffset == 1 && d_we == 1) ? 1 : 0;	

	/* initialize subcomponents */
	// initialize two d-cache modules & lru bits
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
				  .addra(/*d_wr_addr_sel*/lru_addr), // input [4 : 0] addra
				  .dina(lru_out), // input [0 : 0] dina
				  .douta(lru_in) // output [0 : 0] douta
				);
	// initialize icache module			
	icache icache_dt (
				  .clka(clk), // input clka
				  .wea(i_we), // input [0 : 0] wea
				  .addra(i_wr_addr_sel), // input [5 : 0] addra
				  .dina(icache_wr_data), // input [73 : 0] dina
				  .douta(i_rd_data) // output [73 : 0] douta
				);
	victim_buffer v_buffer(clk, rst, v_we, v_re, i_addr[15:2], 
						d_addr[15:2], v_wr_data, writeLineInd, 
						v_rd_data_i, v_rd_data_d, v_hit_line_i, v_hit_line_d, v_hit_i, v_hit_d, 
						evict_index, emptySlots, roll, victimEv_data, 
						~i_hitIn);	
	// main memory pool				
	main_mem u_mem(clk, m_we, m_addr, m_wr_data, m_rd_data);

	// memory delay simulation
	// count 4 cycles when there is  a write request
	// return mem-rdy when the transaction is finished
	reg [1:0] mem_cntr;
	reg mem_state, mem_nxtState;
	reg mem_cntr_en;
	localparam waitc = 1'b0;
	localparam count = 1'b1;
	wire m_rdy = (mem_state == waitc) ? 1 : 0;
	// counter that counts number of cycles for delay
	always @ (posedge clk/*, posedge rst*/) begin
		if(rst) begin
			mem_cntr <= 0;
		end
		else if(mem_cntr_en) begin
			mem_cntr <= mem_cntr+1;
		end
	end
	// define the state machine for mem-delay simulation
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
			// when there is no mem re/we action
			// spin and wait
			waitc: begin
				if(m_re | m_we) begin
					mem_nxtState = count;
					mem_cntr_en = 1;
				end
			end
			// else count until the cntr reach zero again.
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
	/**
	 * normal: handles all kinds of request, when there is a hit, it will
	 * return to itself; else it will jump to corresponding states
	 * the feeding sequence is: write through->imiss->dmiss
	 *
	 * dfetch: fetch data from memory and write it to d cache
	 *
	 * ifetch: fetch data from memory and write it to i cache
	 *
	 * ievict: evict i cache line to victim buffer, if there is
	 * a need to evict vbuffer, evict that line to memory first
	 *
	 * devict: evict d cache line to victim buffer, if there is
	 * a need to evict vbuffer, evict that line to memory first
	 *
	 * hDetect: hazard detection for write through. Will send state
	 * machine to corresponding states when there is a hit in either
	 * icache, dcache, vbuffer or none. Will also invalidate icache
	 * first
	 *
	 * write_through: read memory line from main memory, in case
	 * when there is no hit in current cache system, we need other 3 words
	 * before we write back
	 *
	 * hdevict: handle the case when there is a hit in either d-cache or vbuffer
	 * or both. Will choose the fastest way to flush the line and resume the
	 * feeding process
	 *
	 * mem_write: memory write stage for writting data during the write through
	 * action
	 *
	 * spin: spin wait one cycle deliberately since we need to prefeed the 
	 * addr to block RAM before it reads the desired line.
	 * it is used when the blockRAM addr port was previously occupied by other
	 * addresses.
	 *
	 * itest: in case for a write through action, an extra icache miss detection
	 * state is need so that the controller will not miss icache miss in 
	 * corner cases(i.e. when there is a icache miss at write through state)
	 *
	 */
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
		spin = 4'b1001,
		itest = 4'b1010,
	reg [3:0] state, nextState;
	reg [3:0] emptySlots_reg;

	// accept and hold empty slots register for one cycle
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

	// cache related signals for convenience
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
	//wire v_valid = v_rd_data[79];
	wire v_dirty_i = v_rd_data_i[78];
	wire v_dirty_d = v_rd_data_d[78];
	//wire [13:0] v_tag = v_rd_data[77:64];

	assign i_hitIn = (i_valid==1 && i_tag==i_dst_tag) ? 1 : 0;
	wire d_hitIn = ((d_valid0==1 && d_tag0==d_dst_tag) || (d_valid1==1 && d_tag1==d_dst_tag)) ? 1 : 0;
	wire d_hit_ind = (d_valid0==1 && d_tag0==d_dst_tag) ? 0 : 1;
	//wire v_hitIn = /*(v_valid == 1 && */(v_hit == 1) ? 1 : 0;


	/* select word */
	reg i_output_sel;//, i_output_sel2;
	//wire [63:0] i_cacheLine = i_output_sel ? v_rd_data : 
		//							  i_output_sel2 ? m_rd_data: i_rd_data;
	wire [63:0] i_cacheLine = i_output_sel ? v_rd_data_i : i_rd_data;
	wire [1:0] i_mux = i_addr[1:0];
	assign instr = (i_mux == 2'b11) ? i_cacheLine[63:48] :
					   (i_mux == 2'b10) ? i_cacheLine[47:32] :
					   (i_mux == 2'b01) ? i_cacheLine[31:16] :
					   i_cacheLine[15:0];

	reg d_output_sel;
	wire [63:0] d_selected_line = (d_hit_ind == 0) ? d_rd_line0 : d_rd_line1;
	wire [63:0] d_cacheLine = (d_output_sel == 1) ? v_rd_data_d : d_selected_line;
	wire [1:0] d_mux = d_addr[1:0];
	assign d_data = (d_mux == 2'b11) ? d_cacheLine[63:48] :
					   (d_mux == 2'b10) ? d_cacheLine[47:32] :
					   (d_mux == 2'b01) ? d_cacheLine[31:16] :
					   d_cacheLine[15:0];

	/* make dcache write data */
	reg w_output_sel;
	wire [63:0] writeLine = w_output_sel ? v_rd_data_d : d_selected_line;
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
	/*
	reg [1:0]set0cntr;
	reg rstcntr;
	always@(posedge clk)
		if(rstcntr)
			set0cntr <= 0;
		else
			set0cntr <= set0cntr+1;
	*/

	/* start of FSM */
	always @(*) begin
		i_re = 1;
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
		icache_wr_data = 74'bx;
		m_wr_data = 64'bx;
		writeLineInd = 2'bx;
		freez = 0;
		i_output_sel = 0;
		d_output_sel = 0;
		w_output_sel = 0;
		roll = 1;
		nextState = normal;
		//i_output_sel2 = 0;
		wt_sel = 0;
		d_we_lru = 0;
		

		case(state)
			normal: begin
				// write through detect first
				if(wt == 1) begin
					freez = 1;
					nextState = hDetect;
					wt_sel = 1;
				end
				// icache miss detection
				else if(i_hitIn == 0 && wt == 0) begin
					// if miss and vbuffer miss
					if(v_hit_i == 0) begin
						freez = 1;
						if(i_valid == 0) begin
							m_re = 1;
							nextState = ifetch;
						end
						else begin
							nextState = ievict;
							roll = 0;
							m_addr = victimEv_data[77:64];
							m_wr_data = victimEv_data[63:0];
							if(v_dirty_i == 1 && emptySlots_reg == 4'b1111) begin
								m_we = 1;
							end
						end
					end
					// else swap the content and wait one cycle for address feeding
					else begin
						i_output_sel = 1;
						v_wr_data = {i_rd_data[73:72], i_rd_data[71:64], i_addr[7:2], i_rd_data[63:0]};					
						writeLineInd = v_hit_line_i;
						v_we = 1;
						i_we = 1;
						icache_wr_data = {v_rd_data_i[79:78], v_rd_data_i[77:70], v_rd_data_i[63:0]};
						nextState = spin;
					end
				end
				// dcache miss detection
				else if(re == 1) begin
					if(d_hitIn == 1) begin
						nextState = normal;
						lru_we = 1;
						lru_out = d_hit_ind; // might be redundant
					end
					else begin						
						lru_we = 1;
						lru_out = (d_valid0 == 0) ? 0 :
								  (d_valid1 == 0) ? 1 :
								  ~lru_in;
						dcache_wr_data = {v_rd_data_d[79:78], v_rd_data_d[77:69], v_rd_data_d[63:0]};
						// if miss and vbuffer miss, go to either dfetch or devict
						if(v_hit_d == 0) begin
							freez = 1;
							if((d_valid0 == 0) || (d_valid1 == 0)) begin
								nextState = dfetch;
								m_addr = d_addr[15:2];
								m_re = 1;
							end
							else begin
								nextState = devict;
								roll = 0;
								m_wr_data = victimEv_data[63:0];
								m_addr = victimEv_data[77:64];
								if(v_dirty_d == 1 && emptySlots_reg == 4'b1111) begin
									m_we = 1;
								end
							end
						end
						// else swap the buffer and spin a cycle
						else begin
							d_output_sel = 1;
							if(lru_out == 0) begin
								v_wr_data = {d_rd_line0[74:73], d_rd_line0[72:64], d_addr[6:2], d_rd_line0[63:0]};
							end
							else begin
								v_wr_data = {d_rd_line1[74:73], d_rd_line1[72:64], d_addr[6:2], d_rd_line1[63:0]};
							end
							v_we = 1;
							writeLineInd = v_hit_line_d;
							setOffset = lru_out;
							d_we = 1;
							nextState = spin;
						end
					end
				end
				// dcache we detection
				else if (we == 1) begin
					if(d_hitIn == 1) begin
						lru_we = 1;
						lru_out = d_hit_ind;
						d_we = 1;
						dcache_wr_data = (d_hit_ind == 0) ? {2'b11, d_rd_line0[72:64], replacement} :
															{2'b11, d_rd_line1[72:64], replacement};
						setOffset = d_hit_ind;
						nextState = spin;
					end
					// if dcache miss, then test vbuffer
					else begin	
						dcache_wr_data = {2'b11, v_rd_data_d[77:69], replacement};
						lru_we = 1;
						lru_out = (d_valid0 == 0) ? 0 :
								  (d_valid1 == 0) ? 1 :
								  ~lru_in;
						if(v_hit_d == 0) begin
							freez = 1;
							if((d_valid0 == 0) || (d_valid1 == 0)) begin
								nextState = dfetch;
								m_addr = d_addr[15:2];
								m_re = 1;
							end
							else begin
								nextState = devict;
								roll = 0;
								m_wr_data = victimEv_data[63:0];
								m_addr = victimEv_data[77:64];
								if(v_dirty_d == 1 && emptySlots_reg == 4'b1111) begin
									m_we = 1;
								end
							end
						end
						// vbuffer swap operation, spin one cycle
						else begin
							w_output_sel = 1;
							if(lru_out == 0) begin
								v_wr_data = {d_rd_line0[74:73], d_rd_line0[72:64], d_addr[6:2], d_rd_line0[63:0]};
							end
							else begin
								v_wr_data = {d_rd_line1[74:73], d_rd_line1[72:64], d_addr[6:2], d_rd_line1[63:0]};
							end
							v_we = 1;
							d_we = 1;
							writeLineInd = v_hit_line_d;
							setOffset = lru_out;
							dcache_wr_data = {2'b11, v_rd_data_d[77:69], replacement};
							nextState = spin;
						end
					end
				end		
				// normal case, when both hit and not write through		
				else begin
					nextState = normal;
				end
			end
			// serve i cache miss
			itest: begin
				if(i_hitIn == 0 && wt == 0) begin
					if(v_hit_i == 0) begin
						freez = 1;
						if(i_valid == 0) begin
							m_re = 1;
							nextState = ifetch;
						end
						else begin
							nextState = ievict;
							roll = 0;
							m_addr = victimEv_data[77:64];
							m_wr_data = victimEv_data[63:0];
							if(v_dirty_i == 1) begin
								m_we = 1;
							end
						end
					end
					else begin
						i_output_sel = 1;
						v_wr_data = {i_rd_data[73:72], i_rd_data[71:64], i_addr[7:2], i_rd_data[63:0]};					
						writeLineInd = v_hit_line_i;
						v_we = 1;
						i_we = 1;
						icache_wr_data = {v_rd_data_i[79:78], v_rd_data_i[77:70], v_rd_data_i[63:0]};
						nextState = spin;
					end
				end
				else begin
					nextState = normal;
				end
			end
			hDetect: begin
				freez = 1;
				wt_sel = 1;
				// detect and flush icache hit line
				if(i_tag == d_addr[15:8]) begin
					i_we = 1;
					icache_wr_data = 0;
				end
				if(d_hitIn == 1) begin
				// if dcache hit, write back to memory if dirty;
					if(v_hit_d == 1) begin
						v_we = 1;
						v_wr_data=0;
						writeLineInd = v_hit_line_d;
					end
					if((d_dirty0==1 && d_hit_ind==0)||(d_dirty1==1 && d_hit_ind == 1)) begin
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
						setOffset = d_hit_ind;
						m_re = 1;
						m_addr = d_addr[15:2];
						nextState = write_through;
					end
				end
				else if(v_hit_d == 1) begin	
					// write this line to mem and invalidate itself if dirty
					if(v_dirty_d == 1) begin
						m_we = 1;
						m_addr = d_addr[15:2];
						w_output_sel = 1;
						m_wr_data = replacement;
						nextState = hdevict;
					end
					else begin
					// or we can simply invalidate the vbuffer line
						v_we = 1;
						v_wr_data=0;
						writeLineInd = v_hit_line_d;
						m_re = 1;
						m_addr = d_addr[15:2];
						nextState = write_through;
					end
				end
				else begin
					m_re = 1;
					m_addr = d_addr[15:2];
					nextState = write_through;
				end					
			end
			
			write_through: begin
				freez = 1;
				m_addr = d_addr[15:2];
				if(m_rdy == 0) begin
					m_re = 1;					
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
				end
			end
			
			mem_write: begin
				freez = 1;
				m_addr = d_addr[15:2];
				if(m_rdy == 0) begin
					m_we = 1;					
					case(d_addr[1:0])
						2'b00: m_wr_data = {m_rd_data[63:16], wrt_data};
						2'b01: m_wr_data = {m_rd_data[63:32], wrt_data, m_rd_data[15:0]};
						2'b10: m_wr_data = {m_rd_data[63:48], wrt_data, m_rd_data[31:0]};
						2'b11: m_wr_data = {wrt_data, m_rd_data[47:0]};
					endcase
					nextState = mem_write;					
				end
				else begin
					//freez = 0;
					nextState = itest;
				end
			end
			
			hdevict: begin
				freez = 1;
				if(m_rdy == 0) begin
					m_we = 1;
					m_addr = d_addr[15:2];
					m_wr_data = replacement;
					if(v_hit_d == 1) begin
						w_output_sel = 1;
					end
					nextState = hdevict;
				end
				else begin
					freez = 0;
					nextState = itest;
					if(d_hitIn == 1) begin
						d_we = 1;
						dcache_wr_data = 0;
						setOffset = d_hit_ind;
					end
					else begin
						v_we = 1;
						v_wr_data = 0;
						writeLineInd = v_hit_line_d;
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
					// handle different occupation stats
					// TODO: could be replaced by casex for simplicity and area
					case(emptySlots_reg)
						4'b0000: writeLineInd = 0;
						4'b0001: writeLineInd = 0;
						4'b0010: writeLineInd = 0;
						4'b0011: writeLineInd = 0;
						4'b0100: writeLineInd = 0;
						4'b0101: writeLineInd = 0;
						4'b0110: writeLineInd = 0;
						4'b0111: writeLineInd = 0;
						4'b1000: writeLineInd = 1;
						4'b1001: writeLineInd = 1;
						4'b1010: writeLineInd = 1;
						4'b1011: writeLineInd = 1;
						4'b1100: writeLineInd = 2;
						4'b1101: writeLineInd = 2;
						4'b1110: writeLineInd = 3;
						default: writeLineInd = 0;
					endcase
					nextState = ifetch;	
					m_addr = i_addr[15:2];
					m_re = 1;		
				end
				else begin
					if(v_dirty_i == 1) begin
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
				if(v_hit_d == 1) begin
						v_we = 1;
						v_wr_data = (lru_in == 0) ? {d_rd_line0[74:73], d_rd_line0[72:64], d_addr[6:2], d_rd_line0[63:0]} :
												{d_rd_line1[74:73], d_rd_line1[72:64], d_addr[6:2], d_rd_line1[63:0]};
						writeLineInd = v_hit_line_d;
						nextState = dfetch;
				end				
				else if(emptySlots_reg != 4'b1111) begin
					v_we = 1;
					v_wr_data = (lru_in == 0) ? {d_rd_line0[74:73], d_rd_line0[72:64], d_addr[6:2], d_rd_line0[63:0]} :
												{d_rd_line1[74:73], d_rd_line1[72:64], d_addr[6:2], d_rd_line1[63:0]};
					// handle different occupation stats
					// TODO: could be replaced by casex for simplicity and area
					case(emptySlots_reg)
						4'b0000: writeLineInd = 0;
						4'b0001: writeLineInd = 0;
						4'b0010: writeLineInd = 0;
						4'b0011: writeLineInd = 0;
						4'b0100: writeLineInd = 0;
						4'b0101: writeLineInd = 0;
						4'b0110: writeLineInd = 0;
						4'b0111: writeLineInd = 0;
						4'b1000: writeLineInd = 1;
						4'b1001: writeLineInd = 1;
						4'b1010: writeLineInd = 1;
						4'b1011: writeLineInd = 1;
						4'b1100: writeLineInd = 2;
						4'b1101: writeLineInd = 2;
						4'b1110: writeLineInd = 3;
						//4'b0000: writeLineInd = 0;
						default: writeLineInd = 0;
					endcase
					nextState = dfetch;	
					m_addr = d_addr[15:2];
					m_re = 1;
				end
				else begin
					if(v_dirty_d == 1) begin
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
							nextState = dfetch;								
							m_re = 1;
						end
					end
					else begin
						v_we = 1;
						v_wr_data = (lru_in == 0) ? {d_rd_line0[74:73], d_rd_line0[72:64], d_addr[6:2], d_rd_line0[63:0]} :
													{d_rd_line1[74:73], d_rd_line1[72:64], d_addr[6:2], d_rd_line1[63:0]};
						writeLineInd = evict_index;
						m_addr = d_addr[15:2];
						nextState = dfetch;							
						m_re = 1;
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
					i_we = 1;
					icache_wr_data = {2'b10, i_addr[15:8], m_rd_data};					
					nextState = normal;
				end
			end
			// spin wait white freezing the pipeline
			spin: begin
				freez = 1;
				nextState = normal;
			end
		endcase
	end
endmodule
