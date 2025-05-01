`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/01 13:11:59
// Module Name: top_module
// Description: Top-level integration of IFetch, ALU, Controller, and Decoder
//////////////////////////////////////////////////////////////////////////////////

module top_module();

    // Clock and reset
    reg clk;
    reg rst;

    // IFetch <-> Controller/ALU signals
    wire [31:0] inst;
    wire [31:0] imm32;
    wire        branch;
    wire        zero;

    // ALU control and output
    wire        alu_src;
    wire [1:0]  alu_op;
    wire [31:0] alu_result;

    // Controller output control signals
    wire mem_read;
    wire mem_write;
    wire mem_to_reg;
    wire reg_write;

    // Decoder output and input signals
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] write_data;  // Can be hardcoded or linked to a MEM stage in full CPU

    // R-type decoding fields (to be extracted from inst)
    wire [2:0] funct3 = inst[14:12];
    wire [6:0] funct7 = inst[31:25];

    // =========================
    // Module Instantiations
    // =========================

    // IFetch unit
    IFetch uut_if (
        .clk(clk),
        .rst(rst),
        .imm32(imm32),
        .branch(branch),
        .zero(zero),
        .inst(inst)
    );

    // Decoder unit
    Decoder uut_decoder (
        .clk(clk),
        .rst(rst),
        .reg_write(reg_write),
        .inst(inst),
        .write_data(write_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .imm32(imm32)
    );

    // ALU unit
    ALU uut_alu (
        .read_data1(rs1_data),
        .read_data2(rs2_data),
        .imm32(imm32),
        .alu_src(alu_src),
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7(funct7),
        .alu_result(alu_result),
        .zero(zero)
    );

    // Controller unit
    Controller uut_ctrl (
        .inst(inst),
        .branch(branch),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .alu_op(alu_op)
    );

endmodule
