module Flags(input clk, Z, OV, N, input[1:0] Mode, input [1:0] Update, output z_out, o_out, n_out);

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
		else begin
			Z_U <= (~Mode[1] & Update[1])? Z: Z_U;
			O_U <= (~Mode[1] & Update[0])? OV: O_U;
			N_U <= (~Mode[1] & Update[0])? N: N_U ;
			Z_I <= ( Mode[1] & Update[1])? Z: Z_I;
			O_I <= ( Mode[1] & Update[0])? OV: O_I;
			N_I <= ( Mode[1] & Update[0])? N: N_I;
		end
	end

// Output flags
assign z_out = (Mode[1]) ? Z_I : Z_U;
assign n_out = (Mode[1]) ? N_I : N_U;
assign o_out = (Mode[1]) ? O_I : O_U;

endmodule
