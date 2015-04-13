module Flags(input clk, Z, OV, N, input[1:0] Mode, input [1:0] Update, output reg z_out, ov_out, n_out);

//two sets of flags, one used in interruption handler and one used in user
//mode
//Flags used in interruption handler will be reset when mode resume to user

reg Z_I, O_I, N_I, Z_U, O_U, N_U;

// update flags
	always @(posedge clk) begin
		if (~|Mode) begin
			Z_I <= 0;
			O_I <= 0;
			N_I <= 0;
			Z_U <= 0;
			O_U <= 0;
			N_U <= 0;
		end
		else if (Mode == 2'b01) begin
			Z_U <= (Update[1])? Z: Z_U;
			O_U <= (Update[0])? OV: O_U;
			N_U <= (Update[0])? N: N_U ;
			Z_I <= 0;
			O_I <= 0;
			N_I <= 0;
		end
		else begin
			Z_U <= Z_U;
			O_U <= O_U;
			N_U <= N_U;
			Z_I <= (Update[1])? Z: Z_I;
			O_I <= (Update[0])? OV: O_I;
			N_I <= (Update[0])? N: N_I ;
		end
	end

// Output flags
always @(*) begin
	if (Mode == 2'b01) begin
		z_out = Z_U;
		ov_out = O_U;
		n_out = N_U;
	end
	else begin
		z_out = Z_I;
		ov_out = O_I;
		n_out = N_I;
	end
end
endmodule
