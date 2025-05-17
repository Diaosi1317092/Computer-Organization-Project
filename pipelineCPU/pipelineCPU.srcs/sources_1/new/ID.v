`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/14 17:50:54
// Design Name: 
// Module Name: ID
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


module ID(
    input  [31:0]      inst,
    input  [31:0] regs [0:31],
    input         done_input,
    input  [31:0] input_data,
    input  [31:0] pc,       
    input check_a7,
    output [31:0] reg_write_data,
    output have_reg_write_data,

    output [31:0]  rs1_data,
    output [31:0]  rs2_data,
    output reg [31:0]  imm32,
    output  [31:0]      reg_a7,
    output  [31:0]      output_data,
    output [2:0] funct3,
    output [6:0] funct7,
    output reg [4:0] rd,
    output reg [4:0] rs1,
    output reg [4:0] rs2,

    output reg    branch,
    output reg [1:0] alu_op,
    output reg    alu_src,
    output reg    mem_read,
    output reg    mem_write,
    output reg    mem_to_reg,
    output reg    reg_write,
    output reg    is_jal,
    output reg    is_jalr,
    output reg    is_lui,
    output reg    is_auipc,
    output reg    is_ecall,
    output reg    en_pc,
    output reg    en_output
);
    parameter R_TYPE  = 7'b0110011;
    parameter I_TYPE1 = 7'b0010011;// addi
    parameter I_TYPE2 = 7'b0000011;// lw
    parameter I_TYPE3 = 7'b1100111;// jalr
    parameter I_TYPE4 = 7'b1110011;// ecall  
    parameter S_TYPE  = 7'b0100011;
    parameter B_TYPE  = 7'b1100011;
    parameter U_TYPE1 = 7'b0110111;// lui
    parameter U_TYPE2 = 7'b0010111;// auipc
    parameter J_TYPE  = 7'b1101111;// jal
    
    wire [6:0] opcode = inst[6:0];
    reg    en_input;
    assign rs1_data = regs[rs1];
    assign rs2_data = regs[rs2];

    assign funct3 = inst[14:12];
    assign funct7 = inst[31:25];
    
    assign reg_a7=regs[17];
    assign output_data=regs[10];

    assign reg_write_data = (en_input ? input_data 
        : ( (is_jal || is_jalr) ? pc + 4 : 0));
    assign have_reg_write_data = en_input | is_jal | is_jalr;
    

    always @* begin
        case (opcode)
            I_TYPE1: begin // addi
                imm32 = {{20{inst[31]}}, inst[31:20]};
            end
            I_TYPE2: begin // lw
                imm32 = {{20{inst[31]}}, inst[31:20]};
            end
            I_TYPE3: begin // jalr
                imm32 = {{20{inst[31]}}, inst[31:20]};
            end
            I_TYPE4: begin // ecall
                imm32 = {{20{inst[31]}}, inst[31:20]};
            end
            S_TYPE: begin // sw
                imm32 = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            end
            B_TYPE: begin // beq
                imm32 = {{19{inst[31]}},
                          inst[31], inst[7],
                          inst[30:25], inst[11:8],
                          1'b0};
            end
            J_TYPE: begin // jal
                imm32 = {{11{inst[31]}},
                          inst[31], inst[19:12],inst[20],
                          inst[30:21],
                          1'b0};
            end
            U_TYPE1: begin // lui
                imm32 = {inst[31:12],{12{1'b0}}}; // already << 12
            end
            U_TYPE2: begin // auipc
                imm32 = {inst[31:12],{12{1'b0}}}; // already << 12
            end
            default: begin
                imm32 = 32'd0;
            end
        endcase
    end

    always @(*) begin
        // Default all outputs
        branch      = 0;
        alu_op      = 2'b11;
        alu_src     = 0;
        mem_read    = 0;
        mem_write   = 0;
        mem_to_reg  = 0;
        reg_write   = 0;
        is_jal      = 0;
        is_jalr     = 0;
        is_lui      = 0;
        is_auipc    = 0;
        is_ecall    = 0;
        en_input    = 0;
        en_output   = 0;
        en_pc   = 1;                        
        rs1    = inst[19:15];
        rs2    = inst[24:20];
        rd     = inst[11:7];
        case (opcode)
            R_TYPE: begin
                alu_op     = 2'b10;
                alu_src    = 0;
                reg_write  = 1;
            end
            I_TYPE1: begin
                alu_op     = 2'b11;// check here
                alu_src    = 1;
                reg_write  = 1;
                rs2 = 0;
            end
            I_TYPE2: begin // lw
                alu_op     = 2'b00;
                alu_src    = 1;
                mem_read   = 1;
                mem_to_reg = 1;
                reg_write  = 1;
                rs2 = 0;
            end
            I_TYPE3: begin // jalr
                alu_op     = 2'b11;
                alu_src    = 1;
                reg_write  = 1;
                is_jalr    = 1;
                rs2 = 0;
            end
            I_TYPE4: begin // ecall
                //alu_op     = 2'b11;
                //alu_src    = 1;
                is_ecall   = 1;
                rs2 = 0;
                rs1 = 0;
                if (check_a7) begin
                    is_ecall = 0;
                    case (regs[17])
                        1, 34, 35: begin
                            en_output=1;
                            rd = 0;
                        end
                        5: begin 
                            rd = 10;
                            reg_write=1;
                            en_input=1;
                            if (done_input) en_pc=1;
                            else en_pc=0;
                        end
                        default begin
                            
                        end
                    endcase
                end 
            end
            S_TYPE: begin // sw
                alu_op     = 2'b00;
                alu_src    = 1;
                mem_write  = 1;
                rd = 0;
            end
            B_TYPE: begin // beq, bne, etc.
                alu_op     = 2'b01;
                branch     = 1;
                rd = 0;
            end
            U_TYPE1: begin // lui
                alu_op     = 2'b11;
                alu_src    = 1;
                reg_write  = 1;
                is_lui     = 1;
                rs1 = 0;
                rs2 = 0;
            end
            U_TYPE2: begin // auipc
                alu_op     = 2'b11;
                alu_src    = 1;
                reg_write  = 1;
                is_auipc   = 1;
                rs1 = 0;
                rs2 = 0;
            end
            J_TYPE: begin // jal
                alu_op     = 2'b11; // don't care
                alu_src    = 1; // don't care
                reg_write  = 1;
                is_jal     = 1;
                rs1 = 0;
                rs2 = 0;
            end
            default: begin
                en_pc      = 1;
                rs1 = 0;
                rs2 = 0;
                rd = 0;
                // All control signals remain default
            end
        endcase
        if (rd == 0) reg_write = 0;
    end
        
endmodule
