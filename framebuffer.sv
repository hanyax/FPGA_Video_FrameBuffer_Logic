`timescale 1 ps / 1 ps
module framebuffer(busy, bump, reset, ram_clk, cam_clk, dataIn, refreshCountdown, write, isWrite, address, writeMask, writeData, lastframe, keepOpen);
	parameter num_frame = 16;
	input logic busy, bump, reset, ram_clk, cam_clk;
	input logic [9:0] dataIn;
	input logic [9:0] refreshCountdown;
	
	output logic write;
	output logic isWrite; // 1'b0: read from address, 1'b1: write writeData with writeMask to address
	output logic [24:0] address; // [24:10] is the row address, [9:0] is the column address. It costs 4-6 cycles to switch rows.
	output logic [1:0] writeMask; // 2'b11: write data[15:0], 2'b10: write data[15:8], 2'b01: write data[7:0], 2'b00: invalid
	output logic [9:0] writeData;
	output logic [14:0] lastframe;
	output logic keepOpen;
	assign keepOpen = 0 | (refreshCountdown > 100);
	
	logic [14:0] frame_pointer; // ram_row
	logic [14:0] row_offset;
	logic [9:0] column_offset;
	
	assign lastframe = frame_pointer;
	
	// Fifo1
	logic empty, full, writeFifo;
	integer i, counter;
	
///////////////////////////////
//	Write Timer 0.25s
///////////////////////////////	
	always_ff @(posedge cam_clk) begin
		if (reset | busy) begin
			i <= 0;
			counter <= 0;
			writeFifo <= 1;
		end else begin
			if (writeFifo) begin
				if (i < (640 * 480)) begin
					i <= i + 1;
				end
			end else begin
				i <= 0;
			end
				
			if (writeFifo) begin//
				if (i <  (640 * 480) ) begin
					writeFifo <= 1;
				end else begin
					writeFifo <= 0;
				end
			end 
			
			if (writeFifo) begin//
				counter <= 0;
			end else begin
				if (counter < 2500) begin //25000000) begin
					counter <= counter + 1;
				end else begin
					writeFifo <= 1;
					counter <= 0;
				end
			end 		
		end
	end
	
///////////////////////////////
//	SDRAM address
///////////////////////////////
	always_ff @(posedge ram_clk) begin
		if (reset | busy) begin
			frame_pointer <= 0;
			row_offset <= 0;
			column_offset <= 0;
		end else begin
			if (writeFifo) begin
				if (row_offset >= 300) begin
					if ((frame_pointer + 300) >= (num_frame * 300)) begin
						frame_pointer <= 0;
					end else begin
						frame_pointer <= frame_pointer + 300;
					end
					row_offset <= 0;
					column_offset <= 0;
				end else begin
					if (column_offset < 1023) begin
						column_offset <= column_offset + 1;
						row_offset <= row_offset;
					end else begin
						column_offset <= 0;
						row_offset <= row_offset + 1;
					end
				end
			end
		end
	end
	
	assign address = {frame_pointer+row_offset,column_offset};
	
///////////////////////////////
//	Fifo for cam/ram interface 
///////////////////////////////
assign writeMask = 2'b11;
assign write = ~empty;
assign isWrite = ~bump;
camToRamFifo f1 (.aclr(reset | busy), .data(dataIn), .rdclk(ram_clk), .rdreq(~empty), .wrclk(cam_clk), .wrreq(writeFifo), .q(writeData), .rdempty(empty), .wrfull());
						
endmodule

module framebuffer_tb();
	logic bump, reset, ram_clk, cam_clk;
	logic [9:0] dataIn;
	logic write;
	logic keepOpen;
	logic isWrite; // 1'b0: read from address, 1'b1: write writeData with writeMask to address
	logic [24:0] address; // [24:10] is the row address, [9:0] is the column address. It costs 4-6 cycles to switch rows.
	logic [1:0] writeMask; // 2'b11: write data[15:0], 2'b10: write data[15:8], 2'b01: write data[7:0], 2'b00: invalid
	logic [9:0] writeData;
	logic [14:0] lastframe;
	logic [9:0] refreshCountdown;
	
	framebuffer dut (.bump, .reset, .ram_clk, .cam_clk, .dataIn, .refreshCountdown, .write, .isWrite, .address, .writeMask, .writeData, .lastframe, .keepOpen);

	parameter period = 10;
	initial begin 
		cam_clk<=0;
		forever # (period/2) cam_clk = ~cam_clk;
	end
	
	initial begin 
		ram_clk<=0;
		forever # (period/2) ram_clk = ~ram_clk;
	end
	
	integer i;
	initial begin
		reset <= 1; i <= 1;@(posedge cam_clk);
		reset <= 0; dataIn <= i; @(posedge cam_clk);
		repeat(25000010) begin
			i <= i+1; dataIn <= i;@(posedge cam_clk);
		end

		$stop();
	end
	
	
endmodule