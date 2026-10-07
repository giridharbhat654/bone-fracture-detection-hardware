`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.11.2025 02:32:10
// Design Name: 
// Module Name: rule_control
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`default_nettype none
// =====================================================
// RULE COUNTER UNIT (simplified 9x9 hardware-friendly version)
// =====================================================
module rule_counter_unit (
    input  wire [80:0] cluster_map_in,   // 9x9 flattened mask (cluster)
    input  wire [80:0] corner_map_in,    // 9x9 flattened mask (corner)
    input  wire [80:0] chaos_map_in,     // 9x9 flattened mask (chaos)
    input  wire [80*17-1:0] mag_map_in,  // placeholder, not used here

    output reg  [6:0] cluster_score_out,
    output reg  [6:0] corner_score_out,
    output reg  [6:0] chaos_score_out,
    output reg  [23:0] brightness_score_out,
    output reg         confusion_flag_out
);
    integer i;

    always @(*) begin
        cluster_score_out    = 0;
        corner_score_out     = 0;
        chaos_score_out      = 0;
        brightness_score_out = 0;
        confusion_flag_out   = 0;

        // Count active bits in each 9x9 mask (basic sum)
        for (i = 0; i < 81; i = i + 1) begin
            cluster_score_out = cluster_score_out + cluster_map_in[i];
            corner_score_out  = corner_score_out  + corner_map_in[i];
            chaos_score_out   = chaos_score_out   + chaos_map_in[i];
        end

        // Dummy brightness sum - simulate with scaled value
        brightness_score_out = (cluster_score_out + corner_score_out + chaos_score_out) * 100;

        // Confusion flag: 1 if all three rule counts are above mid-level
        if ((cluster_score_out > 20) && (corner_score_out > 10) && (chaos_score_out > 5))
            confusion_flag_out = 1'b1;
    end
endmodule
`default_nettype wire
