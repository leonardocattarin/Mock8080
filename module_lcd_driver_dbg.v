`define		R_upper	4'b0101
`define		R_lower	4'b0010

`define		M_upper	4'b0100
`define		M_lower	4'b1101

`define		C_upper	4'b0100
`define		C_lower	4'b0011

`define		P_upper	4'b0101
`define		P_lower	4'b0000

`define		I_upper	4'b0100
`define		I_lower	4'b1001

`define		S_upper	4'b0101
`define		S_lower	4'b0011

`define		T_upper	4'b0101
`define		T_lower	4'b0100

`define		W_upper	4'b0101
`define		W_lower	4'b0111

`define		Z_upper	4'b0101
`define		Z_lower	4'b1010

`define		A_upper	4'b0100
`define		A_lower	4'b0001

`define		B_upper	4'b0100
`define		B_lower	4'b0010

`define		T_upper	4'b0101
`define		T_lower	4'b0100

`define		EMPTY_upper	4'b0010
`define		EMPTY_lower	4'b0000

`define		D_upper	4'b0100
`define		D_lower	4'b0100

`define		O_upper	4'b0100
`define		O_lower	4'b1111


module	LCD_Driver_Dbg	(	qzt_clk,
					addrInput,
                    dataInput,

					switchFlag,

					CPU_interface,
					dbg_reg_addr,

					lcd_flags,
					lcd_data);

/*****************************/
/*      	Input			 */
/*****************************/
input		qzt_clk;
input	[7:0]	addrInput;
input	[7:0]	dataInput;
input		switchFlag;
input	[95:0]	CPU_interface;
input 	[3:0]	dbg_reg_addr;

/*****************************/
/*      	Output		 */
/*****************************/

output	[1:0]	lcd_flags;
output	[3:0]	lcd_data;

/*****************************/
/*      	Registers		 */
/*****************************/


reg	[1:0]	lcd_flags;
reg	[3:0]	lcd_data;

reg	[1:0]	initializeLabel = 2'b01; //state variable for inizialization phases
reg	[21:0]	counter;

always @(posedge qzt_clk) begin
	/*************************/
    // POWER-ON INITIALIZATION
	/*************************/

	if (initializeLabel == 2'b01) begin
		// after at least 2000 clock cycles (see 23 lines below), jump to next operation
		if (counter[19:0] == 20'b11111000000000000000) begin		// 1015808 = prev + 32720;	step #9
			initializeLabel = 2'b10;
			counter = 0;
		end else begin
			case (counter[19:0])
				// after at least 750000 clock cycles...
				20'b10111000000000000000: lcd_data = 4'b0011;	// 753664;			step #1, 2 
				20'b10111000000000010000: lcd_flags = 2'b01;	// 753680 = previous + 16;	step #2
				20'b10111000000000100000: lcd_flags = 2'b00;	// 753696 = previous + 16;	step #2

				// after at least 205000 clock cycles...
				20'b11101100000000000000: lcd_flags = 2'b01;	// 966656 = previous + 212960;	step #3, 4
				20'b11101100000000010000: lcd_flags = 2'b00;	// 966672 = previous + 16;	step #4

				// after at least 5000 clock cycles...
				20'b11101110000000000000: lcd_flags = 2'b01;	// 974848 = previous + 8176;	step #5, 6
				20'b11101110000000010000: lcd_flags = 2'b00;	// 974864 = previous + 16;	step #6

				// after at least 2000 clock cycles...
				20'b11110000000000000000: lcd_data = 4'b0010;	// 983040 = previous + 8176;	step #7, 8
				20'b11110000000000010000: lcd_flags = 2'b01;	// 983056 = previous + 16;	step #8
				20'b11110000000000100000: lcd_flags = 2'b00;	// 983072 = previous + 16;	step #8
				20'b11110000000000110000: lcd_data = 4'b0000;	// 983088 = previous + 16;	step #8
			endcase
			counter = counter + 1;
		end

		/**************************************/
		// DISPLAY CONFIGURATION (COMMAND PART)
		/**************************************/
	end else if (initializeLabel == 2'b10) begin
		// when done (see 25 lines below)...
		if (counter[13:0] == 14'b11111111111111) begin
			initializeLabel = 2'b11;
			counter = 0;
		end else begin
			case (counter[11:0])
				// upper nimble
				12'b000000000000:			// prepare data bus
					case (counter[13:12])
						0: lcd_data = 4'b0010;		// 2 @ "FUNCTION SET" command
						default: lcd_data = 4'b0000;	// 0 @ other commands
					endcase
				//set and de-set write en for upper nimble after 16 cycles
				12'b000000010000: lcd_flags = 2'b01;	// command_write enable
				12'b000000100000: lcd_flags = 2'b00;	// command_write disable

				// lower nimble
				// note: lower nimble is sent after 32+64=96 clock cycles from the upper
				12'b000001100000:			// prepare data bus
					case (counter[13:12])
						0: lcd_data = 4'b1000;		// 2 @ "FUNCTION SET" command
						1: lcd_data = 4'b0110;		// 2 @ "ENTRY MODE SET" command: I/D=1 ==> "Auto-increment address counter. Cursor/blink moves to right"; S=0 ==> "shifting disabled"
						2: lcd_data = 4'b1100;		// 2 @ "DISPLAY ON/OFF" command: D=1 ==> "Display characters stored in DD RAM"; C=0 ==> "No cursor"; B=0 ==> "No cursor blinking"
						3: lcd_data = 4'b0001;		// 2 @ "CLEAR DISPLAY" command
					endcase
				// note: after 16 cycles of lower nimble, send write en pulse 
				12'b000001110000: lcd_flags = 2'b01;	// command_write enable

				// note: after 16 cycles of up, set write en low 
				12'b000010000000: lcd_flags = 2'b00;	// command_write disable

				//after each command
				12'b111111111111: lcd_data = 0;		// clear data bus
			endcase
			counter = counter + 1;
		end
	/***********************************/
	// DISPLAY CONFIGURATION (SLEEP PART)
	/***********************************/

	end else if (initializeLabel == 2'b11) begin
		// after at least 82000 clock cycles, jump to next operation
		if (counter[16:0] == 17'b11000000000000000) begin	// 98304
			initializeLabel = 2'b00;
			counter = 0;
		end else begin
			counter = counter + 1;
		end
	end else begin
		/*************************/
		// WRITING DATA TO DISPLAY
		/*************************/
		//NOTE: bit 20-15 are just a requirement for getting to writing phase
		//bit 14-12 correspond to different commands (e.g. different characters)
		//bit 11-0 are needed for correct command timing
		//NOTE : to execute next commands must have passed 2^20+2^19+2^18+2^17+2^16+2^15 cycles (around 20 ms?)
		if (counter[20:16] == 5'b11111) begin
			
			if (counter[15:12] == 0) begin
					case (counter[11:0])
						// upper nimble

						//1-prepare data bus
						12'b000000000000: lcd_data = 4'b1000;	
						//2-command_write enable
						12'b000000010000: lcd_flags = 2'b01;	
						//3-command_write disable
						12'b000000100000: lcd_flags = 2'b00;	

						// lower nimble

						//1-prepare data bus
						12'b000001100000: lcd_data = 4'b0000;	
						//2-command_write enable
						12'b000001110000: lcd_flags = 2'b01;	
						//3-command_write disable
						12'b000010000000: lcd_flags = 2'b00;	
						//4-clear data bus 
						12'b111111111111: lcd_data = 0;		
					endcase
			end  else if (switchFlag) begin
				/************************/
				//switchflag = 1 RAM Debug
				/************************/
				
				// "Write Data to CG RAM or DD RAM" command (address is set to 0)
				 if (counter[15:12] <= 4'b0111) begin
					case (counter[11:0])
						// upper nimble
						12'b000000000000:
							case (counter[15:12])

								//second data char
								4'b1000: if (dataInput[3:0] <= 4'b1001) 
										lcd_data = 4'b0011;
									else 
										lcd_data = 4'b0100;

								//first data char
								4'b0111: if (dataInput[7:4] <= 4'b1001) 
										lcd_data = 4'b0011;
									else 
										lcd_data = 4'b0100;
							
								//space
								4'b0110: lcd_data = 4'b0010;

								//second addr char
								4'b0101: if (addrInput[3:0] <= 4'b1001) 
										lcd_data = 4'b0011;
									else 
										lcd_data = 4'b0100;
								//first addr char
								4'b0100: if (addrInput[7:4] <= 4'b1001) 
										lcd_data = 4'b0011;
									else 
										lcd_data = 4'b0100;

								//Space
								4'b0011: lcd_data = 4'b0010;

								//Char M
								4'b0010: 
										lcd_data = `M_upper;
								//Char R
								4'b0001: 
										lcd_data = `R_upper;
	
								default: lcd_data = 4'b0010;
							endcase
						12'b000000010000: lcd_flags = 2'b11;	// data_write enable
						12'b000000100000: lcd_flags = 2'b00;	// data_write disable

						// lower nimble
						12'b000001100000:
							case (counter[15:12])
								//second data char
								4'b1000: begin 
									if (dataInput[3:0] <= 4'b1001)
										lcd_data = dataInput[3:0];
									else 
										lcd_data = dataInput[3:0] - 4'b1001;

									//restart writing procedure
									counter[15:12] = 0;
								end
								//first data char
								4'b0111: if (dataInput[7:4] <= 4'b1001) 
										lcd_data = dataInput[7:4];
									else 
										lcd_data = dataInput[7:4] - 4'b1001;
							
								//Space
								4'b0110: lcd_data = 4'b0000;

								//Second addr Char
								4'b0101: if (addrInput[3:0] <= 4'b1001) 
										lcd_data = addrInput[3:0];
									else 
										lcd_data = addrInput[3:0] - 4'b1001;

								//First addr char
								4'b0100: if (addrInput[7:4] <= 4'b1001) 
										lcd_data = addrInput[7:4];
									else 
										lcd_data = addrInput[7:4] - 4'b1001;

								//Space
								4'b0011: lcd_data = 4'b0010;

								//Char M
								4'b0010: 
										lcd_data = `M_lower;
								//Char R
								4'b0001: 
										lcd_data = `R_lower;
										
								default: lcd_data = 4'b0000;
							endcase
						12'b000001110000: lcd_flags = 2'b11;	// data_write enable
						12'b000010000000: lcd_flags = 2'b00;	// data_write disable
						12'b111111111111: lcd_data = 0;		// clear data bus
					endcase
				end
				
			end else begin
				/************************/
				//switchflag = 0 CPU Debug
				/************************/

				// "Write Data to CG RAM or DD RAM" command (address is set to 0)
				 if (counter[15:12] <= 4'b0111) begin
					case (counter[11:0])
						// upper nimble
						12'b000000000000:
							case (counter[15:12])

								//Second Data char
								4'b1000: case(dbg_reg_addr)
										4'b1011://DI (data in)
											if (CPU_interface[91:88] <= 4'b1001) 
												lcd_data = 4'b0011;
											else 
												lcd_data = 4'b0100;
										4'b1010://DO (data out)
											if (CPU_interface[83:80] <= 4'b1001) 
												lcd_data = 4'b0011;
											else 
												lcd_data = 4'b0100;
										4'b1001://AD (address)
											if (CPU_interface[75:72] <= 4'b1001) 
												lcd_data = 4'b0011;
											else 
												lcd_data = 4'b0100;
										4'b1000://SP
											if (CPU_interface[67:64] <= 4'b1001) 
												lcd_data = 4'b0011;
											else 
												lcd_data = 4'b0100;
										4'b0111://C
											if (CPU_interface[59:56] <= 4'b1001) 
												lcd_data = 4'b0011;
											else 
												lcd_data = 4'b0100;
										4'b0110://B
											if (CPU_interface[51:48] <= 4'b1001) 
												lcd_data = 4'b0011;
											else 
												lcd_data = 4'b0100;
										4'b0101://A
											if (CPU_interface[43:40] <= 4'b1001) 
												lcd_data = 4'b0011;
											else 
												lcd_data = 4'b0100;
										4'b0100://Z
											if (CPU_interface[35:32] <= 4'b1001) 
												lcd_data = 4'b0011;
											else 
												lcd_data = 4'b0100;
										4'b0011://W
											if (CPU_interface[27:24] <= 4'b1001) 
												lcd_data = 4'b0011;
											else 
												lcd_data = 4'b0100;
										4'b0010://ST
											if (CPU_interface[19:16] <= 4'b1001) 
													lcd_data = 4'b0011;
												else 
													lcd_data = 4'b0100;
										4'b0001://IR
											if (CPU_interface[11:8] <= 4'b1001) 
											lcd_data = 4'b0011;
												else 
											lcd_data = 4'b0100;
										4'b0000://PC
											if (CPU_interface[3:0] <= 4'b1001) 
												lcd_data = 4'b0011;
											else 
												lcd_data = 4'b0100;
								endcase

								//first Data char
								4'b0111: case(dbg_reg_addr)
										4'b1011://DI (data in)
											if (CPU_interface[95:92] <= 4'b1001) 
												lcd_data = 4'b0011;
											else 
												lcd_data = 4'b0100;
										4'b1010://DO (data out)
											if (CPU_interface[87:84] <= 4'b1001) 
												lcd_data = 4'b0011;
											else 
												lcd_data = 4'b0100;
										4'b1001://AD (address)
											if (CPU_interface[79:76] <= 4'b1001) 
												lcd_data = 4'b0011;
											else 
												lcd_data = 4'b0100;
										4'b1000://SP
											if (CPU_interface[71:68] <= 4'b1001) 
												lcd_data = 4'b0011;
											else 
												lcd_data = 4'b0100;
										4'b0111://C
											if (CPU_interface[63:60] <= 4'b1001) 
												lcd_data = 4'b0011;
											else 
												lcd_data = 4'b0100;
										4'b0110://B
											if (CPU_interface[55:52] <= 4'b1001) 
												lcd_data = 4'b0011;
											else 
												lcd_data = 4'b0100;
										4'b0101://A
											if (CPU_interface[47:44] <= 4'b1001) 
												lcd_data = 4'b0011;
											else 
												lcd_data = 4'b0100;
										4'b0100://Z
											if (CPU_interface[39:36] <= 4'b1001) 
												lcd_data = 4'b0011;
											else 
												lcd_data = 4'b0100;
										4'b0011://W
											if (CPU_interface[31:28] <= 4'b1001) 
												lcd_data = 4'b0011;
											else 
												lcd_data = 4'b0100;
										4'b0010://ST
											if (CPU_interface[23:20] <= 4'b1001) 
													lcd_data = 4'b0011;
												else 
													lcd_data = 4'b0100;
										4'b0001://IR
											if (CPU_interface[15:12] <= 4'b1001) 
											lcd_data = 4'b0011;
												else 
											lcd_data = 4'b0100;
										4'b0000://PC
											if (CPU_interface[7:4] <= 4'b1001) 
												lcd_data = 4'b0011;
											else 
												lcd_data = 4'b0100;
								endcase

								//space
								4'b0110: lcd_data = `EMPTY_upper;

								//second Reg Name char
								4'b0101: case(dbg_reg_addr)
										4'b1011:lcd_data = `I_upper;//DI (data in)
										4'b1010:lcd_data = `O_upper;//DO (data out)
										4'b1001:lcd_data = `D_upper;//AD (address)
										4'b1000:lcd_data = `P_upper;//SP
										4'b0111:lcd_data = `EMPTY_upper;//C
										4'b0110:lcd_data = `EMPTY_upper;//B
										4'b0101:lcd_data = `EMPTY_upper;//A
										4'b0100:lcd_data = `EMPTY_upper;//Z
										4'b0011:lcd_data = `EMPTY_upper;//W
										4'b0010:lcd_data = `T_upper;//ST
										4'b0001:lcd_data = `R_upper;//IR
										4'b0000:lcd_data = `C_upper;//PC
								endcase

								//first Reg Name char
								4'b0100: case(dbg_reg_addr)
										4'b1011:lcd_data = `D_upper;//DI (data in)
										4'b1010:lcd_data = `D_upper;//DO (data out)
										4'b1001:lcd_data = `A_upper;//AD (address)
										4'b1000:lcd_data = `S_upper;//SP
										4'b0111:lcd_data = `C_upper;//C
										4'b0110:lcd_data = `B_upper;//B
										4'b0101:lcd_data = `A_upper;//A
										4'b0100:lcd_data = `Z_upper;//Z
										4'b0011:lcd_data = `W_upper;//W
										4'b0010:lcd_data = `S_upper;//ST
										4'b0001:lcd_data = `I_upper;//IR
										4'b0000:lcd_data = `P_upper;//PC
								endcase
										
										
								//Space
								4'b0011: lcd_data = `EMPTY_upper;

								//Char P
								4'b0010: 
										lcd_data = `P_upper;
								//Char C
								4'b0001: 
										lcd_data = `C_upper;
	
								default: lcd_data = 4'b0010;
							endcase
						12'b000000010000: lcd_flags = 2'b11;	// data_write enable
						12'b000000100000: lcd_flags = 2'b00;	// data_write disable

						// lower nimble
						12'b000001100000:
							case (counter[15:12])


								//Second Data char
								4'b1000: begin
											case(dbg_reg_addr)
											4'b1011://DI (data in)
												if (CPU_interface[91:88] <= 4'b1001) 
													lcd_data = CPU_interface[91:88];
												else 
													lcd_data = CPU_interface[91:88] - 4'b1001;
											4'b1010://DO (data out)
												if (CPU_interface[83:80] <= 4'b1001) 
													lcd_data = CPU_interface[83:80];
												else 
													lcd_data = CPU_interface[83:80] - 4'b1001;
											4'b1001://AD (address)
												if (CPU_interface[75:72] <= 4'b1001) 
													lcd_data = CPU_interface[75:72];
												else 
													lcd_data = CPU_interface[75:72] - 4'b1001;
											4'b1000://SP
												if (CPU_interface[67:64] <= 4'b1001) 
													lcd_data = CPU_interface[67:64];
												else 
													lcd_data = CPU_interface[67:64] - 4'b1001;
											4'b0111://C
												if (CPU_interface[59:56] <= 4'b1001) 
													lcd_data = CPU_interface[59:56];
												else 
													lcd_data = CPU_interface[59:56] - 4'b1001;
											4'b0110://B
												if (CPU_interface[51:48] <= 4'b1001) 
													lcd_data = CPU_interface[51:48];
												else 
													lcd_data = CPU_interface[51:48] - 4'b1001;
											4'b0101://A
												if (CPU_interface[43:40] <= 4'b1001) 
													lcd_data = CPU_interface[43:40];
												else 
													lcd_data = CPU_interface[43:40] - 4'b1001;
											4'b0100://Z
												if (CPU_interface[35:32] <= 4'b1001) 
													lcd_data = CPU_interface[35:32];
												else 
													lcd_data = CPU_interface[35:32] - 4'b1001;
											4'b0011://W
												if (CPU_interface[27:24] <= 4'b1001) 
													lcd_data = CPU_interface[27:24];
												else 
													lcd_data = CPU_interface[27:24] - 4'b1001;
											4'b0010://ST
												if (CPU_interface[19:16] <= 4'b1001) 
													lcd_data = CPU_interface[19:16];
												else 
													lcd_data = CPU_interface[19:16] - 4'b1001;
											4'b0001://IR
												if (CPU_interface[11:8] <= 4'b1001) 
													lcd_data = CPU_interface[11:8];
												else 
													lcd_data = CPU_interface[11:8] - 4'b1001;
											4'b0000://PC
												if (CPU_interface[3:0] <= 4'b1001) 
													lcd_data = CPU_interface[3:0];
												else 
													lcd_data = CPU_interface[3:0] - 4'b1001;
											
									endcase
								counter[15:12] = 0;
				 				end

								//first Data char
								4'b0111: case(dbg_reg_addr)
										4'b1011://DI (data in)
											if (CPU_interface[95:92] <= 4'b1001) 
												lcd_data = CPU_interface[95:92];
											else 
												lcd_data = CPU_interface[95:92] - 4'b1001;
										4'b1010://DO (data out)
											if (CPU_interface[87:84] <= 4'b1001) 
												lcd_data = CPU_interface[87:84];
											else 
												lcd_data = CPU_interface[87:84] - 4'b1001;
										4'b1001://AD (address)
											if (CPU_interface[79:76] <= 4'b1001) 
												lcd_data = CPU_interface[79:76];
											else 
												lcd_data = CPU_interface[79:76] - 4'b1001;
										4'b1000://SP
											if (CPU_interface[71:68] <= 4'b1001) 
												lcd_data = CPU_interface[71:68];
											else 
												lcd_data = CPU_interface[71:68] - 4'b1001;
										4'b0111://C
											if (CPU_interface[63:60] <= 4'b1001) 
												lcd_data = CPU_interface[63:60];
											else 
												lcd_data = CPU_interface[63:60] - 4'b1001;
										4'b0110://B
											if (CPU_interface[55:52] <= 4'b1001) 
												lcd_data = CPU_interface[55:52];
											else 
												lcd_data = CPU_interface[55:52] - 4'b1001;
										4'b0101://A
											if (CPU_interface[47:44] <= 4'b1001) 
												lcd_data = CPU_interface[47:44];
											else 
												lcd_data = CPU_interface[47:44] - 4'b1001;
										4'b0100://Z
											if (CPU_interface[39:36] <= 4'b1001) 
												lcd_data = CPU_interface[39:36];
											else 
												lcd_data = CPU_interface[39:36] - 4'b1001;
										4'b0011://W
											if (CPU_interface[31:28] <= 4'b1001) 
												lcd_data = CPU_interface[31:28];
											else 
												lcd_data = CPU_interface[31:28] - 4'b1001;
										4'b0010://ST
											if (CPU_interface[23:20] <= 4'b1001) 
												lcd_data = CPU_interface[23:20];
											else 
												lcd_data = CPU_interface[23:20] - 4'b1001;
										4'b0001://IR
											if (CPU_interface[15:12] <= 4'b1001) 
												lcd_data = CPU_interface[15:12];
											else 
												lcd_data = CPU_interface[15:12] - 4'b1001;
										4'b0000://PC
											if (CPU_interface[7:4] <= 4'b1001) 
												lcd_data = CPU_interface[7:4];
											else 
												lcd_data = CPU_interface[7:4] - 4'b1001;
								endcase

								

								//Space
								4'b0110: lcd_data = `EMPTY_lower;

								//second Reg Name char
								4'b0101: case(dbg_reg_addr)
										4'b1011:lcd_data = `I_lower;//DI (data in)
										4'b1010:lcd_data = `O_lower;//DO (data out)
										4'b1001:lcd_data = `D_lower;//AD (address)
										4'b1000:lcd_data = `P_lower;//SP
										4'b0111:lcd_data = `EMPTY_lower;//C
										4'b0110:lcd_data = `EMPTY_lower;//B
										4'b0101:lcd_data = `EMPTY_lower;//A
										4'b0100:lcd_data = `EMPTY_lower;//Z
										4'b0011:lcd_data = `EMPTY_lower;//W
										4'b0010:lcd_data = `T_lower;//ST
										4'b0001:lcd_data = `R_lower;//IR
										4'b0000:lcd_data = `C_lower;//PC
								endcase

								//first Reg Name char
								4'b0100: case(dbg_reg_addr)
										4'b1011:lcd_data = `D_lower;//DI (data in)
										4'b1010:lcd_data = `D_lower;//DO (data out)
										4'b1001:lcd_data = `A_lower;//AD (address)
										4'b1000:lcd_data = `S_lower;//SP
										4'b0111:lcd_data = `C_lower;//C
										4'b0110:lcd_data = `B_lower;//B
										4'b0101:lcd_data = `A_lower;//A
										4'b0100:lcd_data = `Z_lower;//Z
										4'b0011:lcd_data = `W_lower;//W
										4'b0010:lcd_data = `S_lower;//ST
										4'b0001:lcd_data = `I_lower;//IR
										4'b0000:lcd_data = `P_lower;//PC
								endcase
										
										
								//Space
								4'b0011: lcd_data = `EMPTY_lower;

								//Char P
								4'b0010: 
										lcd_data = `P_lower;
								//Char C
								4'b0001: 
										lcd_data = `C_lower;
										
								default: lcd_data = 4'b0000;
							endcase
						12'b000001110000: lcd_flags = 2'b11;	// data_write enable
						12'b000010000000: lcd_flags = 2'b00;	// data_write disable
						12'b111111111111: lcd_data = 0;		// clear data bus
					endcase
				end

			end
		end
		counter = counter + 1;
	end
end

endmodule