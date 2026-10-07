`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.11.2025 20:13:46
// Design Name: 
// Module Name: linebuffer
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


module linebuffer #(parameter WIDTH = 8,parameter DEPTH = 256)(
input wire clk,
input wire reset,
input wire [WIDTH-1:0] data_in,
output reg [WIDTH-1:0] data_out );
reg [WIDTH-1:0] shift_reg [0:DEPTH-1];
integer i;
always @(posedge clk) begin
if (reset) begin
for (i = 0;i < DEPTH;i = i + 1)
shift_reg[i] <= {WIDTH{1'b0}};
data_out <= 0;
end
else begin
for (i = DEPTH-1;i > 0;i = i - 1)
shift_reg[i] <= shift_reg[i-1];
shift_reg[0] <= data_in;
data_out <= shift_reg[DEPTH-1];
end
end
endmodule

