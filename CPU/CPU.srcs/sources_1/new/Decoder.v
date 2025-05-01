module Decoder(
    input              clk,
    input              rst,
    input              reg_write,
    input  [31:0]      inst,
    input  [31:0]      write_data,

    output reg [31:0]  rs1_data,
    output reg [31:0]  rs2_data,
    output reg [31:0]  imm32
);

    wire [4:0] rs1    = inst[19:15];
    wire [4:0] rs2    = inst[24:20];
    wire [4:0] rd     = inst[11:7];
    wire [6:0] opcode = inst[6:0];

    reg [31:0] regs [0:31];
    integer i;

    always @(posedge clk) begin
        if (!rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'h00000000;
        end else if (reg_write && (rd != 5'd0)) begin
            regs[rd] <= write_data;
        end
    end

    always @* begin
        rs1_data = regs[rs1];
        rs2_data = regs[rs2];
    end

    always @* begin
        case (opcode)
            7'b0000011: begin // lw
                imm32 = {{20{inst[31]}}, inst[31:20]};
            end
            7'b0010011: begin // addi
                imm32 = {{20{inst[31]}}, inst[31:20]};
            end
            7'b0100011: begin // sw
                imm32 = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            end
            7'b1100011: begin // beq
                imm32 = {{19{inst[31]}},
                          inst[31], inst[7],
                          inst[30:25], inst[11:8],
                          1'b0};
            end
            default: begin
                imm32 = 32'd0;
            end
        endcase
    end

endmodule
