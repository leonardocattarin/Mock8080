/***************************/
/*** Module_CPU ***/
/***************************/
module	Module_CPU   (	clk_qzt,
					dbg_clk,
                    clk_in,

					en,
					reset,
					res_addr,
					data_in,

					data_out,
					data_addr,
					write_en,

					dbg_interface
					);

// IN/OUT section
input clk_qzt;
input clk_in;
input dbg_clk;
input en;

//address to reset instruction pointer
input reset;
input [7:0] res_addr;

//data IN when communicating with RAM
input [7:0] data_in;

//data OUT for RAM communication
output [7:0] data_out;
output [7:0] data_addr;
output 	write_en;

output [95:0] dbg_interface;

//Reg section
//debug output to know at which addr


reg [7:0] PC; //Program Counter: address to (supposed) next instruction 

reg [7:0] IR; //Instruction Register: contains opcode of current instruction

reg [7:0] W; //temporary (hidden) registers
reg [7:0] Z;

reg [7:0] A; //accumulator register

reg [7:0] B; //auxiliary general purpose registers
reg [7:0] C;

reg [7:0] H; //auxiliary regs, usually used to store addresses
reg [7:0] L;

reg [7:0] SP; //stack pointer register (stack grows downwards)

reg [7:0] state = 0; //identifies instruction state

reg [7:0] data_out;
reg [7:0] data_addr;
reg 	write_en = 0;
reg 	clk_in_old;
reg		dbg_clk_old;

//flags
reg flg_carry;
reg flg_sign;
reg flg_zero;
reg flg_parity;
reg flg_auxiliary;


buf(dbg_interface, {data_in,data_out,data_addr,SP,C,B,A,Z,W,state,IR,PC});


always @(posedge clk_qzt) begin
	if (en && dbg_clk && !dbg_clk_old) begin
		if (clk_in && !clk_in_old)begin //verifies enable and goes according to slave clock
			if(reset) begin //reset program counter to given address
				PC <= res_addr + 1;
				state <= 0;
			end
			else begin
				
				//first two states always fetch next instruction
					case (state)
						8'd0: begin
							data_addr <= PC; //place PC addr in address buffer
							write_en <= 0;  //read mode
							state <= state + 1;
						end 
						8'd1: begin
							//wait to allow RAM operations
							state <= state + 1;
						end 
						8'd2: begin
							IR <= data_in; //fetch instruction from RAM in IR
							state <= state + 1;
						end 
					endcase
					//at this point IR contains instruction pointed by PC
					//begin actual instruction execution
					//NOTE: usually instructions update program counter only at the end of their execution
					case (IR)
						//NOP, does nothing
						8'h00: begin
								case (state)
									8'd3: begin //simply increase PC and reset state
										PC <= PC + 1;
										state <= 0;
									end
								endcase
								end
						//JMP, jumps to address
						8'hC3: begin
								case (state)
									8'd3: begin //RAM fetch request for next address
										data_addr <= PC + 1;
										write_en <= 0;  //read mode
										state <= state + 1;
									end
									8'd4: begin 
										//wait to allow RAM operations
										state <= state + 1;
									end
									8'd5: begin //load fetched data directly in PC and reset state
										PC <= data_in;
										state <= 0;
									end
								endcase
								end
						//MVI B,Data, copies the byte to B reg
						8'h06: begin
								case (state)
									8'd3: begin //request fetch next byte
										data_addr <= PC + 1;
										write_en <= 0;  //read mode
										state <= state + 1;
									end
									8'd4: begin 
										//wait to allow RAM operations
										state <= state + 1;
									end
									8'd5: begin //load data directly in B and increse PC
										B <= data_in;
										PC <= PC + 2;
										state <= 0;
									end
								endcase
								end
						//ADD B, adds B content to A, sets carry
						8'h80: begin
								case (state)
									8'd3: begin //request fetch next byte
										{carry_flg, A} <= A + B;
										state <= 0;
										PC <= PC + 1;
									end
								endcase
								end
						//by default do a nope
						default: begin
								case (state)
									8'd3: begin //simply increase PC and reset state
										PC <= PC + 1;
										state <= 0;
									end
								endcase
								end
					endcase
				end
		end
		clk_in_old <= clk_in;
	end
	dbg_clk_old <= dbg_clk;
end

endmodule