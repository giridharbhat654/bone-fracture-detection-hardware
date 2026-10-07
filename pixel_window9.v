`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.11.2025 20:13:46
// Design Name: 
// Module Name: pixel_window9
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


module pixel_window_9x9 #(parameter DATA_WIDTH = 1)(
input wire clk,
input wire reset,
input wire [DATA_WIDTH-1:0] pixel_in_row0,
input wire [DATA_WIDTH-1:0] pixel_in_row1,
input wire [DATA_WIDTH-1:0] pixel_in_row2,
input wire [DATA_WIDTH-1:0] pixel_in_row3,
input wire [DATA_WIDTH-1:0] pixel_in_row4,
input wire [DATA_WIDTH-1:0] pixel_in_row5,
input wire [DATA_WIDTH-1:0] pixel_in_row6,
input wire [DATA_WIDTH-1:0] pixel_in_row7,
input wire [DATA_WIDTH-1:0] pixel_in_row8,
// Flattened 9×9 window output - single 81-bit vector
output reg [9*9*DATA_WIDTH-1:0] window_out
);
// Internal 2D storage (9×9)
reg [DATA_WIDTH-1:0] window [0:8][0:8];
integer r,c;
// Sequential shift window
always @(posedge clk) begin
if (reset) begin
for (r = 0;r < 9;r = r + 1)
for (c = 0;c < 9;c = c + 1)
window[r][c] <= 0;
window_out <= 0;
end
else begin
// Shift each row
for (r = 0;r < 9;r = r + 1) begin
for (c = 0;c < 8;c = c + 1)
window[r][c] <= window[r][c+1];
end
// Insert new pixels at right edge
window[0][8] <= pixel_in_row0;
window[1][8] <= pixel_in_row1;
window[2][8] <= pixel_in_row2;
window[3][8] <= pixel_in_row3;
window[4][8] <= pixel_in_row4;
window[5][8] <= pixel_in_row5;
window[6][8] <= pixel_in_row6;
window[7][8] <= pixel_in_row7;
window[8][8] <= pixel_in_row8;
// Flatten for output
for (r = 0;r < 9;r = r + 1)
for (c = 0;c < 9;c = c + 1)
window_out[(r*9 + c)*DATA_WIDTH +: DATA_WIDTH] <= window[r][c];
end
end
endmodule


