`timescale 1ns / 1ps

module tb_Decoder;

  // inputs
  reg         clk;
  reg         rst_n;
  reg         reg_write;
  reg         en_pc;
  reg  [31:0] inst;
  reg  [31:0] write_data;
  reg         en_input;
  reg         en_output;
  reg         branch;
  reg         zero;
  reg         is_jal;
  reg         is_jalr;
  reg  [31:0] new_pc;

  // outputs
  wire [31:0] output_data;
  wire [31:0] rs1_data;
  wire [31:0] rs2_data;
  wire [31:0] reg_a7;
  wire [31:0] imm32;

  // instantiate DUT
  Decoder uut (
    .clk       (clk),
    .rst       (rst_n),
    .reg_write (reg_write),
    .en_pc     (en_pc),
    .inst      (inst),
    .write_data(write_data),
    .en_input  (en_input),
    .en_output (en_output),
    .output_data(output_data),
    .rs1_data  (rs1_data),
    .rs2_data  (rs2_data),
    .reg_a7    (reg_a7),
    .imm32     (imm32)
  );

  // generate 50?MHz clock
  initial clk = 0;
  always #10 clk = ~clk;

  initial begin
    // dump waveform
    $dumpfile("tb_Decoder.vcd");
    $dumpvars(0, tb_Decoder);

    // reset
    rst_n      = 0;
    reg_write  = 0;
    en_pc      = 1;
    en_input   = 0;
    en_output  = 0;
    branch     = 0;
    zero       = 0;
    is_jal     = 0;
    is_jalr    = 0;
    inst       = 32'd0;
    write_data = 32'd0;
    #25;
    rst_n = 1;  // release reset

    // opcode = I_TYPE1, rd=5, rs1=0, imm=10
    inst = {10'b0000000000, 5'd0, 3'b000, 5'd5, 7'b0010011};
    inst[31:20] = 12'd10;
    #20;
    if (imm32 !== 32'd10) $display("ADDI imm error: got %d", imm32);

    // write result to rd
    write_data = 32'd42;
    reg_write  = 1;
    #20;
    reg_write  = 0;
    if (rs1_data !== 32'd0) $display("RS1 read error");
    if (uut.regs[5] !== 32'd42) $display("Reg write error: x5 != 42");

    // S_TYPE sw x2, 20(x3)
    inst = {7'b0100011, 5'd2, 5'd3, 3'b010, 5'd0, 7'b0000000};
    inst[31:25] = 7'd0;
    inst[11:7]  = 5'd20;
    #20;
    if (imm32 !== 32'd20) $display("SW imm error: got %d", imm32);

    // B_TYPE beq x4, x4, offset=8
    inst = {inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
    inst[31]    = 1'b0;
    inst[7]     = 1'b0;
    inst[30:25] = 6'd0;
    inst[11:8]  = 4'd4;
    branch = 1; zero = 1;
    #20;
    if (imm32 !== 32'd8) $display("BEQ imm error: got %d", imm32);
    branch = 0; zero = 0;

    // finish
    #20;
    $finish;
  end

endmodule
