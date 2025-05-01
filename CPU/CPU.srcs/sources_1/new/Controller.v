module Controller (
    input  [31:0] inst,
    output reg    branch,
    output reg [1:0] alu_op,
    output reg    alu_src,
    output reg    mem_read,
    output reg    mem_write,
    output reg    mem_to_reg,
    output reg    reg_write
);

    // Opcode definitions (parameterized)
    parameter R_TYPE  = 7'b0110011;
    parameter I_TYPE1 = 7'b0010011;
    parameter I_TYPE2 = 7'b0000011;
    parameter I_TYPE3 = 7'b1100111;
    parameter S_TYPE  = 7'b0100011;
    parameter B_TYPE  = 7'b1100011;
    parameter U_TYPE1 = 7'b0110111;
    parameter U_TYPE2 = 7'b0010111;
    parameter J_TYPE  = 7'b1101111;

    wire [6:0] opcode = inst[6:0];

    always @(*) begin
        // Default all outputs
        branch      = 0;
        alu_op      = 2'b11;
        alu_src     = 0;
        mem_read    = 0;
        mem_write   = 0;
        mem_to_reg  = 0;
        reg_write   = 0;

        case (opcode)
            R_TYPE: begin
                alu_op     = 2'b10;
                alu_src    = 0;
                reg_write  = 1;
            end
            I_TYPE1, I_TYPE3: begin
                alu_op     = 2'b11;// check here
                alu_src    = 1;
                reg_write  = 1;
            end
            I_TYPE2: begin // lw
                alu_op     = 2'b00;
                alu_src    = 1;
                mem_read   = 1;
                mem_to_reg = 1;
                reg_write  = 1;
            end
            S_TYPE: begin // sw
                alu_op     = 2'b00;
                alu_src    = 1;
                mem_write  = 1;
            end
            B_TYPE: begin // beq, bne, etc.
                alu_op     = 2'b01;
                branch     = 1;
            end
            U_TYPE1, U_TYPE2: begin // lui, auipc
                alu_op     = 2'b11;
                alu_src    = 1;
                reg_write  = 1;
            end
            J_TYPE: begin // jal
                alu_op     = 2'b11;
                alu_src    = 1;
                reg_write  = 1;
            end
            default: begin
                // All control signals remain default
            end
        endcase
    end

endmodule
