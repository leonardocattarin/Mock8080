`define		Test	4'b1100

module Main_Module	(	CLK_50M, //main clock
				SW, //switch
				BTN_SOUTH, BTN_EAST, BTN_NORTH, //buttons
				ROT_A, ROT_B, ROT_CENTER, //rotary knob sensors

				LCD_DB, LCD_E, LCD_RS, LCD_RW, //lcd connectors
				LED); 

/**************/
/*** Inputs ***/
/**************/
input		CLK_50M;
input	[3:0]	SW;

input 		BTN_SOUTH;
input 		BTN_NORTH;
input 		BTN_EAST;

input 		ROT_A;
input 		ROT_B; 
input 		ROT_CENTER;



/***************/
/*** Outputs ***/
/***************/
output	[7:0]	LCD_DB; //LCD data
output		LCD_E;
output		LCD_RS;
output		LCD_RW;

output	[7:0]	LED;

/**************/
/*** Wires ****/
/**************/

/*
wire w_pulse_wire;
wire w_direction;
wire w_stable_ROT_A;
wire w_stable_ROT_B;
*/

//wires for stabilized buttons
wire w_stable_BTN_EAST;
wire w_stable_BTN_NORTH;
wire w_stable_BTN_SOUTH;

//wires for CPU debugging
wire [3:0] w_dbg_CPU_reg;
wire [95:0] w_dbg_CPU;

//wires for RAM debugging
wire [7:0] w_dbg_addr_RAM;
wire [7:0] w_dbg_data_RAM;

//secondary clocks
wire w_custom_clk;
wire w_dbg_clk;

//buses for RAM-CPU interfaces
wire [7:0] w_data_addr; //data flag for reading/writing
wire 	w_data_write_flag ; //0:read, 1:write
wire [7:0] w_data_CPU_2_RAM;
wire [7:0] w_data_RAM_2_CPU;



/*** Assign and buffers for LCD functioning ***/
buf(LCD_RW, 0); // only writing on LCD
buf(LCD_DB[3:0], 4'b1111); //we use only 4-bit LCD interface

//Leds used for various debug purposes
buf(LED[7:0],w_dbg_addr_RAM);
//buf(LED[0],w_stable_BTN_EAST);




/************************/
/*** Modules for Knob ***/
/************************/
/*
//Two monostables for the knob inputs
Module_Monostable_enforced	monostable_knob_A (	.clk_in(CLK_50M),
					.monostable_input(ROT_A),
					.N(defaultN/8),

					.monostable_output(w_stable_ROT_A));

Module_Monostable_enforced	monostable_knob_B (	.clk_in(CLK_50M),
					.monostable_input(ROT_B),
					.N(defaultN/8),

					.monostable_output(w_stable_ROT_B));


//a driver which returns a rotation pulse and the direction
//1->clockwise, 0->counter-clockwise
module_knob_driver knob_driver (.qzt_clk(CLK_50M),
					.rot_A(w_stable_ROT_A),
					.rot_B(w_stable_ROT_B),

					.pulse(w_pulse_wire),
					.direction(w_direction));


// a "ladder" counter using the knob input
Module_SynchroCounter_8_bit_SR_bidirectional knob_counter	(	.qzt_clk(CLK_50M),
						.clk_in(w_pulse_wire),
						.reset(0),
						.set(0),
						.presetValue(0),
						.direction(w_direction),

						.out(w_dbg_addr_RAM));	
*/
	
/**********************************/
/*** 		LCD Driver 			***/
/**********************************/

//shows Debug info for RAM and CPU
//Datas are shown in Hex format
//CPU switchflag reference
/*
0000 -> PC
0001 -> IR
0010 -> ST
0011 -> W
0100 -> Z
0101 -> A
0110 -> B
0111 -> C
1000 -> SP
1001 -> Addr
1010 -> Data_out
1011 -> Data_in
*/
LCD_Driver_Dbg lcd_driver	(	.qzt_clk(CLK_50M),
					.switchFlag(SW[0]),

					//Ram interface
					.addrInput(w_dbg_addr_RAM),
                    .dataInput(w_dbg_data_RAM),

					//CPU interface
					.CPU_interface(w_dbg_CPU),
					.dbg_reg(w_dbg_CPU_reg),

					//Buses needed for the LCD
					.lcd_flags({LCD_RS, LCD_E}),
					.lcd_data(LCD_DB[7:4]));



/**********************************/
/*** 		Debug clock			***/
/**********************************/


Module_FrequencyDivider dbg_clk_gen	(	.clk_in(CLK_50M),
					.period(29'd25000), //1kHz?

					.clk_out(w_dbg_clk));




/******************************************/
/*** 		Counter	Modules for Debug 		***/
/******************************************/

Module_Ladder_8_bit_SR dbg_cpu_counter	(	.qzt_clk(CLK_50M),
						.clk_in(w_dbg_clk),
						.reset(0),
						.set(0),
						.presetValue(0),
						.limit(4'b1100),
						.pulse_up(w_stable_BTN_EAST & (!SW[0])),
						.pulse_down(w_stable_BTN_NORTH & (!SW[0])),

						.out(w_dbg_CPU_reg));	

Module_Ladder_8_bit_SR dbg_ram_counter	(	.qzt_clk(CLK_50M),
						.clk_in(w_dbg_clk),
						.reset(0),
						.set(0),
						.presetValue(0),
						.limit(8'b00000000),

						.pulse_up(w_stable_BTN_EAST & SW[0]),
						.pulse_down(w_stable_BTN_NORTH & SW[0]),

						.out(w_dbg_addr_RAM));	

/******************************************/
/*** 		Button Monostables 			***/
/******************************************/
Module_Monostable_enforced	Button_East_Monostable(	.clk_in(CLK_50M),
					.monostable_input(BTN_EAST),
					.N(defaultN*4),
					.monostable_output(w_stable_BTN_EAST));

Module_Monostable_enforced	Button_North_Monostable(	.clk_in(CLK_50M),
					.monostable_input(BTN_NORTH),
					.N(defaultN*4),
					.monostable_output(w_stable_BTN_NORTH));

Module_Monostable_enforced	Button_South_Monostable(	.clk_in(CLK_50M),
					.monostable_input(BTN_SOUTH),
					.N(defaultN*4),
					.monostable_output(w_stable_BTN_SOUTH));

/**********************************/
/*** 		RAM module 			***/
/**********************************/
Module_BRAM_256_byte RAM   (	.clk_qzt(CLK_50M),
					.dbg_clk(w_dbg_clk),
					.clk_in(w_stable_BTN_SOUTH),
					.en(1),
					
					//inputs from CPU
					.write_en(w_data_write_flag),
					.addr(w_data_addr),
					.data_in(w_data_CPU_2_RAM),

					//dbg input
					.dbg_addr(w_dbg_addr_RAM),

					//Data output from RAM to CPU
					.data_out(w_data_RAM_2_CPU),

					//dbg output
					.dbg_data_out(w_dbg_data_RAM));


/**********************************/
/*** 	...Finally, the CPU		***/
/**********************************/

Module_CPU Mock_CPU  (	.clk_qzt(CLK_50M),
					.dbg_clk(w_dbg_clk),
                    .clk_in(w_stable_BTN_SOUTH),

					.en(1),
					.reset(0),
					.res_addr(0),
					//data input from RAM (used after read query)
					.data_in(w_data_RAM_2_CPU),

					//data and addr output for RAM write
					.data_out(w_data_CPU_2_RAM),
					.data_addr(w_data_addr),
					.write_en(w_data_write_flag),

					//output debug interface
					.dbg_interface(w_dbg_CPU)
					);

endmodule
