`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   
// Design Name: 
// Module Name:    spart 
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
module spart(
    input clk,
    input rst,
    input iorw,
    output rda,
    output tbr,
    input [1:0] ioaddr,
    inout [7:0] databus,
    output txd,
    input rxd
    );

	wire [7:0] DATAOUT,R_BUFFER;
	wire Enable;

	Bus_Interface iBUS(.DATABUS(databus), .DATAOUT(DATAOUT), .R_BUFFER(R_BUFFER), .RDA(rda), .TBR(tbr), .IORW(iorw), .IOADDR(ioaddr));

	BAUD_Rate_Gen iBAUD(.clk(clk), .rst(rst), .Enable(Enable));

	Transmit iTRAN(.TxD(txd), .TBR(tbr), .DATA(DATAOUT), .IOADDR(ioaddr), .clk(clk), .rst(rst), .Enable(Enable), .IORW(iorw));

	Receive iRECE(.DATA(R_BUFFER), .RDA(rda), .RxD(rxd), .Enable(Enable), .clk(clk), .rst(rst), .IORW(iorw), .IOADDR(ioaddr));

endmodule
