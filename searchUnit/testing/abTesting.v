module abTesting(S, clk, reset, outS, finish);
	localparam t = 4;
	localparam c = 1;
	input reset, clk;
	input[127:0] S;
//	output reg[31:0] A,B;
	reg[31:0] A, B;
	output[127:0] outS;
	reg[31:0] sArray[3:0];
	reg[31:0] lArray;
	reg[31:0] tmpA, tmpB, A_in, B_in, S_in, L_in;
	reg[3:0] i, j;
//	wire[31:0] S,L;
	output finish;
//	assign S = 32'h2;
	assign L = 32'h1;
	
	assign outS[31:0] = sArray[0];
	assign outS[63:32] = sArray[1];
	assign outS[95:64] = sArray[2];
	assign outS[127:96] = sArray[3];
	
	
	assign finish = (j==12) ? 1 : 0;
	
	function[31:0] ROTL;
		input[31:0] A, rAmt;
		reg[63:0] tmp1, tmp2;
		begin
			tmp1 = {A,A};
			tmp2 = tmp1 << rAmt[4:0];
			ROTL = tmp2[63:32];
		end
	endfunction
	
	

	always@(posedge clk or posedge reset) begin
		if(reset) begin
			A <= 0;
			B <= 0;
			sArray[0] <= S[31:0];
			sArray[1] <= S[63:32];
			sArray[2] <= S[95:64];
			sArray[3] <= S[127:96];
			lArray <= L;
			i <= 0;
			j <= 0;
		end
		else begin
			sArray[0] <= sArray[0];
			sArray[1] <= sArray[1];
			sArray[2] <= sArray[2];
			sArray[3] <= sArray[3];
			if(j < (3*t)) begin
				A <= A_in;
				B <= B_in;
				sArray[i] <= S_in;
				lArray <= L_in;
				i <= (i+1)%t;
				j <= j + 1;
			end
			else begin
				A <= A;
				B <= B;
				lArray <= lArray;
				i <= i;
				j <= 0;
			end
		
		end
	
	end
	
	always@(A, B, sArray[0], sArray[1], sArray[2], sArray[3], lArray, tmpA, tmpB, A_in, B_in) begin
		tmpA = A;
		A_in = ROTL((A+B+sArray[i]),3);
		S_in = ROTL((tmpA+B+sArray[i]), 3);
		tmpB = B;
		B_in = ROTL((A_in + B + lArray), (A_in + B));
		L_in = ROTL((A_in + tmpB + lArray), (A_in + tmpB));
	end
	

	
endmodule