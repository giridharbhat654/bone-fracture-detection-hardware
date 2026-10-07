`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.11.2025 20:13:46
// Design Name: 
// Module Name: sram
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


module sram #(parameter WIDTH = 8,parameter DEPTH = 65536)(
input wire clk,
input wire cs,
input wire wr_en,
input wire rd_en,
input wire reset,
input wire [WIDTH-1:0] data_in,
input wire [$clog2(DEPTH)-1:0] address,
output reg [WIDTH-1:0] data_out
);
// Synthesis tool will map this to SRAM macro
reg [WIDTH-1:0] mem [0:DEPTH-1];
always @(posedge clk) begin
if (reset)
data_out <= {WIDTH{1'b0}};
else if (cs && wr_en)
mem[address] <= data_in;
else if (cs && rd_en)
data_out <= mem[address];
end
endmodule
