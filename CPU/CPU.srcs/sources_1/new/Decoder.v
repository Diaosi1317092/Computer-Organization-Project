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
    parameter R_TYPE  = 7'b0110011;
    parameter I_TYPE1 = 7'b0010011;// addi
    parameter I_TYPE2 = 7'b0000011;// lw
    parameter I_TYPE3 = 7'b1100111;// jalr
    parameter S_TYPE  = 7'b0100011;
    parameter B_TYPE  = 7'b1100011;
    parameter U_TYPE1 = 7'b0110111;// lui
    parameter U_TYPE2 = 7'b0010111;// auipc
    parameter J_TYPE  = 7'b1101111;// jal
    
    wire [4:0] rs1    = inst[19:15];
    wire [4:0] rs2    = inst[24:20];
    wire [4:0] rd     = inst[11:7];
    wire [6:0] opcode = inst[6:0];

    reg [31:0] regs [0:31];
    integer i;

    always @(posedge clk, negedge rst) begin
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
            I_TYPE1: begin // addi
                imm32 = {{20{inst[31]}}, inst[31:20]};
            end
            I_TYPE2: begin // lw
                imm32 = {{20{inst[31]}}, inst[31:20]};
            end
            I_TYPE3: begin // jalr
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

endmodule
