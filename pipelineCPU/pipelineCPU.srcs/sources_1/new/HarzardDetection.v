`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/14 17:53:40
// Design Name: 
// Module Name: HarzardDetection
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


module HarzardDetection(
    input clk,
    input rst,
    output reg[31:0] pc,
    output reg is_nop
    );
    reg[31:0] count,next_count;
    reg[31:0] next_pc,next_is_nop;
    always @(negedge clk, negedge rst) begin
        if(~rst) begin
            count <= 0;
            pc <= 0;
            is_nop <= 1;
        end else begin
            count <= next_count;
            pc <= next_pc;
            is_nop <= next_is_nop;
        end
    end
    always @(*) begin
        if (count==4) next_count=0;
        else next_count=count+1;
        if (count==0) begin
            next_pc=pc+4;
            next_is_nop=0;
        end
        else begin
            next_pc=pc;
            next_is_nop=1;
        end
    end
endmodule
