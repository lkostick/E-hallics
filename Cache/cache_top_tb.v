`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:36:15 04/09/2015 
// Design Name: 
// Module Name:    top_level_tb 
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
module cache_top_tb();
	reg clk;
	reg rst;
	reg [15:0] i_addr;
	reg [15:0] d_addr, wrt_data;
	reg [15:0] i_addr_pre, d_addr_pre;
	wire [15:0] instr, d_data;
	wire i_hit, d_hit;
	reg we, re;
	//reg m_we;
	reg [13:0] m_addr; 
	reg [15:0] m_wr_data;
	reg wt;
	
	cache cache_DUT(clk, rst, i_addr_pre, i_addr, instr, i_hit, d_data, d_hit, d_addr_pre, d_addr, we, re, wrt_data, wt);
	clk_gen clk_gen_module(.CLKIN_IN(clk), .RST_IN(rst), .CLKIN_IBUFG_OUT(clk_glb), .CLK0_OUT(), .LOCKED_OUT());
	
	// test the case when both icache and dcache miss
	task DUAL_MISS;
		begin
			@(negedge clk) begin
				re = 1;
			end
			@(posedge clk) begin
				i_addr = 1;
				i_addr_pre = 2;
				re = 1;
			end
			#10;
			re = 0;
			while(i_hit==1'b0) begin 
				#5; 
			end
			
		end
	endtask
	// test the case when i evict many times to victim buffer
	task I_MULTI_EVICT;
		begin
			#30;
			@(negedge clk) begin
				i_addr_pre = 16'h0103;
			end
			@(posedge clk) begin
				i_addr = 16'h0103;
				// this test getting data from next line
				i_addr_pre = 16'h0104;
			end
			//$display("before here\n");
			//$strobe("i_hit value is: %d\n",i_hit);
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end			
			@(posedge clk) begin
				i_addr = 16'h0104;
				i_addr_pre = 16'h0201;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			@(posedge clk) begin
				i_addr = 16'h0201;
				i_addr_pre = 16'h0302;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			@(posedge clk) begin
				i_addr = 16'h0302;
				i_addr_pre = 16'h0500;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			@(posedge clk) begin
				i_addr = 16'h0500;
				// revisit previous hit in the victim buffer
				i_addr_pre = 16'h0100;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			@(posedge clk) begin
				i_addr = 16'h0100;
				// introduce more miss
				i_addr_pre = 16'h0700;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			@(posedge clk) begin
				i_addr = 16'h0700;
				// get original missed one
				i_addr_pre = 16'h0000;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			@(posedge clk) begin
				i_addr = 16'h0000;
				// introduce more miss
				//i_addr_pre = 16'h0000;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end			
		end
	endtask
	
	task D_MULTI_EVICT;
		begin
			#30;
			re = 1;
			@(negedge clk) begin
				d_addr_pre = 16'h0103;
			end
			@(posedge clk) begin
				d_addr = 16'h0103;
				// this test getting data from next line
				d_addr_pre = 16'h0104;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			@(posedge clk) begin
				d_addr = 16'h0104;
				// this test getting data from next line
				// should go to second lru set
				d_addr_pre = 16'h0200;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			@(posedge clk) begin
				d_addr = 16'h0200;
				// this test getting data from next line
				// should go to second lru set
				d_addr_pre = 16'h0301;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			@(posedge clk) begin
				d_addr = 16'h0301;
				// this test getting data from next line
				// should go to second lru set
				d_addr_pre = 16'h0402;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			@(posedge clk) begin
				d_addr = 16'h0402;
				// this test getting data from next line
				// should go to second lru set
				d_addr_pre = 16'h0503;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			@(posedge clk) begin
				d_addr = 16'h0503;
				// this test getting data from next line
				// should go to second lru set
				d_addr_pre = 16'h0401;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			@(posedge clk) begin
				d_addr = 16'h0401;
				// this test getting data from next line
				// should go to second lru set
				d_addr_pre = 16'h0700;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			@(posedge clk) begin
				d_addr = 16'h0700;
				// this test getting data from next line
				// should go to second lru set
				//d_addr_pre = 16'h0200;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			re = 0;
		end
	endtask
	
	task D_MULTI_TEST_W;
		begin
			#30;
			//re = 1;
			@(negedge clk) begin
				d_addr_pre = 16'h0103;
			end
			@(posedge clk) begin
				d_addr = 16'h0103;
				we = 1;
				// this test getting data from next line
				d_addr_pre = 16'h0104;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			we = 0;
			@(posedge clk) begin
				d_addr = 16'h0104;
				we = 1;
				// this test getting data from next line
				// should go to second lru set
				d_addr_pre = 16'h0200;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			we = 0;
			@(posedge clk) begin
				d_addr = 16'h0200;
				we = 1;
				// this test getting data from next line
				// should go to second lru set
				d_addr_pre = 16'h0301;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			we = 0;
			@(posedge clk) begin
				d_addr = 16'h0301;
				// this test getting data from next line
				// should go to second lru set
				d_addr_pre = 16'h0402;
				we = 1;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			we = 0;
			@(posedge clk) begin
				d_addr = 16'h0402;
				// this test getting data from next line
				// should go to second lru set
				d_addr_pre = 16'h0503;
				we = 1;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			we = 0;
			@(posedge clk) begin
				d_addr = 16'h0503;
				// this test getting data from next line
				// should go to second lru set
				d_addr_pre = 16'h0401;
				we = 1;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			we = 0;
			@(posedge clk) begin
				d_addr = 16'h0401;
				// this test getting data from next line
				// should go to second lru set
				d_addr_pre = 16'h0700;
				we = 1;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			we = 0;
			@(posedge clk) begin
				d_addr = 16'h0700;
				// this test getting data from next line
				// should go to second lru set
				//d_addr_pre = 16'h0200;
				we = 1;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			we = 0;
			re = 0;
		end
	endtask
	
	task WT_MULTI_TEST;
		begin
			#30;
			//re = 1;
			@(negedge clk) begin
				d_addr_pre = 16'h0000;
			end
			@(posedge clk) begin
				re = 1;
				d_addr = 16'h0000;
				//we = 1;
				// this test getting data from next line
				d_addr_pre = 16'h0000;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			re = 0;
			//we = 0;
			@(posedge clk) begin
				d_addr = 16'h0000;
				// we = 1;
				// this test getting data from next line
				// should go to second lru set
				we = 1;
				//wt = 1;
				wrt_data = 16'hffff;
				//d_addr_pre = 16'h0200;
			end
			#30;
			we = 0;
			while(i_hit==1'b0) begin 
				#20; 
			end
			@(posedge clk) begin
				d_addr = 16'h0000;
				// we = 1;
				// this test getting data from next line
				// should go to second lru set
				re = 1;
				//wt = 1;
				wrt_data = 16'hffff;
				//d_addr_pre = 16'h0200;
			end
			#20;
			re = 0;
			while(i_hit==1'b0) begin 
				#20; 
			end
			@(posedge clk) begin
				d_addr = 16'h0000;
				// we = 1;
				// this test getting data from next line
				// should go to second lru set
				wt = 1;
				//wt = 1;
				wrt_data = 16'hfffe;
				d_addr_pre = 16'h0000;
			end
			#30;
			wt = 0;
			while(i_hit==1'b0) begin 
				#20; 
				// expect imiss;
			end
			@(posedge clk) begin
				d_addr = 16'h0000;
				// we = 1;
				// this test getting data from next line
				// should go to second lru set
				we = 1;
				//wt = 1;
				//wt = 1;
				wrt_data = 16'hcccf;
				d_addr_pre = 16'h0100;
			end
			#20;
			we = 0;
			#10;
			while(i_hit==1'b0) begin 
				#20; 
				// expect imiss;
			end
			@(posedge clk) begin
				d_addr = 16'h0100;
				// we = 1;
				// this test getting data from next line
				// should go to second lru set
				we = 1;
				//wt = 1;
				//wt = 1;
				wrt_data = 16'hccca;
				d_addr_pre = 16'h0200;
			end
			#30;
			we = 0;
			while(i_hit==1'b0) begin 
				#20; 
				// expect imiss;
			end
			@(posedge clk) begin
				d_addr = 16'h0200;
				// we = 1;
				// this test getting data from next line
				// should go to second lru set
				we = 1;
				//wt = 1;
				//wt = 1;
				wrt_data = 16'hcccf;
				d_addr_pre = 16'h0000;
			end
			#30;
			we = 0;
			while(i_hit==1'b0) begin 
				#20; 
				// expect imiss;
			end
			@(posedge clk) begin
				d_addr = 16'h0000;
				// we = 1;
				// this test getting data from next line
				// should go to second lru set
				wt = 1;
				//wt = 1;
				//wt = 1;
				wrt_data = 16'hcccd;
				//d_addr_pre = 16'h0200;
			end
			#30;
			wt = 0;
			while(i_hit==1'b0) begin 
				#20; 
				// expect imiss;
			end
			/*
			//we = 0;
			@(posedge clk) begin
				d_addr = 16'h0200;
				//we = 1;
				// this test getting data from next line
				// should go to second lru set
				d_addr_pre = 16'h0301;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			//we = 0;
			@(posedge clk) begin
				d_addr = 16'h0301;
				// this test getting data from next line
				// should go to second lru set
				d_addr_pre = 16'h0402;
				//we = 1;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			//we = 0;
			@(posedge clk) begin
				d_addr = 16'h0402;
				// this test getting data from next line
				// should go to second lru set
				d_addr_pre = 16'h0503;
				//we = 1;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			//we = 0;
			@(posedge clk) begin
				d_addr = 16'h0503;
				// this test getting data from next line
				// should go to second lru set
				d_addr_pre = 16'h0401;
				//we = 1;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			//we = 0;
			@(posedge clk) begin
				d_addr = 16'h0401;
				// this test getting data from next line
				// should go to second lru set
				d_addr_pre = 16'h0700;
				//we = 1;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			//we = 0;
			@(posedge clk) begin
				d_addr = 16'h0700;
				// this test getting data from next line
				// should go to second lru set
				//d_addr_pre = 16'h0200;
				//we = 1;
			end
			#10;
			while(i_hit==1'b0) begin 
				#20; 
			end
			*/
			we = 0;
			re = 0;
		end
	endtask
	
	initial begin
		rst = 1;
		i_addr = 16'h0;
		i_addr_pre = 16'h1;
		d_addr = 16'h0;
		d_addr_pre = 16'h1;
		we = 0;
		re = 0;
		wrt_data = 0;
		wt = 0;
		#100;
		rst = 0;
		DUAL_MISS();
		I_MULTI_EVICT();
		D_MULTI_EVICT();
		D_MULTI_TEST_W();
		WT_MULTI_TEST();
		#300;
		$stop();
	end
	initial begin
	  clk = 1;
	end
	always clk = #10 ~clk;

endmodule
