`timescale 1 ps / 1 ps
module framebuffer_back(busy, isWrite, drawBlack, replay, lastframe, raddr, clk, reset);
	parameter num_frame = 16;
	
	input logic busy, isWrite, drawBlack, replay, clk, reset; // running on VGA frequency
	// last frame pointer of the write frame
	input logic [14:0] lastframe;
	output logic [24:0]	raddr;
	
///////////////////////////////
//	SDRAM address
///////////////////////////////
	logic [14:0] frame_pointer; // ram_row
	logic [14:0] row_offset;
	logic [9:0] column_offset;
	
	integer replay_count;
	logic new_frame, cur_frame_done, doneUpdate;
	always_ff @(posedge clk) begin
		if (reset | drawBlack | ~replay | busy) begin
			replay_count <= 0;
			new_frame <= 0;
		end else begin
			if (doneUpdate) begin
				replay_count <= 0;
				new_frame <= 0;
			end else begin
				if (replay_count < 2500) begin //25000000) begin // VGA = 25Mhz replay the same image for 1 sec
					replay_count <= replay_count + 1;
					new_frame <= 0;
				end else begin
					new_frame <= 1;
				end
			end
		end
	end

	always_ff @(posedge clk) begin
		if (reset | drawBlack | ~replay | busy) begin
			if ((lastframe + 300) >= (num_frame * 300)) begin
				frame_pointer <= 0;
			end else begin
				frame_pointer <= lastframe + 300;
			end
			row_offset <= 0;
			column_offset <= 0;
			cur_frame_done <= 0;
			doneUpdate <= 0;
		end else begin
			if (replay) begin
				if (new_frame) begin // load a new frame while the current frame is done
					if (cur_frame_done) begin // update a frame
						doneUpdate <= 1;
						if ((frame_pointer + 300) > (num_frame * 300)) begin
							frame_pointer <= 0;
						end else begin
							frame_pointer <= frame_pointer + 300;
						end
						row_offset <= 0;
						column_offset <= 0;
						cur_frame_done <= 0;
					end else begin // finish up the current frame
						if (column_offset >= 1022 & row_offset >= 299) begin
							cur_frame_done <= 1;
						end 
						if (column_offset < 1023) begin
							column_offset <= column_offset + 1;
							row_offset <= row_offset;
						end else begin
							column_offset <= 0;
							if (row_offset < 300) begin
								row_offset <= row_offset + 1;
							end else begin
								row_offset <= 0;
							end
						end
						doneUpdate <= 0;
					end
				end else begin // stay at current frame
					frame_pointer <= frame_pointer;
					if (column_offset < 1023) begin
						column_offset <= column_offset + 1;
						row_offset <= row_offset;
					end else begin
						column_offset <= 0;
						if (row_offset < 300) begin
							row_offset <= row_offset + 1;
						end else begin
							row_offset <= 0;
						end
					end
					doneUpdate <= 0;
				end
			end
		end
	end
		
	assign raddr = {frame_pointer+row_offset,column_offset};
	
endmodule

module framebuffer_back_tb();
	parameter num_frame = 16;
	
	logic isWrite, drawBlack, replay, clk, reset; 
	logic [14:0] lastframe;
	logic [24:0]	raddr;
	
	framebuffer_back fb(.isWrite, .drawBlack, .replay, .lastframe, .raddr, .clk, .reset);

	parameter period = 10;
	initial begin 
		clk<=0;
		forever # (period/2) clk = ~clk;
	end
	
	integer i;
	initial begin
		reset <= 1; @(posedge clk);
		reset <= 0; isWrite <= 1; drawBlack <= 1; replay <= 0; lastframe <= 0; @(posedge clk);
		drawBlack <= 0; @(posedge clk);
		replay <= 1; @(posedge clk);
		
		repeat(50000500) begin
			@(posedge clk);
		end

		$stop();
	end

endmodule