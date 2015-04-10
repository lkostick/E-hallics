`timescale 1ns/100ps
module group00_tb();
reg clk, rst, stop;
reg[63:0] dataToLC;
reg startLC;
reg[2:0] levels;
wire Qempty;
wire[31:0] keyOut;
wire[63:0] dataToReg;
wire incrPC;
//group00 group00DUT(clk, rst, stop, dataToLC, startLC, levels, dataToReg, incrPC, key, Qfull, enableQ);
group00 group00DUT(clk, rst, stop, dataToLC, startLC, levels, dataToReg, incrPC, keyOut, Qempty);
initial begin
clk=1'b0;
rst=1'b1;
startLC=0;

stop=0;
repeat (5) @(posedge clk);
rst=1'b0;
startLC=1;
levels=3'b000;
repeat (2) @(posedge clk);
startLC=0;
dataToLC=64'hFFF0F0F0F0F0F0FF;


end

always
#10 clk= ~clk;



endmodule
