module IFetch(
    input         clk,      // clock signal
    input         rst,      // active-low synchronous reset
    input [31:0]  imm32,    // branch offset (already left-shifted by 1 when generated)
    input         branch,   // 1 if instruction is beq
    input         zero,     // 1 if ALU result is zero (for beq)
    output [31:0] inst      // output instruction
);

    reg [31:0] pc;           // program counter
    wire [13:0] addr;        // address for instruction memory

    // Instantiate the instruction ROM
    prgrom urom(
        .clka(clk),
        .addra(addr),
        .douta(inst)
    );

    // Address connected to lower bits of pc (>>2 because 4 bytes per instruction)
    assign addr = pc[15:2];

    // PC update
    always @(negedge clk, negedge rst) begin
        
        if (!rst) begin
            pc <= 32'h0000_0000;
        end else begin
            //pc <= pc + 32'd4;   // normal sequential execution
            if (branch && zero) begin
                pc <= pc + imm32;   // branch taken
            end else begin
                pc <= pc + 32'd4;   // normal sequential execution
            end
        end
    end

endmodule
