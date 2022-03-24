/***************************/
/*** Module_BRAM_256_byte ***/
/***************************/

/*** Configured in Read-first: ***/
/*** If writing, the output at clkedge... ***/
/*** ...is previous state, not input ***/


module	Module_BRAM_256_byte   (	clk_qzt,
                    clk_in,
					dbg_clk,
					en,
					write_en,

					addr,
                    dbg_addr,
					data_in,

					data_out,
                    dbg_data_out);

// IN/OUT section
input clk_qzt;
input clk_in;
input dbg_clk_old;
input dbg_clk;
input en;
input write_en;

//address and data input
input [7:0] addr;
input [7:0] data_in;
output [7:0] data_out;

input [7:0] dbg_addr;
output [7:0] dbg_data_out;

//Reg section
reg [7:0] data_out;
reg [7:0] dbg_data_out;

reg clk_in_old;

//ram blocks, 8bit address and 8bit=1byte cells, -> 256 bytes memory
reg [7:0] RAM [255:0]; //unit size, number of unit cells

//ram initialization, aka program/data loading
initial
begin
	$readmemh("memory.data", RAM, 0, 255);
end


always @(posedge clk_qzt) begin
	if (en && dbg_clk && !dbg_clk_old)begin
		if (clk_in && !clk_in_old) begin
			if (write_en) begin
				RAM[addr] <= data_in;
			end

			data_out <= RAM[addr];
		end

        dbg_data_out <= RAM[dbg_addr];
		clk_in_old <= clk_in;
	end
	dbg_clk_old <= dbg_clk;
end

endmodule

