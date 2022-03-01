module	LCD_Driver_Hex	(	qzt_clk,
					addrInput,
                    dataInput,
					signFlag,
					dashFlag,

					lcd_flags,
					lcd_data);

/*****************************/
/*      	Input			 */
/*****************************/
input		qzt_clk;
input	[7:0]	addrInput;
input	[7:0]	dataInput;
input		signFlag;
input		dashFlag;

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
reg	[20:0]	counter;

always @(posedge qzt_clk) begin

    // POWER-ON INITIALIZATION
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

		// DISPLAY CONFIGURATION (COMMAND PART)
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

	// DISPLAY CONFIGURATION (SLEEP PART)
	end else if (initializeLabel == 2'b11) begin
		// after at least 82000 clock cycles, jump to next operation
		if (counter[16:0] == 17'b11000000000000000) begin	// 98304
			initializeLabel = 2'b00;
			counter = 0;
		end else begin
			counter = counter + 1;
		end


// WRITING DATA TO DISPLAY
	end else begin
		//note : to execute next commands must have passed 2^20+2^19+2^18+2^17+2^16+2^15 cycles (around 20 ms?)
		if (counter[20:15] == 6'b111111) begin

			// "Set DD RAM Address" command (address is set to 0)
			if (counter[14:12] == 0) begin
				case (counter[11:0])
					// upper nimble
					12'b000000000000: lcd_data = 4'b1000;	// prepare data bus
					12'b000000010000: lcd_flags = 2'b01;	// command_write enable
					12'b000000100000: lcd_flags = 2'b00;	// command_write disable

					// lower nimble
					12'b000001100000: lcd_data = 4'b0000;	// prepare data bus
					12'b000001110000: lcd_flags = 2'b01;	// command_write enable
					12'b000010000000: lcd_flags = 2'b00;	// command_write disable
					12'b111111111111: lcd_data = 0;		// clear data bus
				endcase

			// "Write Data to CG RAM or DD RAM" command (address is set to 0)
			end else if (counter[14:12] <= 3'b111) begin
				case (counter[11:0])
					// upper nimble
					12'b000000000000:
						case (counter[14:12])

							3'b101: if (dataInput[3:0] <= 4'b1001) 
									lcd_data = 4'b0011;
							 	else 
							 		lcd_data = 4'b0100;

							3'b100: if (dataInput[7:4] <= 4'b1001) 
									lcd_data = 4'b0011;
							 	else 
							 		lcd_data = 4'b0100;
						
							3'b011: lcd_data = 4'b0010;

							3'b010: if (addrInput[3:0] <= 4'b1001) 
									lcd_data = 4'b0011;
							 	else 
							 		lcd_data = 4'b0100;

							3'b001: if (addrInput[7:4] <= 4'b1001) 
									lcd_data = 4'b0011;
							 	else 
							 		lcd_data = 4'b0100;
									 
							default: lcd_data = 4'b0010;
						endcase
					12'b000000010000: lcd_flags = 2'b11;	// data_write enable
					12'b000000100000: lcd_flags = 2'b00;	// data_write disable

					// lower nimble
					12'b000001100000:
						case (counter[14:12])
							3'b101: if (dataInput[3:0] <= 4'b1001)
									lcd_data = dataInput[3:0];
							 	else 
							 		lcd_data = dataInput[3:0] - 4'b1001;

							3'b100: if (dataInput[7:4] <= 4'b1001) 
									lcd_data = dataInput[7:4];
							 	else 
							 		lcd_data = dataInput[7:4] - 4'b1001;
						
							3'b011: lcd_data = 4'b0000;

							3'b010: if (addrInput[3:0] <= 4'b1001) 
									lcd_data = addrInput[3:0];
							 	else 
							 		lcd_data = addrInput[3:0] - 4'b1001;

							3'b001: if (addrInput[7:4] <= 4'b1001) 
									lcd_data = addrInput[7:4];
							 	else 
							 		lcd_data = addrInput[7:4] - 4'b1001;
									 
							default: lcd_data = 4'b0000;
						endcase
					12'b000001110000: lcd_flags = 2'b11;	// data_write enable
					12'b000010000000: lcd_flags = 2'b00;	// data_write disable
					12'b111111111111: lcd_data = 0;		// clear data bus
				endcase
			end
		end
		counter = counter + 1;
	end
end

endmodule