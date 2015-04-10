module accelerator_control(clk, rst, control, address, data, pckeydata, pckeyaddr, startLC, dataToProc, dataToLC, levels, stop);
input clk, rst;
input[1:0] control;//00 do nothing, 01 start, 10 read, 11 stop
input[4:0] address;// cipher text buffer(lower4bit), performance count 1, 2, 3, and key upper 16 & lower 16
input[15:0] data;//data from processor
input[15:0] pckeydata;//data from pereformance count or keybuffer
output reg[3:0] pckeyaddr;
output reg startLC;
output reg[15:0] dataToProc;
output reg[63:0] dataToLC;
output reg[2:0] levels;//level count for loading cipher text	
output reg stop;
reg [15:0] buffer [0:15];//cipher text buffer

//for control
localparam start = 2'b01;
localparam read = 2'b10;
localparam found =2'b11;

reg[2:0] state, nextstate;
localparam idle=3'b000;
localparam fillbuffer=3'b001;
localparam loadlevel=3'b010;
localparam sendback=3'b011;
localparam stopstate=3'b100;

always@(posedge clk, posedge rst)
	if (rst)
		state<=idle;
	else
		state<=nextstate;

reg inclevel;	
always@(posedge clk, posedge rst)
	if (rst)		
		levels<=3'b000;
	else if (inclevel ==1)
		levels<=levels+3'b001;

//check if buffer is filled with cipher text
reg incbuff;
reg[4:0]buffcount;
always@(posedge clk, posedge rst)
	if(rst)
		buffcount<=0;
	else if(incbuff)
		buffcount<=buffcount+5'b00001;

		
always@(*) begin
startLC=0;
stop=0;
inclevel=0;
incbuff=0;
case(state)
	idle:	begin
		if(control==start)
			nextstate=fillbuffer;
		else if (control==found) begin
			stop=1;
			nextstate=stopstate;
		end
		else if (control == read) begin
			nextstate= sendback;
			pckeyaddr=address[3:0];
		end	
		else
			nextstate=idle;
	end
	fillbuffer: begin
		if(buffcount>5'b01111)
			nextstate=loadlevel;
		else begin
			buffer[address[3:0]]=data;
			nextstate=fillbuffer;
		end
		incbuff=1;
	end	
	loadlevel: begin
		if(levels>3'b011)
			nextstate=idle;	
		else begin
			startLC=1;
			dataToLC={buffer[{levels[1:0],2'b00}],buffer[{levels[1:0],2'b01}],buffer[{levels[1:0],2'b10}],buffer[{levels[1:0],2'b11}]};
			nextstate=loadlevel;
		end
		inclevel=1;
	end
		
	sendback: begin
		dataToProc=pckeydata;
		nextstate=idle;
	end
	stopstate: begin
		stop=1;
		nextstate=stopstate;
	end	
	default:
		nextstate=idle;
endcase
end

endmodule
