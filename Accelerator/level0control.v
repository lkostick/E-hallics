module level0control(clk, rst, stop, stopSU, dataToLC, startLC, levels, regEn, dataToReg, startSU, writeReq, writeQen, enableQ, incrPC, Qfull, writeSucceeded);
input clk, rst, stop;
input[63:0]dataToLC;
input startLC;
input [2:0] levels;
input[15:0] writeReq;
input Qfull;
output reg[3:0] regEn;
output[63:0]dataToReg;
output reg startSU, incrPC, stopSU, enableQ;//to Q
output reg [4:0] writeQen;//to mux
output reg[15:0] writeSucceeded;//to search unit;

reg[1:0] state, nextstate;
localparam idle=2'b00;
localparam loadregister=2'b01;
localparam rrwrite=2'b10;
localparam stopstate=2'b11;

assign dataToReg=dataToLC;

always@(posedge clk, posedge rst)
	if (rst)
		state<=idle;
	else
		state<=nextstate;
		
		
always@(*) begin
regEn=4'b0000;
startSU=0;
enableQ=0;
writeQen=5'b10000;
incrPC=0;
stopSU=0;
writeSucceeded=16'h0000;
case(state)
	idle:	begin
		if (startLC==1 && levels==3'b000)
			nextstate=loadregister;
		else if(stop==1) begin
			stopSU=1;
			nextstate=stopstate;
			end
		else if((|writeReq)==1) begin
			if(Qfull!=1)
				nextstate=rrwrite;
			else
				nextstate=idle;
			end	
		else
			nextstate=idle;
	end
	loadregister: begin
		regEn=4'b1111;
		nextstate=idle;
		startSU=1;
	end
	rrwrite: begin
		casex(writeReq)
		16'bXXXXXXXXXXXXXXX1: begin	writeQen=5'h00; writeSucceeded=16'h0001; end
		16'bXXXXXXXXXXXXXX1X: begin	writeQen=5'h01;	writeSucceeded=16'h0002; end
		16'bXXXXXXXXXXXXX1XX: begin	writeQen=5'h02;	writeSucceeded=16'h0004; end
		16'bXXXXXXXXXXXX1XXX: begin	writeQen=5'h03;	writeSucceeded=16'h0008; end
		16'bXXXXXXXXXXX1XXXX: begin	writeQen=5'h04;	writeSucceeded=16'h0010; end
		16'bXXXXXXXXXX1XXXXX: begin	writeQen=5'h05;	writeSucceeded=16'h0020; end
		16'bXXXXXXXXX1XXXXXX: begin	writeQen=5'h06;	writeSucceeded=16'h0040; end
		16'bXXXXXXXX1XXXXXXX: begin	writeQen=5'h07;	writeSucceeded=16'h0080; end
		16'bXXXXXXX1XXXXXXXX: begin	writeQen=5'h08;	writeSucceeded=16'h0100; end
		16'bXXXXXX1XXXXXXXXX: begin	writeQen=5'h09;	writeSucceeded=16'h0200; end
		16'bXXXXX1XXXXXXXXXX: begin	writeQen=5'h0A;	writeSucceeded=16'h0400; end
		16'bXXXX1XXXXXXXXXXX: begin	writeQen=5'h0B;	writeSucceeded=16'h0800; end
		16'bXXX1XXXXXXXXXXXX: begin	writeQen=5'h0C;	writeSucceeded=16'h1000; end
		16'bXX1XXXXXXXXXXXXX: begin	writeQen=5'h0D;	writeSucceeded=16'h2000; end
		16'bX1XXXXXXXXXXXXXX: begin	writeQen=5'h0E;	writeSucceeded=16'h4000; end
		16'b1XXXXXXXXXXXXXXX: begin	writeQen=5'h0F;	writeSucceeded=16'h8000; end
		default:			  begin	writeQen=5'h10;	writeSucceeded=16'h0000; end
		endcase
		enableQ=1;
		incrPC=1;
		nextstate=idle;
	end	
	stopstate: begin
		stopSU=1;
		nextstate = stopstate;
	end
	default: nextstate=idle;
endcase
end

endmodule
