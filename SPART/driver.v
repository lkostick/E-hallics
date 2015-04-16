module spart(input clk, input rst, output full, input send, input [7:0] data_in, output reg RCV, input [2:0] addr, output [15:0] data_out, output txd, input rxd);

	localparam BAUD_RATE = 8'ha2;
	
   wire empty, rda, tbr;
	reg rd_en, write;
	wire [7:0] send_data, read_data;
	reg [3:0] data_buffer[0:15];
	reg [7:0] Baud_Rate;

	FIFO iDUT(.clk(clk), .srst(rst), .din(data_in), .wr_en(send), .rd_en(rd_en), .dout(send_data), .full(full), .empty(empty));

	Transmit iTRAN(.TxD(txd), .TBR(tbr), .DATA(send_data), .clk(clk), .Enable(~|Baud_Rate), .write(write));

	Receive iRECE(.DATA(read_data), .RDA(rda), .RxD(rxd), .Enable(~|Baud_Rate), .clk(clk));	
	
	// Generate Baud rate, which is fixed at 38400
	always @(posedge clk)
		if ( ~|Baud_Rate ) Baud_Rate <= BAUD_RATE;
		else Baud_Rate <= Baud_Rate - 1;
	
	// Read FIFO if it is not empty
	always @(negedge clk)
		rd_en <= ~(empty | rd_en) & tbr;
		
	// One cycle after reading FIFO, data is ready, send it through Transmit
	always @(posedge clk)
		write <= rd_en;
	
	// Receive data, read it from Receive and set RCV signal
	always @(posedge clk)
		if (rda) begin
			data_buffer[read_data[7:4]] <= read_data[3:0];
			RCV <= &read_data[7:4];
		end
		else begin
			data_buffer[read_data[7:4]] <= data_buffer[read_data[7:4]];
			RCV <= ~|addr & RCV;
		end
	
	// Output data to CPU
	assign data_out = (addr == 3'h1) ? {12'h000, data_buffer[0]}:
							(addr == 3'h2) ? {data_buffer[1],data_buffer[2],data_buffer[3],data_buffer[4]}:
							(addr == 3'h3) ? {data_buffer[5],data_buffer[6],data_buffer[7],data_buffer[8]}:
							(addr == 3'h4) ? {data_buffer[9],data_buffer[10],data_buffer[11],data_buffer[12]}:
												  {8'h0,data_buffer[13],data_buffer[14]};
endmodule //spart