module Controller (
    input  [31:0] inst,
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
    output reg    en_input,
    output reg    en_output,
    input [31:0]   reg_a7,
    input         done_input
);

    // Opcode definitions (parameterized)
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
            end
            I_TYPE2: begin // lw
                alu_op     = 2'b00;
                alu_src    = 1;
                mem_read   = 1;
                mem_to_reg = 1;
                reg_write  = 1;
            end
            I_TYPE3: begin // jalr
                alu_op     = 2'b11;
                alu_src    = 1;
                reg_write  = 1;
                is_jalr    = 1;
            end
            I_TYPE4: begin // ecall
                //alu_op     = 2'b11;
                //alu_src    = 1;
                is_ecall   = 1;
                case (reg_a7)
                    1, 34, 35: begin
                        en_output=1;
                    end
                    5: begin 
                        reg_write=1;
                        en_input=1;
                        if (done_input) en_pc=1;
                        else en_pc=0;
                    end
                    default begin
                        
                    end
                endcase 
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
            U_TYPE1: begin // lui
                alu_op     = 2'b11;
                alu_src    = 1;
                reg_write  = 1;
                is_lui     = 1;
            end
            U_TYPE2: begin // auipc
                alu_op     = 2'b11;
                alu_src    = 1;
                reg_write  = 1;
                is_auipc   = 1;
            end
            J_TYPE: begin // jal
                alu_op     = 2'b11; // don't care
                alu_src    = 1; // don't care
                reg_write  = 1;
                is_jal     = 1;
            end
            default: begin
                // All control signals remain default
            end
        endcase
    end

endmodule
