module t_abTesting();
	
	reg clk, start, rst;
	reg[31:0] inS[3:0];
	reg[31:0] L;
	always	#5 clk = ~clk;	
	wire[127:0] S;
	wire finish;
	integer i;
	abTesting DUT(.S({inS[3],inS[2],inS[1],inS[0]}), .L(L), .clk(clk), .reset(rst), .outS(S), .finish(finish));
	
	always@(posedge finish)begin 
		$display("S: %.8x %.8x %.8x %.8x\n", S[31:0], S[63:32], S[95:64], S[127:96]);
	end
	
	initial begin
		L = 1;
		inS[0] = 2;
		inS[1] = 0;
		inS[2] = 0;
		inS[3] = 0;
		clk = 0;
		start = 0;
		rst = 1;
		#5 rst = 0;
		for(i=0; i < 10; i = i + 1) begin
			#125 rst = 1;
			inS[0] = inS[0] + 1;
			#5 rst = 0;
		end
		#5 rst = 0;
		$stop;
//		start = 1;
//		#2000 $stop;
	end






endmodule