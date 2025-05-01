`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/01 14:04:50
// Design Name: 
// Module Name: DMem
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


module DMem(
input clk,
input mem_read,mem_write,
input [31:0] addr,
input [31:0] din,
output[31:0] dout);
prgram udram(.clka(~clk), .wea(mem_write), .addra(addr[15:2]), .dina(din), .douta(dout));
endmodule

