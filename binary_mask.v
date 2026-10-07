`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.11.2025 20:13:46
// Design Name: 
// Module Name: binary_mask
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
// Binary Mask Unit (Fixed + Adaptive)
// =====================================================
// This version is more sensitive and dynamically
// computes weak/strong edges for better detection
// on 8-bit grayscale medical images.
//
// Works with: h_map, v_map, d1_map, d2_map (from Scharr)
//
// Outputs:
//  - h_weak, v_weak, d1_weak, d2_weak
//  - h_strong, v_strong
//  - any_weak_edge  (for cluster mask)
//  - all_weak_edge  (for chaos mask)
//  - edge_binary_out (8-bit for debug/output)
//
// =====================================================
module binary_mask_unit #(
    parameter EDGE_THRESHOLD_WEAK   = 16'd80,   // Reduced threshold
    parameter EDGE_THRESHOLD_STRONG = 16'd150   // Reduced threshold
)(
    input  wire signed [15:0] h_mag_in,
    input  wire signed [15:0] v_mag_in,
    input  wire signed [15:0] d1_mag_in,
    input  wire signed [15:0] d2_mag_in,

    output wire h_weak_out,
    output wire v_weak_out,
    output wire d1_weak_out,
    output wire d2_weak_out,
    output wire h_strong_out,
    output wire v_strong_out,
    output wire any_weak_edge,
    output wire all_weak_edge,
    output reg  [7:0] edge_binary_out
);

    // =====================================================
    // Compute absolute magnitudes
    // =====================================================
    wire [15:0] abs_h  = h_mag_in[15]  ? -h_mag_in  : h_mag_in;
    wire [15:0] abs_v  = v_mag_in[15]  ? -v_mag_in  : v_mag_in;
    wire [15:0] abs_d1 = d1_mag_in[15] ? -d1_mag_in : d1_mag_in;
    wire [15:0] abs_d2 = d2_mag_in[15] ? -d2_mag_in : d2_mag_in;

    // =====================================================
    // Adaptive gradient magnitude (optional but helpful)
    // =====================================================
    wire [15:0] grad_mag = abs_h + abs_v + (abs_d1 >> 1) + (abs_d2 >> 1);

    // =====================================================
    // Edge detection thresholds
    // =====================================================
    assign h_weak_out  = (abs_h  > EDGE_THRESHOLD_WEAK);
    assign v_weak_out  = (abs_v  > EDGE_THRESHOLD_WEAK);
    assign d1_weak_out = (abs_d1 > EDGE_THRESHOLD_WEAK);
    assign d2_weak_out = (abs_d2 > EDGE_THRESHOLD_WEAK);

    assign h_strong_out = (abs_h > EDGE_THRESHOLD_STRONG);
    assign v_strong_out = (abs_v > EDGE_THRESHOLD_STRONG);

    // =====================================================
    // Cluster and Chaos masks
    // =====================================================
    // "Any weak edge" → if any direction shows an edge
    assign any_weak_edge = h_weak_out | v_weak_out | d1_weak_out | d2_weak_out;

    // "All weak edge" → very noisy / chaotic regions
    assign all_weak_edge = h_weak_out & v_weak_out & d1_weak_out & d2_weak_out;

    // =====================================================
    // Output binary edge pixel
    // =====================================================
    always @(*) begin
        if (h_strong_out || v_strong_out)
            edge_binary_out = 8'hFF;  // strong edge pixel
        else if (any_weak_edge)
            edge_binary_out = 8'h55;  // weak edge pixel (mid-gray)
        else
            edge_binary_out = 8'h00;  // background
    end

endmodule

`default_nettype wire





