`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/14 17:50:40
// Design Name: 
// Module Name: IF
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


module IF(
    input clk,rst, 
    input[31:0] pc,
    input is_nop,
    output [31:0] output_inst
    );
    parameter base_address = 32'h0000_3000;
    parameter nop_inst = 32'h00000013;
    wire [13:0] addr;        // address for instruction memory
    wire [31:0] tmp_inst;
    assign output_inst = is_nop ? nop_inst : tmp_inst;
    assign addr = (pc[13:0]-base_address) >> 2;
    pgrom urom( // Instantiate the instruction ROM
        .clka(~clk),
        .addra(addr),
        .douta(tmp_inst)
    );
endmodule
