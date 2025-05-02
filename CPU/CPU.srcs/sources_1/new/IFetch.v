module IFetch(
    input         clk,      // clock signal
    input         rst,      // active-low synchronous reset
    input [31:0]  imm32,    // branch offset (already left-shifted by 1 when generated)
    input         branch,   // 1 if instruction is beq
    input         zero,     // 1 if ALU result is zero (for beq)
    input         is_jal, 
    output [31:0] inst,      // output instruction
    output reg [31:0] out_pc,
    input         is_jalr,
    input [31:0]  new_pc
);

    reg [31:0] pc;           // program counter
    wire [13:0] addr;        // address for instruction memory

    // Instantiate the instruction ROM
    prgrom urom(
        .clka(clk),
        .addra(addr),
        .douta(inst)
    );
    
    always @(posedge clk) begin
        out_pc<=pc;
    end
    
//    // PC update
//    always @(negedge clk, negedge rst) begin
//        if (!rst) begin
//            pc <= 32'h0000_3000;
//        end else begin
//            //pc <= pc + 32'd4;   // normal sequential execution
//            if (is_jalr) begin
//                pc <= new_pc;
//            end else if (branch && zero || is_jal) begin
//                pc <= pc + imm32;   // branch taken
//            end else begin
//                pc <= pc + 32'd4;   // normal sequential execution
//            end
//        end
//    end
    
    parameter base_address = 32'h0000_3000;
    reg[31:0] next_pc;
    // Address connected to lower bits of pc (>>2 because 4 bytes per instruction)
    assign addr = (pc[13:0]-base_address) >> 2;
    
    always @(*) begin
        if (is_jalr) begin
            next_pc = new_pc;
        end else if (branch && zero || is_jal) begin
            next_pc = pc + imm32;   // branch taken
        end else begin
            next_pc = pc + 32'd4;   // normal sequential execution
        end
    end
    
    always @(negedge clk, negedge rst) begin
        if(~rst) begin
            pc <= base_address;
        end else begin
            pc <= next_pc;
        end
    end

endmodule
