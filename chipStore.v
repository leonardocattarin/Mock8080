/*******************************/
/*** Module_FrequencyDivider ***/
/*******************************/

module	Module_FrequencyDivider	(	clk_in,
					period,

					clk_out);

input		clk_in;
input	[29:0]	period;

output		clk_out;

reg		clk_out;

reg	[29:0]	counter;

always @(posedge clk_in) begin
	if (counter >= (period - 1)) begin
		counter <= 0;
		clk_out <= ~clk_out;
	end else
		counter <= counter + 1;
end

endmodule

/****************************/
/*** Module_Counter_8_bit ***/
/****************************/

module	Module_Counter_8_bit	(	clk_in,
					limit,

					out,
					carry);

input		clk_in;
input	[7:0]	limit;

output	[7:0]	out;
output		carry;

reg	[7:0]	out;
reg		carry;

always @(posedge clk_in) begin
	if (out >= (limit - 8'b00000001)) begin
		out <= 0;
		carry <= 1;
	end else if (out == 0) begin
		out <= 1;
		carry <= 0;
	end else
		out <= out + 1;
end

endmodule

/**************************************/
/*** Module_SynchroCounter_8_bit_SR ***/
/**************************************/

module	Module_SynchroCounter_8_bit_SR	(	qzt_clk,
						clk_in,
						reset,
						set,
						presetValue,
						limit,

						out,
						carry);

input		qzt_clk;
input		clk_in;
input		reset;
input		set;
input	[7:0]	presetValue;
input	[7:0]	limit;

output	[7:0]	out;
output		carry;

reg	[7:0]	out;
reg		carry;

reg		clk_in_old;


always @(posedge qzt_clk) begin
	if (reset) begin
		out <= 0;
		carry <= 0;
	end else if (set) begin
		out <= presetValue;
		carry <= 0;
	end else if (!clk_in_old & clk_in) begin
		if (out >= (limit - 8'b00000001)) begin
			out <= 0;
			carry <= 1;
		end else if (out == 0) begin
			out <= 1;
			carry <= 0;
		end else
			out <= out + 1;
	end

	clk_in_old <= clk_in;
end

endmodule




/**************************************/
/*** Module_Ladder_8_bit_SR ***/
/**************************************/

module	Module_Ladder_8_bit_SR	(	qzt_clk,
						clk_in,
						pulse_up,
						pulse_down,
						reset,
						set,
						presetValue,
						limit,

						out,
						carry);

input		qzt_clk;
input		clk_in;
input		pulse_up;
input		pulse_down;
input		reset;
input		set;
input	[7:0]	presetValue;
input	[7:0]	limit;

output	[7:0]	out;
output		carry;

reg	[7:0]	out;
reg		carry;

reg		clk_in_old;
reg 	pulse_down_old;
reg 	pulse_up_old ;


always @(posedge qzt_clk) begin
	if (reset) begin
		out <= 0;
		carry <= 0;
	end else if (set) begin
		out <= presetValue;
		carry <= 0;
	end else if (!clk_in_old & clk_in) begin

		if (pulse_up && !pulse_up_old) begin
			if (out >= (limit - 8'b00000001)) begin
				out <= 0;
				carry <= 1;
			end else begin
				out <= out + 1;
			end
		end

		if (pulse_down && !pulse_down_old) begin
			if (out == 0) begin
				out <= limit - 8'b00000001;
			end else begin
				out <= out - 1;
			end
		end

		if(carry)
			carry<=0;
		
		pulse_down_old <= pulse_down;
		pulse_up_old <= pulse_up;

	end

	clk_in_old <= clk_in;
end

endmodule





/*********************************************/
/*** Module_Multiplexer_2_input_8_bit_sync ***/
/*********************************************/

module	Module_Multiplexer_2_input_8_bit_sync	(	clk_in,
							address,
							input_0,
							input_1,

							mux_output);

input		clk_in;
input		address;
input	[7:0]	input_0;
input	[7:0]	input_1;

output	[7:0]	mux_output;

reg	[7:0]	mux_output;

always @(posedge clk_in) begin
	mux_output <= (address)? input_1 : input_0;
end

endmodule

/*****************************/
/*** Module_MonostableHold ***/
/*****************************/

`define		defaultN 	28'b0000000011110100001001000000	//	10^6 ===> 20 ms

module Module_Monostable	(	clk_in,
					monostable_input,
					N,

					monostable_output);

input		clk_in;
input		monostable_input;
input	[27:0]	N;

output		monostable_output;

reg		monostable_output;

reg		monostable_input_old;
reg 	[27:0]	counter;

always @(posedge clk_in) begin
	if (counter == 0) begin
		if (!monostable_input_old & monostable_input) begin
			counter <= ((N)? N : `defaultN) - 1;
			monostable_output <= 1;
		end else
			monostable_output <= 0;
	end else
		counter <= counter - 1;

	monostable_input_old <= monostable_input;
end

endmodule

/*****************************/
/*** Module_Monostable_enforced ***/
/*****************************/
//implements debouncing also for button risetime

`define		defaultN 	28'b0000000011110100001001000000	//	10^6 ===> 20 ms

module Module_Monostable_enforced	(	clk_in,
					monostable_input,
					N,

					monostable_output);

input		clk_in;
input		monostable_input;
input	[27:0]	N;

output		monostable_output;

reg		monostable_output;

reg		monostable_input_old;
reg 	[27:0]	counter;

always @(posedge clk_in) begin
	if (counter == 0) begin
		if (!monostable_input_old & monostable_input) begin
			counter <= ((N)? N : `defaultN) - 1;
			monostable_output <= 1;
		end else
			monostable_output <= 0;
	end else if(monostable_input)begin
		counter <= ((N)? N : `defaultN) - 1;
	end else
		counter <= counter - 1;
	monostable_input_old <= monostable_input;
end

endmodule

/**********************************/
/*** Module_ToggleFlipFlop_sync ***/
/**********************************/

module Module_ToggleFlipFlop	(	clk_in,
					ff_input,

					ff_output);

input		clk_in;
input		ff_input;

output		ff_output;

reg		ff_output;

reg		ff_input_previous;

always @(posedge clk_in) begin
	if (!ff_input_previous & ff_input) begin
		ff_output <= ~ff_output;
	end

	ff_input_previous <= ff_input;
end

endmodule

/***************************/
/*** Module_Latch_16_bit ***/
/***************************/

module	Module_Latch_16_bit	(	clk_in,
					holdFlag,
					twoByteInput,

					twoByteOuput);

input		clk_in;
input		holdFlag;
input	[15:0]	twoByteInput;

output	[15:0]	twoByteOuput;

reg	[15:0]	twoByteOuput;


always @(posedge clk_in) begin
	if (!holdFlag) twoByteOuput <= twoByteInput;
end

endmodule




