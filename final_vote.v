`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.11.2025 20:13:46
// Design Name: 
// Module Name: final_vote
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
// FINAL VOTE UNIT
// Combines rule-based scores and thresholds to decide
// fracture presence (1) or normal (0).
// =====================================================
module final_vote_unit(
    input  wire [6:0]  cluster_score_in,
    input  wire [6:0]  corner_score_in,
    input  wire [6:0]  chaos_score_in,
    input  wire [23:0] brightness_score_in,
    input  wire        confusion_flag_in,

    input  wire [6:0]  thresh_cluster,
    input  wire [6:0]  thresh_corner,
    input  wire [6:0]  thresh_chaos,
    input  wire [23:0] thresh_brightness,

    output reg  [2:0]  vote_count_out,
    output reg         final_diagnosis_out,

    // Debug outputs
    output reg [6:0]   dbg_cluster_score,
    output reg [6:0]   dbg_corner_score,
    output reg [6:0]   dbg_chaos_score,
    output reg [23:0]  dbg_brightness_score,
    output reg [2:0]   dbg_vote_count
);

    reg [2:0] votes;

    always @(*) begin
        // Default safe values
        vote_count_out        = 3'd0;
        final_diagnosis_out   = 1'b0;

        dbg_cluster_score     = cluster_score_in;
        dbg_corner_score      = corner_score_in;
        dbg_chaos_score       = chaos_score_in;
        dbg_brightness_score  = brightness_score_in;
        dbg_vote_count        = 3'd0;

        // Reset vote counter
        votes = 3'd0;

        // -------------------------------
        // Threshold-based rule voting
        // -------------------------------
        if (cluster_score_in > thresh_cluster)        votes = votes + 1; // Rule 1
        if (corner_score_in  > thresh_corner)         votes = votes + 1; // Rule 2
        if (chaos_score_in   > thresh_chaos)          votes = votes + 1; // Rule 3 (more chaos = bad → true when high)
        if (brightness_score_in > thresh_brightness)  votes = votes + 1; // Rule 5
        if (confusion_flag_in)                        votes = votes + 1; // Rule 4 (dominance/ambiguity)

        // -------------------------------
        // Output assignment
        // -------------------------------
        vote_count_out = votes;
        dbg_vote_count = votes;

        // Final diagnosis: 3 or more votes = fracture
        if (votes >= 3)
            final_diagnosis_out = 1'b1;
        else
            final_diagnosis_out = 1'b0;
    end

endmodule
`default_nettype wire
