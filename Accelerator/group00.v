module group00(clk, rst, stop, dataToLC, startLC, levels, dataToReg, incrPC, keyOut, Qempty);
input clk, rst, stop;
input[63:0] dataToLC;
input startLC;
input[2:0] levels;
wire Qfull;
wire enableQ;
output Qempty;
output [31:0] keyOut;
output[63:0] dataToReg;
output incrPC;
wire stopSU, startSU;
wire[3:0] regEn;
wire[15:0] writeReq;
wire[4:0] writeQen;//mux
wire [15:0] writeSucceeded;
wire[31:0] key0, key1, key2;
reg [31:0] key;
wire writeReq0, writeReq1, writeReq2;
level0control level0(clk, rst, stop, stopSU, dataToLC, startLC, levels, regEn, dataToReg, startSU, writeReq, writeQen, enableQ, incrPC, Qfull, writeSucceeded);
su su0(rst, clk, startSU, stopSU, writeSucceeded[0], key0, writeReq0);
su1 su1(rst, clk, startSU, stopSU, writeSucceeded[1], key1, writeReq1);
su2 su2(rst, clk, startSU, stopSU, writeSucceeded[2], key2, writeReq2);

queue0 queue00 (
  .clk(clk), // input clk
  .rst(rst), // input rst
  .din(key), // input [31 : 0] din
  .wr_en(enableQ), // input wr_en
  .rd_en(1'b1), // input rd_en
  .dout(keyOut), // output [31 : 0] dout
  .full(Qfull), // output full
  .empty(Qempty) // output empty
);

assign writeReq={13'h0000, writeReq2, writeReq1, writeReq0};
always@(*)
case(writeQen)
5'b00000: key=key0;
5'b00001: key=key1;
5'b00010: key=key2;
default:  key=32'hffffffff;
endcase



endmodule
