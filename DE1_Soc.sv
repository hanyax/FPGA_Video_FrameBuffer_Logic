module DE1_Soc(CLOCK_50, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, KEY, LEDR, SW, GPIO_0);
	output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	output logic [9:0] LEDR;
	inout logic [35:0] GPIO_0;
	input logic [3:0] KEY;
	input logic [9:0] SW;
	input logic CLOCK_50;
	
	logic clk;
	assign clk = CLOCK_50;
	
	//parameter whichClock = 25;
	//clock_divider cdiv (.clock(CLOCK_50), .reset(reset), .divided_clocks(clk)); 
	
	
endmodule


module DE1_Soc_testbench();
	logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	logic [9:0] LEDR, SW;
	logic [3:0] KEY;
	logic clk;
	
	DE1_Soc dut (.CLOCK_50(clk), .HEX0, .HEX1, .HEX2, .HEX3, .HEX4, .HEX5, .KEY, .LEDR, .SW);
	
	parameter period = 100;
	
	initial begin 
		clk <= 1; 
		forever #(period/2) clk <= ~clk; 
	end
	
	initial begin 

	// test to 0
	$stop;
end
endmodule

// divided_clocks[0] = 25MHz, [1] = 12.5Mhz, ... [23] = 3Hz, [24] = 1.5Hz, [25] = 0.75Hz, ...
module clock_divider (clock, reset, divided_clocks);
	input logic reset, clock;
	output logic [31:0] divided_clocks = 0;

	always_ff @(posedge clock) begin
		divided_clocks <= divided_clocks + 1;
	end
endmodule
