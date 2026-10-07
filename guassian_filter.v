`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.11.2025 20:13:46
// Design Name: 
// Module Name: guassian_filter
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


module gaussian_filter #(parameter PIXEL_WIDTH = 8)(
input wire [PIXEL_WIDTH-1:0] p11, p12, p13,
input wire [PIXEL_WIDTH-1:0] p21, p22, p23,
input wire [PIXEL_WIDTH-1:0] p31, p32, p33,
output wire [PIXEL_WIDTH-1:0] blurred_pixel_out);
wire [PIXEL_WIDTH+3:0] sum;
assign sum =
(p11) + (p12<<1) + (p13) +
(p21<<1) + (p22<<2) + (p23<<1) +
(p31) + (p32<<1) + (p33);
assign blurred_pixel_out = sum[PIXEL_WIDTH+3:4]; // divide by 16
endmodule

