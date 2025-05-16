`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/01 13:11:59
// Module Name: top_module
// Description: Top-level integration of IFetch, ALU, Controller, and Decoder
//////////////////////////////////////////////////////////////////////////////////

module top_module(
    input init_clk,
    input rst,
    input done,
    input cp_done,
    input [7:0] sw_input,
    input  wire rx,
    output wire tx,
    output [7:0] seg1,
    output [7:0] seg2,
    output [7:0] led,
    output wire [7:0] an   //control the 8-segment
);
    // about IO
    wire en_pc;
    wire clk;
    wire en_input;
    wire en_output;
    wire done_input;
    wire [31:0] output_data;
    wire [31:0] input_data;
    wire is_ecall;
    wire [31:0] reg_a7;
    wire [7:0] cp_input;
    
    //divided clock
    wire clk_de;
    
    // IFetch <-> Controller/ALU signals
    wire [31:0] inst;
    wire [31:0] imm32;
    wire        branch;
    wire        zero;
    wire [31:0] pc;
    wire [31:0] uart_reg_a7;
    wire [31:0] uart_output_data;

    // ALU control and output
    wire        alu_src;
    wire [1:0]  alu_op;
    wire [31:0] alu_result;

    // Controller output control signals
    wire mem_read;
    wire mem_write;
    wire mem_to_reg;
    wire reg_write;
    wire is_jal;
    wire is_jalr;
    wire is_lui;
    wire is_auipc;

    // Decoder output and input signals
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] write_data;  // Can be hardcoded or linked to a MEM stage in full CPU
    wire [31:0] mem_read_data;
    wire [31:0] reg_write_data; 

    // R-type decoding fields (to be extracted from inst)
    wire [2:0] funct3 = inst[14:12];
    wire [6:0] funct7 = inst[31:25];
    
    wire [31:0] regs [0:31];
    
    // =========================
    // Module Instantiations
    // =========================
    ClockDivider uut_debounce_divider(
        .clk(init_clk),
        .rst(rst),
        .period(1000000),
        .clk_out(clk_de)
    );
    
    ClockDivider uut_clk_divider(
        .clk(init_clk),
        .rst(rst),
        .period(6),
        .clk_out(clk)
    );
    
    // IFetch unit
    IFetch uut_if (
        .clk(clk),
        .rst(rst),
        .imm32(imm32),
        .branch(branch),
        .zero(zero),
        .inst(inst),
        .out_pc(pc),
        .is_jal(is_jal),
        .is_jalr(is_jalr),
        .new_pc(alu_result),
        .en_pc(en_pc)
    );

    // Decoder unit
    Decoder uut_decoder (
        .clk(clk),
        .rst(rst),
        .reg_write(reg_write),
        .inst(inst),
        .write_data(reg_write_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .imm32(imm32),
        .en_input(en_input),
        .en_output(en_output),
        .output_data(output_data),
        .reg_a7(reg_a7),
        .en_pc(en_pc),
        .regs(regs)
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
        .zero(zero),
        .pc(pc),
        .is_lui(is_lui),
        .is_auipc(is_auipc)
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
        .alu_op(alu_op),
        .is_jal(is_jal),
        .is_jalr(is_jalr),
        .is_lui(is_lui),
        .is_auipc(is_auipc),
        .is_ecall(is_ecall),
        .en_pc(en_pc),
        .en_input(en_input),
        .en_output(en_output),
        .reg_a7(reg_a7),
        .done_input(done_input)
    );
    
    // Data Memory unit
    DMem uut_dmem(
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .addr(alu_result),
        .din(rs2_data), 
        .dout(mem_read_data),
        .funct3(funct3),
        .en_pc(en_pc)
    );
    
    // MemOrIO unit
    WriteBackMUX uut_writebackmux(
        .mem_to_reg(mem_to_reg),
        .mem_read_data(mem_read_data),
        .alu_result(alu_result),
        .reg_write_data(reg_write_data),
        .addr(alu_result),
        .funct3(funct3),
        .pc(pc),
        .is_jal(is_jal),
        .is_jalr(is_jalr),
        .en_input(en_input),
        .done_input(done_input),
        .input_data(input_data)
    );
    
    InputModule uut_input(
        .clk(clk),
        .clk_de(clk_de),
        .rst(rst),
        .sw_input(sw_input),
        .cp_input(cp_input),
        .done(done),
        .cp_done(cp_done),
        .input_data(input_data),
        .true_done_input(done_input)
    );
    
    OutputModule uut_output(
        .clk(init_clk),
        .rst(rst),
        .en_output(en_output),
        .reg_a7(reg_a7),
        .output_data(output_data),
        .uart_reg_a7(uart_reg_a7),
        .uart_output_data(uart_output_data),
        .seg1(seg1),
        .seg2(seg2),
        .led(led),
        .an(an)
    );

    UartTop uut_uart(
        .clk(init_clk),
        .rst(rst),
        .rx(rx),
        .tx(tx),
        .uart_reg_a7(uart_reg_a7),
        .uart_output_data(uart_output_data),
        .cp_input(cp_input)
    );
    
endmodule