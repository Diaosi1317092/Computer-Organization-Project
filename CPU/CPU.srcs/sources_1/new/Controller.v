module Controller(
    input  [31:0] inst,
    output reg branch,
    output reg mem_read,
    output reg mem_write,
    output reg mem_to_reg,
    output reg reg_write,
    output reg alu_src,
    output reg [1:0] alu_op
);

    wire [6:0] opcode = inst[6:0];

    always @* begin
        branch     = 0;
        mem_read   = 0;
        mem_write  = 0;
        mem_to_reg = 0;
        reg_write  = 0;
        alu_src    = 0;
        alu_op     = 2'b11;

        case (opcode)
            7'b0000011: begin // lw
                mem_read   = 1;
                mem_to_reg = 1;
                reg_write  = 1;
                alu_src    = 1;
                alu_op     = 2'b00;
            end
            7'b0100011: begin // sw
                mem_write = 1;
                alu_src   = 1;
                alu_op    = 2'b00;
            end
            7'b1100011: begin // beq
                branch  = 1;
                alu_op  = 2'b01;
            end
            7'b0110011: begin // R-type: add, sub, and, or
                reg_write = 1;
                alu_src   = 0;
                alu_op    = 2'b10;
            end
            default: begin
            end
        endcase
    end

endmodule
