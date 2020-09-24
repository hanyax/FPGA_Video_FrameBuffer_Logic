`timescale 1 ps / 1 ps
module sdram_controller(
	input logic ram_clk, VGA_clk, cam_clk, bump, replay, reset,
	input logic [9:0] WR_DATA,
	output logic [9:0] RD_DATA,
	output logic [9:0] x,
	output logic [8:0] y,
	inout [15:0] DRAM_DQ, 
	output logic [12:0] DRAM_ADDR, 
	output logic [1:0] DRAM_BA, 
	output logic DRAM_CAS_N, 
	output logic DRAM_CKE, 
	output logic DRAM_CLK, 
	output logic DRAM_CS_N, 
	output logic DRAM_LDQM, 
	output logic DRAM_RAS_N, 
	output logic DRAM_UDQM, 
	output logic DRAM_WE_N 
    );
	 
	logic [24:0] read_addr, write_addr, address;
	logic [9:0] refreshCountdown;
	logic write, isWrite, drawBlack;
	logic [1:0] writeMask; // 2'b11: write data[15:0], 2'b10: write data[15:8], 2'b01: write data[7:0], 2'b00: invalid
	logic [9:0] writeData;
	logic [14:0] lastframe;
	logic keepOpen, busy, init;
	
	enum {A, B} ps, ns;
	integer i;
	logic syncStart;

	always_ff @(posedge cam_clk) begin
		if (reset) begin
			i <= 0;
			init <= 1;
		end else begin
			if (i >= 640 * 480) begin
				i <= 0;
			end else begin
				i <= i + 1;
			end
			if (syncStart & (i==0)) begin
				init = 0;
			end
			init <= init;
		end
	end
			
	always_ff @(posedge ram_clk) begin
		if (reset) begin
			ps <= A;
			syncStart <= 0;
		end else begin			
			if (busy & (i != 0)) begin
				ns = ps;
			end else begin
				if (~busy & ps == B) begin
					syncStart <= 1;
				end
				ns = B;
			end
		end
		ps <= ns;
	end
	
	framebuffer front_buffer(.busy(drawBlack), .bump, .reset, .ram_clk, .cam_clk, .dataIn(WR_DATA), 
									.refreshCountdown, .write, .isWrite, .address(write_addr), 
									.writeMask, .writeData, .lastframe, .keepOpen);
									
	framebuffer_back back_buffer(.busy(drawBlack), .isWrite, .drawBlack, .replay, .lastframe, .raddr(read_addr), .clk(VGA_clk), .reset);
	
	always_comb begin
		if (isWrite) begin
			address = write_addr;
		end else begin
			address = read_addr;
		end
	end
	
	logic readValid;
	logic [24:0] raddr;
	logic [15:0] new_data;
	logic [15:0] rdata, RDATA;
	EasySDRAM #(.CLOCK_PERIOD(8)) ram (.clk(ram_clk), .rst(reset), .write, .full(), .fifoUsage(), .isWrite, 
						.address, .writeMask, .writeData({6'b0, writeData}),
						.readValid, .raddr, .rdata, .keepOpen, .busy, .rowOpen(), .refreshCountdown,
						.DRAM_DQ, .DRAM_ADDR, .DRAM_BA, .DRAM_CAS_N, .DRAM_CKE, .DRAM_CLK, .DRAM_CS_N, .DRAM_LDQM, .DRAM_RAS_N, .DRAM_UDQM, .DRAM_WE_N);
	
	always @(posedge ram_clk) begin
		if (reset | drawBlack) begin
			RDATA <= 16'b1;
		end else begin
			if (readValid) begin
				RDATA <= rdata;
			end 
		end
	end
	
	// drawblack module
	checkBlack check (.clk(VGA_clk), .reset, .replay, .x, .y, .drawBlack);
	
	always_comb begin
		if (drawBlack) begin // write a fsm to controll drawback
			RD_DATA = 10'b1111111111;
		end else begin
			RD_DATA = rdata[9:0];
		end
	end

endmodule

module sdram_controller_tb ();
	logic ram_clk, VGA_clk, cam_clk, bump, replay, reset;
	logic [9:0] WR_DATA;
	logic [9:0] RD_DATA;
	logic [9:0] x;
	logic [8:0] y;
   logic clk, rst, write, full, isWrite, readValid, keepOpen, busy, rowOpen;
   logic [9:0] refreshCountdown;
   logic [7:0] fifoUsage;
   logic [24:0] raddr, address;
   logic [1:0] 	writeMask;
   logic [15:0] writeData, rdata;

   tri [15:0] DRAM_DQ;
   logic [12:0] DRAM_ADDR;
   logic [1:0] DRAM_BA;
   logic DRAM_CAS_N, DRAM_CKE, DRAM_CLK, DRAM_CS_N, DRAM_LDQM, DRAM_RAS_N, DRAM_UDQM, DRAM_WE_N;
	
	parameter ram_period = 10;
	parameter VGA_period = 40;
	parameter cam_period = 40;
	
	initial begin 
		ram_clk<=0;
		forever # (ram_period/2) ram_clk = ~ram_clk;
	end
	
	initial begin 
		cam_clk<=0;
		forever # (VGA_period/2) cam_clk = ~cam_clk;
	end
	
	initial begin 
		VGA_clk<=0;
		forever # (VGA_period/2) VGA_clk = ~VGA_clk;
	end
	
	sdram_controller dut (.*);
	
	integer i;
	initial begin
		reset <= 1; i <= 1; bump <= 0; replay <= 0; @(posedge cam_clk);
		
		reset <= 0; WR_DATA <= i; @(posedge cam_clk);
		
		repeat(100) begin
			i <= i+1; WR_DATA <= i;@(posedge cam_clk);
		end
		
		bump <= 1; replay <= 0; @(posedge cam_clk);
		
		repeat(50) begin
			@(posedge cam_clk);
		end
		
		bump <= 1; replay <= 1; @(posedge cam_clk);
		
		repeat(2457600) begin
			@(posedge cam_clk);
		end

		$stop();
	end
	
endmodule