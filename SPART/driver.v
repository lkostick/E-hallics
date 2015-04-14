module driver(input clk, input rst, output reg iorw, input rda, input tbr, output reg [1:0] ioaddr, inout [7:0] databus, output full, input send, input [7:0] data_in, output reg RCV, input [2:0] addr, output [15:0] data_out );


   wire empty;
	reg rd_en, flag;
	wire [7:0] send_data;

	assign databus = (iorw) ? 8'hzz : send_data;

	FIFO iDUT(.clk(clk), .srst(rst), .din(data_in), .wr_en(send), .rd_en(rd_en), .dout(send_data), .full(full), .empty(empty));

	always @(negedge clk)
			rd_en <= ~(empty | rd_en | rda) & tbr;
			
	always @(*) begin
		iorw = ~flag;
		ioaddr = {2{~(rda|flag)}};
	end
	
	always @(posedge clk)
		flag <= rd_en;

	reg [3:0] data_buffer[0:15];

		
	always @(posedge clk)
		if (rda & iorw)
			data_buffer[databus[7:4]] <= databus[3:0];
		else
			data_buffer[databus[7:4]] <= data_buffer[databus[7:4]];
		
	always @(posedge clk)
		if (rda & iorw)
			RCV <= &databus[7:4];
		else if (|addr)
			RCV <=0;
		else
			RCV <= RCV;

	assign data_out = (addr == 3'h1) ? {12'h000, data_buffer[0]}:
							(addr == 3'h2) ? {data_buffer[1],data_buffer[2],data_buffer[3],data_buffer[4]}:
							(addr == 3'h3) ? {data_buffer[5],data_buffer[6],data_buffer[7],data_buffer[8]}:
							(addr == 3'h4) ? {data_buffer[9],data_buffer[10],data_buffer[11],data_buffer[12]}:
							{8'h0,data_buffer[13],data_buffer[14]};
endmodule
