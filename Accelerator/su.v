module su(rst, clk, startSU, stopSU, writeSucceeded, key, writeReq);
input rst, clk;
input startSU, stopSU, writeSucceeded;
output reg[31:0] key;
output reg writeReq;

reg [1:0] state, nextstate;
localparam state0=2'b00;
localparam state1=2'b01;
localparam state2=2'b10;
localparam state3=2'b11;

always@(posedge clk, posedge rst)
	if (rst)
		state<=state0;
	else
		state<=nextstate;
/*reg count;
reg inccount;
always@(posedge clk, posedge rst)
	if (rst)
		count<=0;
	else if(inccount)
		count=count+1;
*/
always @ (*) begin
key=32'h00000000;
writeReq=0;
//inccount=0;
case (state)
	state0: 
		nextstate=state1;
	state1: 
		nextstate=state3;
	state2: 
		nextstate=state2;
	state3: begin
		writeReq=1;
		key=32'hF000000F;
		if(writeSucceeded==0) begin
			nextstate=state3;
			end
	//	else if(count ==0) begin
		//	nextstate = state3;
		//	inccount=1;
		//	end
		else	begin
			nextstate=state2;		
		//	inccount=1;
		end	
	end	
endcase

end

endmodule
