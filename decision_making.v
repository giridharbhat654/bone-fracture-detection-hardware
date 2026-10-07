`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.11.2025 20:13:46
// Design Name: 
// Module Name: decision_making
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
// TOP-LEVEL ASIC-FRIENDLY PIPELINE (With Timing-Fixed Rule Counter)
// =====================================================
module top_level_final_decision #(
    parameter IMAGE_WIDTH  = 256,
    parameter PIXEL_WIDTH  = 8,
    parameter ADDR_WIDTH   = 16,
    parameter WINDOW_SIZE  = 9
)(
    input  wire clk,
    input  wire reset,
    input  wire start,

    input  wire [6:0]  thresh_cluster,
    input  wire [6:0]  thresh_corner,
    input  wire [6:0]  thresh_chaos,
    input  wire [23:0] thresh_brightness,

    output reg  final_diagnosis_out,
    output reg  output_valid,

    output wire [7:0]  edge_pixel_out_dbg,
    output wire [6:0]  dbg_cluster_score,
    output wire [6:0]  dbg_corner_score,
    output wire [6:0]  dbg_chaos_score,
    output wire [23:0] dbg_brightness_score,
    output wire [2:0]  dbg_vote_count
);

    // =====================================================
    // FSM and Memory
    // =====================================================
    localparam S_IDLE = 2'b00, S_READ = 2'b01, S_PIPE = 2'b10, S_DONE = 2'b11;

    reg [1:0] state;
    reg [ADDR_WIDTH-1:0] addr;
    reg [15:0] latency_cnt;
    localparam LATENCY_CYCLES = (WINDOW_SIZE-1)*IMAGE_WIDTH + WINDOW_SIZE;

    wire [PIXEL_WIDTH-1:0] pixel_from_mem;
    sram #(.WIDTH(PIXEL_WIDTH), .DEPTH(1<<ADDR_WIDTH)) u_sram (
        .clk(clk),
        .cs(1'b1),
        .wr_en(1'b0),
        .rd_en(state == S_READ),
        .reset(reset),
        .data_in({PIXEL_WIDTH{1'b0}}),
        .address(addr),
        .data_out(pixel_from_mem)
    );

    // =====================================================
    // Linebuffers and 3x3 window
    // =====================================================
    wire [PIXEL_WIDTH-1:0] lb1_out, lb2_out;
    linebuffer #(.WIDTH(PIXEL_WIDTH), .DEPTH(IMAGE_WIDTH)) u_lb1 (
        .clk(clk), .reset(reset), .data_in(pixel_from_mem), .data_out(lb1_out)
    );
    linebuffer #(.WIDTH(PIXEL_WIDTH), .DEPTH(IMAGE_WIDTH)) u_lb2 (
        .clk(clk), .reset(reset), .data_in(lb1_out), .data_out(lb2_out)
    );

    reg [PIXEL_WIDTH-1:0] line0_shift [0:2];
    reg [PIXEL_WIDTH-1:0] line1_shift [0:2];
    reg [PIXEL_WIDTH-1:0] line2_shift [0:2];

    always @(posedge clk) begin
        if (reset) begin
            line0_shift[0] <= 0; line0_shift[1] <= 0; line0_shift[2] <= 0;
            line1_shift[0] <= 0; line1_shift[1] <= 0; line1_shift[2] <= 0;
            line2_shift[0] <= 0; line2_shift[1] <= 0; line2_shift[2] <= 0;
        end else begin
            line0_shift[0] <= line0_shift[1];
            line0_shift[1] <= line0_shift[2];
            line0_shift[2] <= lb2_out;

            line1_shift[0] <= line1_shift[1];
            line1_shift[1] <= line1_shift[2];
            line1_shift[2] <= lb1_out;

            line2_shift[0] <= line2_shift[1];
            line2_shift[1] <= line2_shift[2];
            line2_shift[2] <= pixel_from_mem;
        end
    end

    wire [PIXEL_WIDTH-1:0] p11 = line0_shift[0];
    wire [PIXEL_WIDTH-1:0] p12 = line0_shift[1];
    wire [PIXEL_WIDTH-1:0] p13 = line0_shift[2];
    wire [PIXEL_WIDTH-1:0] p21 = line1_shift[0];
    wire [PIXEL_WIDTH-1:0] p22 = line1_shift[1];
    wire [PIXEL_WIDTH-1:0] p23 = line1_shift[2];
    wire [PIXEL_WIDTH-1:0] p31 = line2_shift[0];
    wire [PIXEL_WIDTH-1:0] p32 = line2_shift[1];
    wire [PIXEL_WIDTH-1:0] p33 = line2_shift[2];

    // =====================================================
    // Scharr edge detection
    // =====================================================
    wire signed [15:0] h_map, v_map, d1_map, d2_map;
    scharr_compute_unit #(.PIXEL_WIDTH(PIXEL_WIDTH)) u_scharr (
        .p11(p11), .p12(p12), .p13(p13),
        .p21(p21), .p22(p22), .p23(p23),
        .p31(p31), .p32(p32), .p33(p33),
        .h_map_out(h_map),
        .v_map_out(v_map),
        .d1_map_out(d1_map),
        .d2_map_out(d2_map)
    );

    wire signed [15:0] grad_mag = h_map + v_map; // simple gradient magnitude estimate

    // =====================================================
    // Binary mask stage
    // =====================================================
    wire h_weak, v_weak, d1_weak, d2_weak;
    wire h_strong, v_strong;
    wire cluster_mask, chaos_mask;
    wire [7:0] edge_pixel_out;

    binary_mask_unit #(
        .EDGE_THRESHOLD_WEAK(16'd80),
        .EDGE_THRESHOLD_STRONG(16'd200)
    ) u_mask (
        .h_mag_in(h_map),
        .v_mag_in(v_map),
        .d1_mag_in(d1_map),
        .d2_mag_in(d2_map),
        .h_weak_out(h_weak),
        .v_weak_out(v_weak),
        .d1_weak_out(d1_weak),
        .d2_weak_out(d2_weak),
        .h_strong_out(h_strong),
        .v_strong_out(v_strong),
        .any_weak_edge(cluster_mask),
        .all_weak_edge(chaos_mask),
        .edge_binary_out(edge_pixel_out)
    );

    assign edge_pixel_out_dbg = edge_pixel_out;
    wire corner_mask = h_strong & v_strong;

    // =====================================================
    // Rule counter unit (your version)
    // =====================================================
    wire [6:0] cluster_score, corner_score, chaos_score;
    wire [23:0] brightness_score;
    wire confusion_flag;

    rule_counter_unit u_counter (
    .clk(clk),
    .reset(reset),
    .enable(state == S_READ),  // ✅ only count during active image read
    .cluster_mask_in(cluster_mask),
    .corner_mask_in(corner_mask),
    .chaos_mask_in(chaos_mask),
    .grad_mag_in(grad_mag),
    .cluster_score_out(cluster_score),
    .corner_score_out(corner_score),
    .chaos_score_out(chaos_score),
    .brightness_score_out(brightness_score),
    .confusion_flag_out(confusion_flag)
);

    // =====================================================
    // Final Voting Logic
    // =====================================================
    wire [2:0] vote_count;
    wire final_decision;

   final_vote_unit u_vote (
    .cluster_score_in(cluster_score),
    .corner_score_in(corner_score),
    .chaos_score_in(chaos_score),
    .brightness_score_in(brightness_score),
    .confusion_flag_in(confusion_flag),

    // 🔹 Thresholds from testbench
    .thresh_cluster(thresh_cluster),
    .thresh_corner(thresh_corner),
    .thresh_chaos(thresh_chaos),
    .thresh_brightness(thresh_brightness),

    // 🔹 Outputs
    .vote_count_out(vote_count),
    .final_diagnosis_out(final_decision),

    // 🔹 Debug
    .dbg_cluster_score(dbg_cluster_score),
    .dbg_corner_score(dbg_corner_score),
    .dbg_chaos_score(dbg_chaos_score),
    .dbg_brightness_score(dbg_brightness_score),
    .dbg_vote_count(dbg_vote_count)
);


    // =====================================================
    // FSM: pipeline timing and output logic
    // =====================================================
    always @(posedge clk) begin
        if (reset) begin
            state <= S_IDLE;
            addr <= 0;
            latency_cnt <= 0;
            output_valid <= 0;
            final_diagnosis_out <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    output_valid <= 0;
                    if (start) begin
                        addr <= 0;
                        latency_cnt <= 0;
                        state <= S_READ;
                    end
                end

                S_READ: begin
                    addr <= addr + 1;
                    if (addr == IMAGE_WIDTH*IMAGE_WIDTH - 1)
                        state <= S_PIPE;
                end

                S_PIPE: begin
                    latency_cnt <= latency_cnt + 1;
                    if (latency_cnt >= LATENCY_CYCLES + 512)
                        state <= S_DONE;
                end

                S_DONE: begin
                    output_valid <= 1;
                    final_diagnosis_out <= final_decision;
                    state <= S_IDLE;
                end
            endcase
        end
    end
endmodule
`default_nettype wire

// =====================================================
// Scharr compute unit
// =====================================================
module scharr_compute_unit #(
    parameter PIXEL_WIDTH = 8
)(
    input  wire [PIXEL_WIDTH-1:0] p11, p12, p13,
    input  wire [PIXEL_WIDTH-1:0] p21, p22, p23,
    input  wire [PIXEL_WIDTH-1:0] p31, p32, p33,
    output wire signed [15:0] h_map_out,
    output wire signed [15:0] v_map_out,
    output wire signed [15:0] d1_map_out,
    output wire signed [15:0] d2_map_out
);
    assign h_map_out  = (-3*$signed({1'b0,p11}) -10*$signed({1'b0,p21}) -3*$signed({1'b0,p31}))
                      + ( 3*$signed({1'b0,p13}) +10*$signed({1'b0,p23}) +3*$signed({1'b0,p33}));

    assign v_map_out  = (-3*$signed({1'b0,p11}) -10*$signed({1'b0,p12}) -3*$signed({1'b0,p13}))
                      + ( 3*$signed({1'b0,p31}) +10*$signed({1'b0,p32}) +3*$signed({1'b0,p33}));

    assign d1_map_out = (-2*$signed({1'b0,p11}) -1*$signed({1'b0,p12}) +1*$signed({1'b0,p23}) +2*$signed({1'b0,p33}));
    assign d2_map_out = ( 2*$signed({1'b0,p11}) +1*$signed({1'b0,p12}) -1*$signed({1'b0,p32}) -2*$signed({1'b0,p33}));
endmodule










