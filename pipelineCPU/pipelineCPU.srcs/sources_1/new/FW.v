`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/17 22:28:25
// Design Name: 
// Module Name: FW
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


module FW(
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] exe_rd,
    input [4:0] mem_rd,
    input [31:0] fw_mem_data,
    input [31:0] fw_exe_data,
    input [31:0] rs1_data,
    input [31:0] rs2_data,
    input fw_reg_write1,
    input fw_reg_write2,
    input fw_exe_have_write_data,
    
    output reg [31:0] operand1_data,
    output reg [31:0] operand2_data,
    output reg is_stalling
    );
        
    always @(*) begin
        operand1_data = rs1_data;
        operand2_data = rs2_data;
        is_stalling = 0;
        if(fw_reg_write2) begin
            if(mem_rd == rs1) begin
                operand1_data = fw_mem_data;
            end
            if (mem_rd == rs2) begin
                operand2_data = fw_mem_data;
            end 
        end 
            
        if (fw_reg_write1) begin
            if(exe_rd == rs1) begin
                if (fw_exe_have_write_data) begin
                    operand1_data = fw_exe_data;
                end else begin 
                    is_stalling = 1;
                end
            end 
            if(exe_rd == rs2) begin
                if (fw_exe_have_write_data) begin
                    operand2_data = fw_exe_data;
                end else begin 
                    is_stalling = 1;
                end
            end 
        end 
    end
    
endmodule
