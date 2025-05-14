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
    output reg[31:0] inst
    );
    wire [13:0] addr;        // address for instruction memory
    wire [31:0] mem_out_inst;
    reg [31:0] next_inst;
    parameter base_address = 32'h0000_3000;
    parameter nop_inst = 32'b0;
        // Instantiate the instruction ROM
        assign addr = (pc[13:0]-base_address) >> 2;
        pgrom urom(
            .clka(clk),
            .addra(addr),
            .douta(mem_out_inst)
        );
       always @(posedge clk, negedge rst) begin
            if (~rst) begin
                inst <= 0;
            end else begin
                inst <= next_inst;
            end
       end
       always @(*) begin
            if (is_nop) begin
                next_inst = nop_inst;
            end else begin
                next_inst = mem_out_inst;
            end
       end
endmodule
