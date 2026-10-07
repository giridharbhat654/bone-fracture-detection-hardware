`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.11.2025 20:13:46
// Design Name: 
// Module Name: rule_counter
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



`timescale 1ns / 1ps
`default_nettype none

// =====================================================
// RULE COUNTER UNIT (Fixed & Functional)
// =====================================================
// This unit accumulates scores based on edge masks and
// gradient magnitudes from the Scharr + Binary Mask stage.
//
// Outputs four rule-based metrics:
//  - cluster_score: how many pixels have any weak edge
//  - corner_score:  how many have both h and v strong
//  - chaos_score:   how many have all weak edges (noise)
//  - brightness_score: sum of gradient magnitudes
//
// =====================================================
module rule_counter_unit #(
    parameter IMG_WIDTH = 256,
    parameter IMG_HEIGHT = 256
)(
    input  wire                  clk,
    input  wire                  reset,
    input  wire                  enable,           // active when reading valid pixels
    input  wire                  cluster_mask_in,
    input  wire                  corner_mask_in,
    input  wire                  chaos_mask_in,
    input  wire signed [15:0]    grad_mag_in,
input wire frame_start,
    output reg  [6:0]            cluster_score_out,
    output reg  [6:0]            corner_score_out,
    output reg  [6:0]            chaos_score_out,
    output reg  [23:0]           brightness_score_out,
    output reg                   confusion_flag_out
);

    // =====================================================
    // Internal accumulators
    // =====================================================
    reg [15:0] pixel_count;
    reg [23:0] brightness_accum;

    always @(posedge clk) begin
          if (reset || frame_start) begin
            pixel_count          <= 0;
            cluster_score_out    <= 0;
            corner_score_out     <= 0;
            chaos_score_out      <= 0;
            brightness_score_out <= 0;
            confusion_flag_out   <= 0;
            brightness_accum     <= 0;
        end else if (enable) begin
            pixel_count <= pixel_count + 1;

            // Count masks
            if (cluster_mask_in)
                cluster_score_out <= cluster_score_out + 1;
            if (corner_mask_in)
                corner_score_out  <= corner_score_out + 1;
            if (chaos_mask_in)
                chaos_score_out   <= chaos_score_out + 1;

            // Brightness accumulation
            brightness_accum <= brightness_accum + (grad_mag_in[15] ? -grad_mag_in : grad_mag_in);

            // Set confusion flag if too many chaos pixels
            if (chaos_score_out > 7'd50)
                confusion_flag_out <= 1'b1;
        end
    end

    // Output brightness at frame end
    always @(*) begin
        brightness_score_out = brightness_accum[23:0];
    end

endmodule

`default_nettype wire

