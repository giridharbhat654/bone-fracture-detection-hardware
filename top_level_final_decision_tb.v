
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.11.2025 22:17:12
// Design Name: 
// Module Name: top_level_final_decision_tb
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

module top_level_final_decision_tb;

    // ===================================================
    // Parameters
    // ===================================================
    localparam IMAGE_WIDTH  = 256;
    localparam PIXEL_WIDTH  = 8;
    localparam ADDR_WIDTH   = 16;
    localparam TOTAL_PIXELS = IMAGE_WIDTH * IMAGE_WIDTH;

    // ===================================================
    // Signals
    // ===================================================
    reg clk;
    reg reset;
    reg start;
    wire output_valid;
    wire final_diagnosis_out;
    wire [7:0] edge_pixel_out_dbg;

    reg [6:0]  thresh_cluster;
    reg [6:0]  thresh_corner;
    reg [6:0]  thresh_chaos;
    reg [23:0] thresh_brightness;

    // exported debug scores from DUT
    wire [6:0] dbg_cluster_score;
    wire [6:0] dbg_corner_score;
    wire [6:0] dbg_chaos_score;
    wire [23:0] dbg_brightness_score;
    wire [2:0] dbg_vote_count;

    integer fd_out;
    integer i;

    // ===================================================
    // DUT (Design Under Test)
    // Make sure the top-level in your project has the exact same port names.
    // ===================================================
    top_level_final_decision #(
        .IMAGE_WIDTH(IMAGE_WIDTH),
        .PIXEL_WIDTH(PIXEL_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .thresh_cluster(thresh_cluster),
        .thresh_corner(thresh_corner),
        .thresh_chaos(thresh_chaos),
        .thresh_brightness(thresh_brightness),
        .final_diagnosis_out(final_diagnosis_out),
        .output_valid(output_valid),
        .edge_pixel_out_dbg(edge_pixel_out_dbg),
        .dbg_cluster_score(dbg_cluster_score),
        .dbg_corner_score(dbg_corner_score),
        .dbg_chaos_score(dbg_chaos_score),
        .dbg_brightness_score(dbg_brightness_score),
        .dbg_vote_count(dbg_vote_count)
    );

    // ===================================================
    // Clock generation (100 MHz)
    // ===================================================
    initial clk = 0;
    always #5 clk = ~clk;

    // ===================================================
    // Test Process
    // ===================================================
    initial begin
        // Initialize
        reset = 1;
        start = 0;
        thresh_cluster   = 7'd65;
        thresh_corner    = 7'd69;
        thresh_chaos     = 7'd30;
        thresh_brightness = 24'd5000000;

        // Hold reset for a few cycles
        repeat (10) @(posedge clk);
        reset = 0;

        // ===================================================
        // Load grayscale image from hex file into SRAM inside DUT
        // Make sure path exists and matches your system
        // ===================================================
        $display("Loading grayscale image data from input.hex ...");
        // The testbench assumes the sram instance inside the DUT is named `u_sram`
        // and has a memory named `mem` (i.e. dut.u_sram.mem). If your sram instance
        // has a different hierarchical name, adjust this path.
        $readmemh("C:/Users/C Giridhar Bhat/OneDrive/Desktop/lol/images/input.hex",
                  dut.u_sram.mem);

        // ===================================================
        // Open output file for writing edges
        // ===================================================
        fd_out = $fopen("C:/Users/C Giridhar Bhat/OneDrive/Desktop/lol/output.hex", "w");
        if (fd_out == 0) begin
            $display("ERROR: Could not open output.hex for writing");
            $finish;
        end

        // ===================================================
        // Start Processing
        // ===================================================
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        $display("Processing started... (waiting for output_valid)");

        // ===================================================
        // Wait for pipeline completion (output_valid asserted)
        // ===================================================
        wait (output_valid == 1);
        $display("Output valid asserted, writing binary edge map...");

        // ===================================================
        // Record Edge Map: write TOTAL_PIXELS outputs (00 or FF)
        // We sample edge_pixel_out_dbg each clock cycle.
        // ===================================================
        for (i = 0; i < TOTAL_PIXELS; i = i + 1) begin
            @(posedge clk);
            $fwrite(fd_out, "%02h\n", edge_pixel_out_dbg);
        end

        $fclose(fd_out);
        $display("Edge map successfully saved to output.hex");

        // ===================================================
        // Print internal rule scores (from DUT exported debug ports)
        // ===================================================
        $display("========== INTERNAL RULE SCORES ==========");
$display("Cluster Score     = %0d", dut.dbg_cluster_score);
$display("Corner Score      = %0d", dut.dbg_corner_score);
$display("Chaos Score       = %0d", dut.dbg_chaos_score);
$display("Brightness Score  = %0d", dut.dbg_brightness_score);
$display("Vote Count        = %0d", dut.dbg_vote_count);
$display("Final Decision    = %b",  dut.final_diagnosis_out);
$display("==========================================");
        $display("==========================================");

        // ===================================================
        // Final Result
        // ===================================================
        $display("------------------------------------------------");
        $display("Processing finished!");
        $display("Final Diagnosis (1=Fracture, 0=Normal) = %b", final_diagnosis_out);
        $display("------------------------------------------------");

        #100;
        $finish;
    end

    // ===================================================
    // Waveform Dump
    // ===================================================
    initial begin
        $dumpfile("top_level_final_decision_tb.vcd");
        $dumpvars(0, top_level_final_decision_tb);
    end

    // ===================================================
    // Simple runtime monitor (prints a few signals each cycle)
    // Note: we do NOT reference internal wires of DUT here, only exported ports.
    // ===================================================
    always @(posedge clk) begin
    if (!reset && dut.state == 2'b01) begin
        $display("ADDR=%0d PIX=%0d h_map=%0d v_map=%0d cluster_mask=%b",
                  dut.addr, dut.pixel_from_mem, dut.h_map, dut.v_map, dut.cluster_mask);
    end
end


endmodule

`default_nettype wire




