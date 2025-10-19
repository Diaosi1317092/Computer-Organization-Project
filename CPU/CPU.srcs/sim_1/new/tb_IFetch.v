`timescale 1ns / 1ps

// Stub for instruction memory: outputs its address as instruction data
module prgrom (
    input          clka,
    input  [13:0]  addra,
    output [31:0]  douta
);
    assign douta = {18'd0, addra};  // inst = zero-extended addr
endmodule

module tb_IFetch;
  // inputs
  reg         clk;
  reg         rst;
  reg [31:0]  imm32;
  reg         branch;
  reg         zero;
  reg         is_jal;
  reg         is_jalr;
  reg [31:0]  new_pc;
  reg         en_pc;

  // outputs
  wire [31:0] inst;
  wire [31:0] out_pc;

  // Instantiate DUT
  IFetch uut (
    .clk     (clk),
    .rst     (rst),
    .imm32   (imm32),
    .branch  (branch),
    .zero    (zero),
    .is_jal  (is_jal),
    .is_jalr (is_jalr),
    .new_pc  (new_pc),
    .en_pc   (en_pc),
    .inst    (inst),
    .out_pc  (out_pc)
  );

  // clock gen: 50 MHz
  initial clk = 0;
  always #10 clk = ~clk;

  initial begin
    // dump waves
    $dumpfile("tb_IFetch.vcd");
    $dumpvars(0, tb_IFetch);

    // init
    rst      = 0;
    en_pc    = 1;
    branch   = 0;
    zero     = 0;
    is_jal   = 0;
    is_jalr  = 0;
    imm32    = 32'd4;
    new_pc   = 32'h0000_4000;

    #25;
    rst = 1;

    // normal increment: PC=0x3000, next=0x3004
    #20;
    $display("PC = %h, inst = %h", out_pc, inst);

    // branch taken: PC += imm32 (4)
    branch = 1; zero = 1; imm32 = 32'd16;
    #20;
    $display("BRANCH¡ú PC = %h", out_pc);
    branch = 0; zero = 0;

    // jal: PC += imm32
    is_jal = 1; imm32 = 32'd32;
    #20;
    $display("JAL    ¡ú PC = %h", out_pc);
    is_jal = 0;

    // freeze PC: en_pc=0
    en_pc = 0; imm32 = 32'd100;
    #20;
    $display("FROZEN ¡ú PC = %h", out_pc);
    en_pc = 1;

    // jalr: PC = new_pc
    is_jalr = 1; new_pc = 32'h0000_5000;
    #20;
    $display("JALR   ¡ú PC = %h", out_pc);
    is_jalr = 0;

    // finish
    #20;
    $finish;
  end
endmodule