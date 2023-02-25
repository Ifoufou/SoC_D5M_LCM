module LCM_Controller(
    // Inputs
    clk,
    reset,

    // Inputs - Avalon-ST (Sink) Interface
    data,
    startofpacket,
    endofpacket,
    empty,
    valid,
    // Output - Avalon-ST (Sink) Interface
    ready,

    // Outputs - LCM Side
    LCM_DATA,
    LCM_DCLK,
    LCM_GRST,
    LCM_SHDB,
    LCM_HSYNC,
    LCM_VSYNC
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/
localparam
// channel width: size of each channel
CW = 8,
// data width: total size of the data
// could be 3*CW (RGB) or 4*CW (RGBA)
DW = 3*CW,

// RGB bit position, input data
R_UI = 23,
R_LI = 16,
G_UI = 15,
G_LI =  8,
B_UI =  7,
B_LI =  0,

/* Number of pixels */
H_ACTIVE      =  960,
H_FRONT_PORCH =   59,
H_SYNC        =    1,
H_BACK_PORCH  =  151,
H_TOTAL       = 1171,

/* Number of lines */
V_ACTIVE      = 240,
V_FRONT_PORCH =   8,
V_SYNC        =   1,
V_BACK_PORCH  =  13,
V_TOTAL       = 262;

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input clk;
input reset;

// Avalon Streaming Interface
// 24-bit RGB => 8-bit per channel
input [23 : 0] data;
input          startofpacket;
input          endofpacket;
input [ 1: 0]  empty;
input          valid;
output         ready;

output [ 7: 0] LCM_DATA;
output         LCM_DCLK;
output         LCM_GRST;
output         LCM_SHDB;
output         LCM_HSYNC;
output         LCM_VSYNC;

/*****************************************************************************
 *                           Constant Declarations                           *
 *****************************************************************************/

// States
localparam STATE_0_SYNC_FRAME = 1'b0,
           STATE_1_DISPLAY    = 1'b1;

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/
// Internal Wires
wire read_enable;
wire end_of_active_frame;

wire lcm_h_sync;
wire lcm_v_sync;
wire [ CW-1: 0] lcm_color_data;

// Internal Registers
reg [ 2: 0] color_select; // TRDB_LCM color selection

// State Machine Registers
reg ns_mode;
reg s_mode;

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/

always @(posedge clk)   // sync reset
begin
    if (reset == 1'b1)
        s_mode <= STATE_0_SYNC_FRAME;
    else
        s_mode <= ns_mode;
end

always @(*)
begin
    // Defaults
    ns_mode = STATE_0_SYNC_FRAME;

   case (s_mode)
    STATE_0_SYNC_FRAME:
    begin
        if (valid & startofpacket)
            ns_mode = STATE_1_DISPLAY;
        else
            ns_mode = STATE_0_SYNC_FRAME;
    end
    STATE_1_DISPLAY:
    begin
        if (end_of_active_frame)
            ns_mode = STATE_0_SYNC_FRAME;
        else
            ns_mode = STATE_1_DISPLAY;
    end
    default:
    begin
        ns_mode = STATE_0_SYNC_FRAME;
    end
    endcase
end

/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

// Internal Registers
always @(posedge clk)
begin
    if (reset)
        color_select <= 4'h1;
    else if (s_mode == STATE_0_SYNC_FRAME)
        color_select <= 4'h1;
    else // if (~read_enable) 
        color_select <= {color_select[1:0], color_select[2]};
end

/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/

// Output Assignments
assign ready = 
    (s_mode == STATE_0_SYNC_FRAME) ?
        valid & ~startofpacket : 
        read_enable & color_select[1];

assign LCM_SHDB  = 1'b1;
assign LCM_GRST  = 1'b1;
assign LCM_DCLK  = ~clk;
assign LCM_VSYNC = lcm_v_sync;
assign LCM_HSYNC = lcm_h_sync;
assign LCM_DATA  = lcm_color_data;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

video_trdb_lcm_timing LCM_Timing (
    // Inputs
    .clk  (clk),
    .reset(reset),

    .red_to_vga_display  (data[R_UI:R_LI]),
    .green_to_vga_display(data[G_UI:G_LI]),
    .blue_to_vga_display (data[B_UI:B_LI]),
    .color_select        (color_select),

    // Outputs
    .read_enable(read_enable),

    .end_of_active_frame(end_of_active_frame),
    .end_of_frame       (), // (end_of_frame),

    .lcm_h_sync    (lcm_h_sync),
    .lcm_v_sync    (lcm_v_sync),
    .lcm_color_data(lcm_color_data)
);
defparam
    LCM_Timing.CW = CW,

    LCM_Timing.H_ACTIVE      = H_ACTIVE,
    LCM_Timing.H_FRONT_PORCH = H_FRONT_PORCH,
    LCM_Timing.H_SYNC        = H_SYNC,
    LCM_Timing.H_BACK_PORCH  = H_BACK_PORCH,
    LCM_Timing.H_TOTAL       = H_TOTAL,

    LCM_Timing.V_ACTIVE      = V_ACTIVE,
    LCM_Timing.V_FRONT_PORCH = V_FRONT_PORCH,
    LCM_Timing.V_SYNC        = V_SYNC,
    LCM_Timing.V_BACK_PORCH  = V_BACK_PORCH,
    LCM_Timing.V_TOTAL       = V_TOTAL;

endmodule
