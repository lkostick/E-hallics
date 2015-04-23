`timescale 1ns/100ps
module accelerator_control_tb();


reg clk, rst;
reg[1:0] control;//00 do nothing, 01 start, 10 read, 11 stop
reg[4:0] address;// cipher text buffer(lower4bit), performance count 1, 2, 3, and key upper 16 & lower 16
reg[15:0] data;//data from processor
reg[15:0] pckeydata;//data from pereformance count or keybuffer
wire[3:0] pckeyaddr;
wire startLC;
wire[15:0] dataToProc;
wire[63:0] dataToLC;
wire[2:0] levels;//level count for loading cipher text	
wire stop;

accelerator_control ac(clk, rst, control, address, data, pckeydata, pckeyaddr, startLC, dataToProc, dataToLC, levels, stop);
/*
reg[15:0] writeReq;
reg Qfull;
wire[3:0] regEn;
wire[63:0]dataToReg;
wire startSU, incrPC, stopSU, enableQ;//to Q
wire [4:0] writeQen;//to mux
wire[15:0] writeSucceeded;//to search unit;


module level0control(clk, rst, stop, stopSU, dataToLC, startLC, levels, regEn, dataToReg, startSU, writeReq, writeQen, enableQ, incrPC, Qfull, writeSucceeded);
module level1control(clk, rst, stop, stopSU, dataToLC, startLC, levels, regEn, dataToReg, startSU, writeReq, writeQen, enableQ, incrPC, Qfull, writeSucceeded);
module level2control(clk, rst, stop, stopSU, dataToLC, startLC, levels, regEn, dataToReg, startSU, writeReq, writeQen, enableQ, incrPC, Qfull, writeSucceeded);
module level3control(clk, rst, stop, stopSU, dataToLC, startLC, levels, regEn, dataToReg, startSU, writeReq, writeQen, enableQ, incrPC, Qfull, writeSucceeded);
*/



initial begin
clk=1'b0;
rst=1'b1;
control=2'b00;
address=5'b11111;
data=16'h0000;
pckeydata=16'h0000;
repeat (2) @ (posedge clk);
rst=1'b0;
repeat (2) @ (posedge clk);
control=2'b01;
@(posedge clk) control=2'b00;
address=5'b00000;
data=16'hf0f0;//1
@(posedge clk)
address=5'b00001;
data=16'hff00;//2
@(posedge clk)
address=5'b00010;
data=16'hf000;//3
@(posedge clk)
address=5'b00011;
data=16'he000;//4
@(posedge clk)
address=5'b00100;
data=16'hd000;//5
@(posedge clk)
address=5'b00101;
data=16'hc000;//6
@(posedge clk)
address=5'b00110;
data=16'hb000;//7
@(posedge clk)
address=5'b00111;
data=16'ha000;//8
@(posedge clk)
address=5'b01000;
data=16'h9000;//9
@(posedge clk)
address=5'b01001;
data=16'h8000;//10
@(posedge clk)
address=5'b01010;
data=16'h7000;//11
@(posedge clk)
address=5'b01011;
data=16'h6000;//12
@(posedge clk)
address=5'b01100;
data=16'h5000;//13
@(posedge clk)
address=5'b01101;
data=16'h4000;//14
@(posedge clk)
address=5'b01110;
data=16'h3000;//15
@(posedge clk)
address=5'b01111;
data=16'h2000;//16
repeat (4) @(posedge clk);

//control=2'b11;

end

always 
#10 clk=~clk;

endmodule
