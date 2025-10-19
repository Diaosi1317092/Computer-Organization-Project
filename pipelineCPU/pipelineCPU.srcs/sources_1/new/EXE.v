`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/14 18:37:57
// Design Name: 
// Module Name: EXE
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


module EXE(
    input [31:0] reg_write_data_in,
    output [31:0] reg_write_data_out,
    input have_reg_write_data_in,
    output have_reg_write_data_out,
    
    input  [31:0] read_data1,
    input  [31:0] read_data2,
    input  [31:0] imm32,
    input         alu_src,
    input  [1:0]  alu_op,
    input         mem_to_reg,
    input  [2:0]  funct3,
    input  [6:0]  funct7,
    output reg [31:0] alu_result,
    output reg    zero,
    input         is_lui,
    input         is_auipc,
    input         branch,
    input         is_jal,
    input         is_jalr,
    input [31:0]  pc,
    output reg [31:0] true_pc,
    input [31:0] predicted_pc,
    output reg check_predicted
);
    wire [31:0] operand2;
    wire [4:0] shamt;  // shift amount (only low 5 bits valid for 32-bit)

    assign operand2 = (alu_src == 1'b0) ? read_data2 : imm32;
    assign shamt = operand2[4:0];

    assign reg_write_data_out = have_reg_write_data_in ? reg_write_data_in : 
        (mem_to_reg ? 0 : alu_result);
    
    assign have_reg_write_data_out = have_reg_write_data_in | !mem_to_reg;
    always @(*) begin
        if (branch) begin
            true_pc = zero ? pc + imm32 : pc + 4;
            check_predicted = (true_pc == predicted_pc);
        end else if (is_jal) begin
            true_pc = pc + imm32;
            check_predicted = (true_pc == predicted_pc);
        end else if (is_jalr) begin
            true_pc = alu_result;
            check_predicted = (true_pc == predicted_pc);
        end else begin
            check_predicted = 1;
            true_pc = predicted_pc;
        end
    end
    always @(*) begin
        case (alu_op)
            2'b00: begin // Load/Store: ADD
                alu_result = read_data1 + operand2;
            end

            2'b01: begin // Branch: SUB
                alu_result = read_data1 - operand2;
                case (funct3)
                    3'b000: begin // beq
                        zero = (read_data1 - operand2 == 32'b0) ? 1'b1 : 1'b0;
                    end
                    3'b001: begin // bne
                        zero = (read_data1 - operand2 == 32'b0) ? 1'b0 : 1'b1;
                    end
                    3'b100: begin // blt
                        zero = ($signed(read_data1) < $signed(operand2)) ? 1'b1 : 1'b0;
                    end
                    3'b101: begin // bge
                        zero = ($signed(read_data1) < $signed(operand2)) ? 1'b0 : 1'b1;
                    end
                    3'b110: begin // bltu
                        zero = (read_data1 < operand2) ? 1'b1 : 1'b0;
                    end
                    3'b111: begin // bgeu
                        zero = (read_data1 < operand2) ? 1'b0 : 1'b1;
                    end
                    default: zero = 1'b0;
                endcase
            end

            2'b10: begin // R-type
                case (funct3)
                    3'b000: begin // ADD or SUB
                        if (funct7[5])
                            alu_result = read_data1 - operand2;
                        else
                            alu_result = read_data1 + operand2;
                    end
                    3'b100: begin // XOR
                        alu_result = read_data1 ^ operand2;
                    end
                    3'b110: begin // OR
                        alu_result = read_data1 | operand2;
                    end
                    3'b111: begin // AND
                        alu_result = read_data1 & operand2;
                    end
                    3'b001: begin // SLL
                        alu_result = read_data1 << shamt;
                    end
                    3'b101: begin // SRL or SRA
                        if (funct7[5])
                            alu_result = $signed(read_data1) >>> shamt; // SRA (arithmetic)
                        else
                            alu_result = read_data1 >> shamt;           // SRL (logical)
                    end
                    3'b010: begin // SLT
                        alu_result = ($signed(read_data1) < $signed(operand2)) ? 32'd1 : 32'd0;
                    end
                    3'b011: begin // SLTU
                        alu_result = (read_data1 < operand2) ? 32'd1 : 32'd0;
                    end
                    default: alu_result = 32'h00000000;
                endcase
            end
            
            2'b11: begin // I-type and U-type
                if (is_lui) begin
                    alu_result = operand2; // already << 12 in imm_gen
                end else if (is_auipc) begin
                    alu_result = pc + operand2; // already << 12 in imm_gen
                end else begin
                    case (funct3)
                        3'b000: begin // ADDI
                            alu_result = read_data1 + operand2;
                        end
                        3'b100: begin // XORI
                            alu_result = read_data1 ^ operand2;
                        end
                        3'b110: begin // ORI
                            alu_result = read_data1 | operand2;
                        end
                        3'b111: begin // ANDI
                            alu_result = read_data1 & operand2;
                        end
                        3'b001: begin // SLLI
                            alu_result = read_data1 << shamt;
                        end
                        3'b101: begin // SRLI
                            if (funct7[5])
                                alu_result = $signed(read_data1) >>> shamt; // SRAI (arithmetic)
                            else
                                alu_result = read_data1 >> shamt;           // SRLI (logical)
                        end
                        3'b010: begin // SLTI
                            alu_result = ($signed(read_data1) < $signed(operand2)) ? 32'd1 : 32'd0;
                        end
                        3'b011: begin // SLTIU
                            alu_result = (read_data1 < operand2) ? 32'd1 : 32'd0;
                        end
                        default: alu_result = 32'h00000000;
                    endcase
                end
            end
            
            default: begin 
                alu_result = 32'h00000000;
            end
        endcase
    end

endmodule
