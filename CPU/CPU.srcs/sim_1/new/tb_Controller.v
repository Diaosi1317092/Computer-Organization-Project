`timescale 1ns / 1ps

module tb_Controller;

  // inputs
  reg  [31:0] inst;
  reg  [31:0] reg_a7;
  reg         done_input;

  // outputs
  wire        branch;
  wire [1:0]  alu_op;
  wire        alu_src;
  wire        mem_read;
  wire        mem_write;
  wire        mem_to_reg;
  wire        reg_write;
  wire        is_jal;
  wire        is_jalr;
  wire        is_lui;
  wire        is_auipc;
  wire        is_ecall;
  wire        en_pc;
  wire        en_input;
  wire        en_output;

  // instantiate DUT
  Controller uut (
    .inst       (inst),
    .branch     (branch),
    .alu_op     (alu_op),
    .alu_src    (alu_src),
    .mem_read   (mem_read),
    .mem_write  (mem_write),
    .mem_to_reg (mem_to_reg),
    .reg_write  (reg_write),
    .is_jal     (is_jal),
    .is_jalr    (is_jalr),
    .is_lui     (is_lui),
    .is_auipc   (is_auipc),
    .is_ecall   (is_ecall),
    .en_pc      (en_pc),
    .en_input   (en_input),
    .en_output  (en_output),
    .reg_a7     (reg_a7),
    .done_input (done_input)
  );

  initial begin
    // dump waveform
    $dumpfile("tb_Controller.vcd");
    $dumpvars(0, tb_Controller);

    // ----- Test R_TYPE -----
    inst = {25'd0, 7'b0110011};  // R_TYPE opcode
    #1;
    if (alu_op !== 2'b10 || reg_write !== 1) $fatal("R_TYPE failed");

    // ----- Test ADDI (I_TYPE1) -----
    inst = {20'd0, 5'd1, 3'b000, 5'd2, 7'b0010011};
    #1;
    if (alu_src !== 1 || alu_op !== 2'b11 || reg_write !== 1) $fatal("ADDI failed");

    // ----- Test LW (I_TYPE2) -----
    inst = {20'd0, 5'd3, 3'b010, 5'd4, 7'b0000011};
    #1;
    if (!(mem_read && mem_to_reg && reg_write && alu_src==1 && alu_op==2'b00))
      $fatal("LW failed");

    // ----- Test JALR (I_TYPE3) -----
    inst = {20'd0, 5'd5, 3'b000, 5'd6, 7'b1100111};
    #1;
    if (!(is_jalr && reg_write && alu_src && alu_op==2'b11)) $fatal("JALR failed");

    // ----- Test ECALL output -----
    inst = {25'd0, 7'b1110011};  // I_TYPE4: ecall
    reg_a7 = 32'd1; done_input = 0;
    #1;
    if (!is_ecall || en_output!==1) $fatal("ECALL output failed");

    // ----- Test ECALL input busy -----
    reg_a7 = 32'd5; done_input = 0;
    #1;
    if (!(is_ecall && en_input && en_pc==0)) $fatal("ECALL input busy failed");

    // ----- Test ECALL input done -----
    done_input = 1;
    #1;
    if (en_pc!==1) $fatal("ECALL input done failed");

    // ----- Test SW (S_TYPE) -----
    inst = {20'd0, 5'd7, 5'd8, 3'b010, 5'd0, 7'b0100011};
    #1;
    if (!(mem_write && alu_src && alu_op==2'b00)) $fatal("SW failed");

    // ----- Test BEQ (B_TYPE) -----
    inst = {7'b0000000, 5'd0, 5'd0, 3'b000, 4'b0000, 1'b0, 7'b1100011};
    #1;
    if (!(branch && alu_op==2'b01)) $fatal("BEQ failed");

    // ----- Test LUI (U_TYPE1) -----
    inst = {20'hABCD0, 5'd0, 7'b0110111};
    #1;
    if (!(is_lui && reg_write && alu_src)) $fatal("LUI failed");

    // ----- Test AUIPC (U_TYPE2) -----
    inst = {20'h10000, 5'd0, 7'b0010111};
    #1;
    if (!(is_auipc && reg_write && alu_src)) $fatal("AUIPC failed");

    // ----- Test JAL (J_TYPE) -----
    inst = {20'd0,5'd0,3'b000,5'd0,7'b1101111};
    #1;
    if (!(is_jal && reg_write)) $fatal("JAL failed");

    $display("All Controller tests passed");
    #1; $finish;
  end

endmodule
