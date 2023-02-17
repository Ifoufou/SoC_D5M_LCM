// (C) 2001-2020 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


// THIS FILE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THIS FILE OR THE USE OR OTHER DEALINGS
// IN THIS FILE.

/******************************************************************************
 *                                                                            *
 * A modified version of the altera_up_avalon_video_vga_timing module to work *
 * with the TRDB LCM from Terasic                                             *
 *                                                                            *
 ******************************************************************************/

module video_trdb_lcm_timing (
	// inputs
	clk,
	reset,

	red_to_vga_display,
	green_to_vga_display,
	blue_to_vga_display,
	color_select,

	// outputs
	read_enable,

	end_of_active_frame,
	end_of_frame,

	lcm_h_sync,      // LCM H_SYNC
	lcm_v_sync,      // LCM V_SYNC
	lcm_color_data   // LCM Color[7:0] for TRDB_LCM
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/

/* Number of pixels */
parameter H_ACTIVE      =  960;
parameter H_FRONT_PORCH =   59;
parameter H_SYNC        =    1;
parameter H_BACK_PORCH  =  151;
parameter H_TOTAL       = 1171;

/* Number of lines */
parameter V_ACTIVE      = 240;
parameter V_FRONT_PORCH =   8;
parameter V_SYNC        =   1;
parameter V_BACK_PORCH  =  13;
parameter V_TOTAL       = 262;

// channel width => 8-bit per channel
parameter CW = 8;
// Number of bits of the pixel counter register
// Note: the pixel counter will only iterate on one line of the frame
// (from 0 to ~H_TOTAL).
parameter PW = $clog2(H_TOTAL);
parameter PIXEL_COUNTER_INCREMENT = 10'h001;

parameter LW = $clog2(V_TOTAL); // Number of bits for lines
parameter LINE_COUNTER_INCREMENT = 10'h001;

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input clk;
input reset;

input [CW-1: 0] red_to_vga_display;
input [CW-1: 0] green_to_vga_display;
input [CW-1: 0] blue_to_vga_display;
input [   2: 0] color_select;

// Outputs
output read_enable;

output reg end_of_active_frame;
output reg end_of_frame;

output reg lcm_h_sync;		 // LCM H_SYNC
output reg lcm_v_sync;	     // LCM V_SYNC
output reg [CW-1: 0] lcm_color_data; // VGA Color[7:0] for TRDB_LCM

/*****************************************************************************
 *                           Constant Declarations                           *
 *****************************************************************************/


/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/

// Internal Registers
//reg					clk_en;
reg [PW-1:0] pixel_counter;
reg [LW-1:0] line_counter;

reg early_hsync_pulse;
reg early_vsync_pulse;
reg hsync_pulse;
reg vsync_pulse;

reg hblanking_pulse;
reg vblanking_pulse;
reg blanking_pulse;


/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/

/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

// Output Registers
always @ (posedge clk)
begin
	if (reset)
	begin
		lcm_h_sync     <= 1'b1;
		lcm_v_sync     <= 1'b1;
		lcm_color_data <= {CW{1'b0}};
	end
	else
	begin
		lcm_h_sync <= ~hsync_pulse;
		lcm_v_sync <= ~vsync_pulse;

		if (blanking_pulse)
			lcm_color_data <= {CW{1'b0}};
		else
			lcm_color_data <= ({CW{color_select[0]}} & red_to_vga_display) |
                              ({CW{color_select[1]}} & green_to_vga_display) |
                              ({CW{color_select[2]}} & blue_to_vga_display);
	end
end

// Internal Registers
always @ (posedge clk)
begin
	if (reset)
	begin
		pixel_counter <= H_TOTAL - 3; // {PW{1'b0}};
		line_counter  <= V_TOTAL - 1; // {LW{1'b0}};
	end
	else
	begin
		// last pixel in the line
		if (pixel_counter == (H_TOTAL - 1))
		begin
			pixel_counter <= {PW{1'b0}};
			
			// last pixel in last line of frame
			if (line_counter == (V_TOTAL - 1))
				line_counter <= {LW{1'b0}};
			// last pixel but not last line
			else
				line_counter <= line_counter + LINE_COUNTER_INCREMENT;
		end
		else 
			pixel_counter <= pixel_counter + PIXEL_COUNTER_INCREMENT;
	end
end

always @ (posedge clk) 
begin
	if (reset)
	begin
		end_of_active_frame <= 1'b0;
		end_of_frame		<= 1'b0;
	end
	else
	begin
		if ((line_counter == (V_ACTIVE - 1)) &&
			(pixel_counter == (H_ACTIVE - 2)))
			end_of_active_frame <= 1'b1;
		else
			end_of_active_frame <= 1'b0;

		if ((line_counter == (V_TOTAL - 1)) && 
			(pixel_counter == (H_TOTAL - 2)))
			end_of_frame <= 1'b1;
		else
			end_of_frame <= 1'b0;
	end
end

always @ (posedge clk) 
begin
	if (reset)
	begin
		early_hsync_pulse <= 1'b0;
		early_vsync_pulse <= 1'b0;
		
		hsync_pulse <= 1'b0;
		vsync_pulse <= 1'b0;
	end
	else
	begin
		// start of horizontal sync
		if (pixel_counter == (H_ACTIVE + H_FRONT_PORCH - 2))
			early_hsync_pulse <= 1'b1;	
		// end of horizontal sync
		else if (pixel_counter == (H_TOTAL - H_BACK_PORCH - 2))
			early_hsync_pulse <= 1'b0;	
			
		// start of vertical sync
		if ((line_counter == (V_ACTIVE + V_FRONT_PORCH - 1)) && 
				(pixel_counter == (H_TOTAL - 2)))
			early_vsync_pulse <= 1'b1;
		// end of vertical sync
		else if ((line_counter == (V_TOTAL - V_BACK_PORCH - 1)) && 
				(pixel_counter == (H_TOTAL - 2)))
			early_vsync_pulse <= 1'b0;
			
		hsync_pulse <= early_hsync_pulse;
		vsync_pulse <= early_vsync_pulse;
	end
end

always @ (posedge clk) 
begin
	if (reset)
	begin
		hblanking_pulse	<= 1'b1;
		vblanking_pulse	<= 1'b1;
		
		blanking_pulse	<= 1'b1;
	end
	else
	begin
		if (pixel_counter == (H_ACTIVE - 2))
			hblanking_pulse	<= 1'b1;
		else if (pixel_counter == (H_TOTAL - 2))
			hblanking_pulse	<= 1'b0;
		
		if ((line_counter == (V_ACTIVE - 1)) &&
				(pixel_counter == (H_TOTAL - 2))) 
			vblanking_pulse	<= 1'b1;
		else if ((line_counter == (V_TOTAL - 1)) &&
				(pixel_counter == (H_TOTAL - 2))) 
			vblanking_pulse	<= 1'b0;
			
		blanking_pulse		<= hblanking_pulse | vblanking_pulse;
	end
end

/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/

// Output Assignments
assign read_enable = ~blanking_pulse;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/


endmodule

