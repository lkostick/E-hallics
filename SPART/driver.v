`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:53:21 01/29/2015 
// Design Name: 
// Module Name:    driver 
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
module driver(
    input clk,
    input rst,
    output reg iorw,
    input rda,
    input tbr,
    output reg [1:0] ioaddr,
    inout [7:0] databus,
	output full,
	input send,
	input [7:0] data_in
    );

	/**
	* If fifo is not empty, this driver will read data from fifo and send it
	* 
	*/

   	wire empty;
	reg rd_en, flag;
	wire [7:0] send_data;

	assign databus = (iorw) ? 8'hzz : send_data;

	FIFO iDUT(.clk(clk), .rst(rst), .din(data_in), .wr_en(send), .rd_en(rd_en), .dout(send_data), .full(full), .empty(empty));

	always @(posedge clk, posedge rst)
	begin
		if (rst)
		begin
			iorw <= 1'bx;
			ioaddr <= 2'bx;
			rd_en <= 0;
			flag <= 0;
		end
		else if (rda == 1) //receive data
		begin
			iorw <= 1;
			ioaddr <= 2'b00;
			rd_en <= 0;
			flag <=0;
		end
		else if (~empty & ~flag) begin //read data
			iorw <= 1;
			ioaddr <= 2'b01;
			rd_en <= 1;
			flag <= 1;
		end
		else if (flag & tbr) //send data
		begin
			iorw <= 0;
			ioaddr <= 2'b00;
			rd_en <= 0;
			flag <= 0;
		end
		else //idle
		begin
			iorw <= 1;
			ioaddr <= 2'b01;
			rd_en <= 0;
			flag <= flag;
		end
	end

endmodule
