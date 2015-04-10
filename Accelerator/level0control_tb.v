`timescale 1ns/100ps
module level0control_tb();
reg clk, rst, stop;
reg[63:0]dataToLC;
reg startLC;
reg [2:0] levels;
reg[15:0] writeReq;
reg Qfull;
wire[3:0] regEn;
wire[63:0]dataToReg;
wire startSU, incrPC, stopSU, enableQ;//to Q
wire [4:0] writeQen;//to mux
wire[15:0] writeSucceeded;//to search unit;

level0control level0(clk, rst, stop, stopSU, dataToLC, startLC, levels, regEn, dataToReg, startSU, writeReq, writeQen, enableQ, incrPC, Qfull, writeSucceeded);
initial begin
clk=1'b0;
rst=1'b1;
startLC=0;
Qfull=0;
stop=0;
writeReq=16'h0000;
repeat (5) @(posedge clk);
rst=1'b0;
startLC=1;
levels=3'b001;//level0 control shouldn't start
repeat (2) @(posedge clk);
levels=3'b000;
repeat (2) @(posedge clk);
startLC=0;
dataToLC=64'hFFF0F0F0F0F0F0FF;

repeat (1) @(posedge clk);
writeReq=16'h0001; 
repeat (2) @(posedge clk);
writeReq=16'h0000;
repeat (2) @(posedge clk);
writeReq=16'h8000;
repeat (2) @(posedge clk);
writeReq=16'h8001;
repeat (2) @(posedge clk);

Qfull=1;
repeat (2) @(posedge clk);
writeReq=16'h0020;
repeat (2) @(posedge clk);
writeReq=16'h0000;
repeat (2) @(posedge clk);

Qfull=0;
repeat (2) @(posedge clk);
writeReq=16'h0500;

repeat (2) @(posedge clk);
stop=1;


end

always 
#10 clk=~clk;

endmodule
