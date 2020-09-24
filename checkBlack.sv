// syc the VGA display
module checkBlack(clk, reset, replay, x, y, drawBlack);
	input logic clk, reset, replay;
	output logic [9:0] x;
	output logic [8:0] y;
	output logic drawBlack;
	
	integer i,x_i, y_i;
	always_ff @(posedge clk) begin
		if (reset) begin
			drawBlack <= 1;
			i <= 0;
			x_i <= 0;
			y_i <= 0;
		end else begin
			if (~replay) begin
				drawBlack <= 1;
				if (i >= 640*480) begin
					i <= 0;
				end else begin
					i <= i + 1;
				end
			end else begin
				if (i < 640*480-1) begin
					drawBlack <= 1;
					i <= i + 1;
				end else begin
					drawBlack <= 0;
				end
			end
			
			if (y_i>=479) begin
				y_i <= 0;
				if (x_i>=639) begin
					x_i <= 0;
				end else begin
					x_i <= x_i + 1;
				end
			end else begin
				y_i <= y_i + 1;
				x_i <= x_i;
			end

		end
	end
	
	assign x = x_i;
	//assign y = y_i;
	always_comb begin
		if (~drawBlack) begin
			if (y_i == 0) begin
				y = 479;
			end else begin
				y = y_i-1;
			end
		end else begin
			y = y_i;
		end
	end
endmodule