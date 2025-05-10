`timescale 1ns / 1ps

module tb_ALU;

  // inputs
  reg  [31:0] read_data1;
  reg  [31:0] read_data2;
  reg  [31:0] imm32;
  reg         alu_src;
  reg  [1:0]  alu_op;
  reg  [2:0]  funct3;
  reg  [6:0]  funct7;
  reg         is_lui;
  reg         is_auipc;
  reg  [31:0] pc;

  // outputs
  wire [31:0] alu_result;
  wire        zero;

  // instantiate ALU
  ALU uut (
    .read_data1(read_data1),
    .read_data2(read_data2),
    .imm32     (imm32),
    .alu_src   (alu_src),
    .alu_op    (alu_op),
    .funct3    (funct3),
    .funct7    (funct7),
    .alu_result(alu_result),
    .zero      (zero),
    .is_lui    (is_lui),
    .is_auipc  (is_auipc),
    .pc        (pc)
  );

  initial begin
    // dump waveform
    $dumpfile("tb_ALU.vcd");
    $dumpvars(0, tb_ALU);

    // ------ Test 1: ADD (load/store) ------
    alu_src   = 0;
    alu_op    = 2'b00;          // ADD opcode
    read_data1= 32'd15;
    read_data2= 32'd27;
    #1;
    if (alu_result !== 42) $fatal("ADD failed: got %0d", alu_result);

    // ------ Test 2: BEQ zero detection ------
    alu_src   = 0;
    alu_op    = 2'b01;          // SUB/branch
    funct3    = 3'b000;         // beq
    read_data1= 32'd100;
    read_data2= 32'd100;
    #1;
    if (zero !== 1) $fatal("BEQ zero failed");

    // ------ Test 3: R-type SLL ------
    alu_src   = 0;
    alu_op    = 2'b10;          // R-type
    funct3    = 3'b001;         // SLL
    funct7    = 7'd0;
    read_data1= 32'h0000_0001;
    read_data2= 32'd4;          // shamt=4
    #1;
    if (alu_result !== 16) $fatal("SLL failed");

    // ------ Test 4: R-type SRA ------
    alu_src   = 0;
    alu_op    = 2'b10;          // R-type
    funct3    = 3'b101;         // SRL/SRA
    funct7    = 7'b0100000;     // arithmetic
    read_data1= -32'sd8;
    read_data2= 32'd2;
    #1;
    if (alu_result !== -2) $fatal("SRA failed");

    // ------ Test 5: I-type ANDI ------
    alu_src   = 1;
    alu_op    = 2'b11;          // I-type
    funct3    = 3'b111;         // ANDI
    funct7    = 7'd0;
    read_data1= 32'hF0F0_F0F0;
    imm32     = 32'h0F0F_0F0F;
    #1;
    if (alu_result !== 32'h0000_0000) $fatal("ANDI failed");

    // ------ Test 6: LUI ------
    alu_src   = 1;
    alu_op    = 2'b11;          // U-type
    is_lui    = 1;
    imm32     = 32'h1234_0000;  // imm << 12
    pc        = 32'd0;
    #1;
    if (alu_result !== 32'h1234_0000) $fatal("LUI failed");
    is_lui    = 0;

    // ------ Test 7: AUIPC ------
    alu_src   = 1;
    alu_op    = 2'b11;
    is_auipc  = 1;
    imm32     = 32'h0000_1000;  // imm << 12
    pc        = 32'h0000_2000;
    #1;
    if (alu_result !== 32'h0000_3000) $fatal("AUIPC failed");

    $display("All ALU tests passed");
    #1;
    $finish;
  end

endmodule
