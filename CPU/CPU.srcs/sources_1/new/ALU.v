module ALU(
    input  [31:0] read_data1,
    input  [31:0] read_data2,
    input  [31:0] imm32,
    input         alu_src,
    input  [1:0]  alu_op,
    input  [2:0]  funct3,
    input  [6:0]  funct7,
    output reg [31:0] alu_result,
    output        zero
);

    wire [31:0] operand2;
    wire [4:0] shamt;  // shift amount (only low 5 bits valid for 32-bit)

    assign operand2 = (alu_src == 1'b0) ? read_data2 : imm32;
    assign shamt = operand2[4:0];

    always @(*) begin
        case (alu_op)
            2'b00: begin // Load/Store: ADD
                alu_result = read_data1 + operand2;
            end

            2'b01: begin // Branch: SUB
                alu_result = read_data1 - operand2;
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
            
            2'b11: begin // I-type
                case (funct3)
                    3'b000: begin // ADD or SUB
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
            
            default: alu_result = 32'h00000000;
        endcase
    end

    assign zero = (alu_result == 32'b0) ? 1'b1 : 1'b0;

endmodule
