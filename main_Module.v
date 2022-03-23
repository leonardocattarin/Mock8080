`define		Test	4'b1100

module Main_Module	(	CLK_50M, 
				SW, 
				LED,
				BTN_SOUTH, BTN_EAST, BTN_NORTH,
				ROT_A, ROT_B, ROT_CENTER,

				LCD_DB, LCD_E, LCD_RS, LCD_RW,
				LED); 

/**************/
/*** Inputs ***/
/**************/
input		CLK_50M;

input 		BTN_SOUTH;
input 		BTN_NORTH;
input 		BTN_EAST;

input 		ROT_A;
input 		ROT_B; 
input 		ROT_CENTER;

input	[3:0]	SW;

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
wire [7:0] w_dbg_addr_RAM;
wire [7:0] w_dbg_data_RAM;
wire w_pulse_wire;
wire w_direction;
wire w_stable_ROT_A;
wire w_stable_ROT_B;
wire w_stable_BTN_EAST;
wire w_stable_BTN_NORTH;
wire w_stable_BTN_SOUTH;

//wire for choosing register visualization
wire [3:0] w_CPU_reg;

wire w_custom_clk;
wire w_dbg_clk;

wire [7:0] data_CPU_2_RAM;
wire [7:0] data_RAM_2_CPU;

wire [7:0] data_addr;
wire 	data_write_flag ;



/*** Assign and buffers ***/
buf(LCD_RW, 0); // only writing on LCD
buf(LCD_DB[3:0], 4'b1111); //we use only 4-bit LCD interface

//temp
buf(LED[7:1],0);
buf(LED[0],w_stable_BTN_EAST);




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
					.CPU_interface(96'd0),
					.dbg_reg(w_CPU_reg),
					//Buses needed for the LCD
					.lcd_flags({LCD_RS, LCD_E}),
					.lcd_data(LCD_DB[7:4]));


Module_FrequencyDivider custom_clk_gen	(	.clk_in(CLK_50M),
					.period(29'd100000000),

					.clk_out(custom_clk));




/******************************************/
/*** 	Module for Debug Register selection	***/
/******************************************/

Module_Ladder_8_bit_SR dbg_reg_counter	(	.qzt_clk(CLK_50M),
						.clk_in(dbg_clk),
						.reset(0),
						.set(0),
						.presetValue(0),
						.limit(4'b1100),
						.pulse_up(w_stable_BTN_EAST),
						.pulse_down(w_stable_BTN_NORTH),

						.out(w_CPU_reg));	

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
					.clk_in(custom_clk),
					.en(1),
					.write_en(data_write_flag),

					.addr(data_addr),
					.dbg_addr(w_dbg_addr_RAM),
					.data_in(data_CPU_2_RAM),

					.data_out(data_RAM_2_CPU),
					.dbg_data_out(w_dbg_data_RAM));


/**********************************/
/*** 	...Finally, the CPU		***/
/**********************************/

Module_CPU Mock_CPU  (	.clk_qzt(CLK_50M),
                    .clk_in(custom_clk),

					.en(1),
					.reset(0),
					.res_addr(0),
					.data_in(data_RAM_2_CPU),

					.data_out(data_CPU_2_RAM),
					.data_addr(data_addr),
					.write_en(data_write_flag)
					);

endmodule
