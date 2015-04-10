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
	input [7:0] data_in,
	output reg RCV,
	input [2:0] addr,
	output reg [15:0] data_out,
	output [7:0] GPIO
    );

	/**
	* If fifo is not empty, this driver will read data from fifo and send it
	* 
	*/

   	wire empty;
	reg rd_en, flag, data_flag;
	wire [7:0] send_data;

	assign databus = (iorw) ? 8'hzz : send_data;

	FIFO iDUT(.clk(clk), .rst(rst), .din(data_in), .wr_en(send), .rd_en(rd_en), .dout(send_data), .full(full), .empty(empty));

	always @(posedge clk, posedge rst)
	begin
		if (rst)
		begin
			iorw <= 1;
			ioaddr <= 2'b01;
			rd_en <= 0;
			flag <= 0;
			data_flag <= 0;
		end
		else if (rda & ~data_flag) //receive data
		begin
			iorw <= 1;
			ioaddr <= 2'b00;
			rd_en <= 0;
			flag <= flag;
			data_flag <= 1;
		end
		else if (data_flag) begin
			iorw <= 1;
			ioaddr <= 2'b00;
			rd_en <= 0;
			flag <= flag;
			data_flag <= 0;
		end
		else if (~empty & ~flag & tbr) begin //read data from fifo
			iorw <= 1;
			ioaddr <= 2'b01;
			rd_en <= 1;
			flag <= 1;
			data_flag <= data_flag;
		end
		else if (flag & tbr) //send data
		begin
			iorw <= 0;
			ioaddr <= 2'b00;
			rd_en <= 0;
			flag <= 1;
			data_flag <= data_flag;
		end
		else //idle
		begin
			iorw <= 1;
			ioaddr <= 2'b01;
			rd_en <= 0;
			flag <= 0;
			data_flag <= data_flag;
		end
	end

reg [3:0] data_buffer[0:14];

		
always @(posedge clk)
	if (data_flag)
		data_buffer[databus[7:4]] <= databus[3:0];
	else
		data_buffer[databus[7:4]] <= data_buffer[databus[7:4]];
		
always @(posedge clk, posedge rst)
	if(rst)
		RCV <=0;
	else if (data_flag && databus[7:4] == 4'hf)
		RCV <= 1;
	else if (~|addr)
		RCV <=0;
	else
		RCV <= RCV;
		

assign GPIO = {data_buffer[0], data_buffer[1]};

always @(addr) 
	case (addr)
		3'h1: data_out = {12'h000, data_buffer[0]};
		3'h2: data_out = {data_buffer[1],data_buffer[2],data_buffer[3],data_buffer[4]};
		3'h3: data_out = {data_buffer[5],data_buffer[6],data_buffer[7],data_buffer[8]};
		3'h4: data_out = {data_buffer[9],data_buffer[10],data_buffer[11],data_buffer[12]};
		default: data_out = {8'h0,data_buffer[13],data_buffer[14]};
	endcase
endmodule
