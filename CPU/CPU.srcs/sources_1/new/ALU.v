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

    assign operand2 = (alu_src == 1'b0) ? read_data2 : imm32;

    always @(*) begin
        case (alu_op)
            2'b00: begin // Load/Store: ADD
                alu_result = read_data1 + operand2;
            end

            2'b01: begin // Branch: SUB
                alu_result = read_data1 - operand2;
            end

            2'b10: begin
                case (funct3)
                    3'b000: begin // ADD or SUB
                        if (funct7[5])
                            alu_result = read_data1 - operand2;
                        else
                            alu_result = read_data1 + operand2;
                    end
                    3'b111: begin // AND
                        alu_result = read_data1 & operand2;
                    end
                    3'b110: begin // OR
                        alu_result = read_data1 | operand2;
                    end
                    default: alu_result = 32'h00000000; // unsupported
                endcase
            end

            default: begin
                alu_result = 32'h00000000;
            end
        endcase
    end

    assign zero = (alu_result == 32'b0) ? 1'b1 : 1'b0;

endmodule
