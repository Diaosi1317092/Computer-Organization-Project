`timescale 1ns / 1ps

module tb_WriteBackMUX;

  // inputs
  reg         mem_to_reg;
  reg  [31:0] mem_read_data;
  reg  [31:0] alu_result;
  reg  [31:0] input_data;
  reg         en_input;
  reg         done_input;
  reg  [2:0]  funct3;
  reg  [31:0] addr;
  reg         is_jal;
  reg         is_jalr;
  reg  [31:0] pc;

  // output
  wire [31:0] reg_write_data;

  // instantiate DUT
  WriteBackMUX uut (
    .mem_to_reg     (mem_to_reg),
    .mem_read_data  (mem_read_data),
    .alu_result     (alu_result),
    .input_data     (input_data),
    .en_input       (en_input),
    .done_input     (done_input),
    .funct3         (funct3),
    .addr           (addr),
    .is_jal         (is_jal),
    .is_jalr        (is_jalr),
    .pc             (pc),
    .reg_write_data (reg_write_data)
  );

  initial begin
    $dumpfile("tb_WriteBackMUX.vcd");
    $dumpvars(0, tb_WriteBackMUX);
    
    // initialize all control inputs
    en_input    = 0;
    done_input  = 0;
    is_jal      = 0;
    is_jalr     = 0;

    // base data
    mem_read_data = 32'hAABBCCDD;
    alu_result    = 32'h12345678;
    input_data    = 32'hCAFEBABE;
    pc            = 32'h00001000;

    // -- test LW --
    mem_to_reg = 1; funct3 = 3'b010; addr = 32'd0;
    #1; if (reg_write_data !== mem_read_data) $fatal("LW failed");

    // -- test LB signed at byte 0 --
    funct3 = 3'b000; addr = 32'd2;
    #1; if (reg_write_data !== {{24{mem_read_data[23]}}, mem_read_data[23:16]})
          $fatal("LB failed");

    // -- test LBU unsigned at byte 3 --
    funct3 = 3'b100; addr = 32'd3;
    #1; if (reg_write_data !== {24'b0, mem_read_data[31:24]})
          $fatal("LBU failed");

    // -- test LH signed lower half --
    funct3 = 3'b001; addr = 32'd0;
    #1; if (reg_write_data !== {{16{mem_read_data[15]}}, mem_read_data[15:0]})
          $fatal("LH failed");

    // -- test LHU unsigned upper half --
    funct3 = 3'b101; addr = 32'd2;
    #1; if (reg_write_data !== {16'b0, mem_read_data[31:16]})
          $fatal("LHU failed");

    // -- test ALU result pass-through --
    mem_to_reg = 0;
    #1; if (reg_write_data !== alu_result) $fatal("ALU path failed");

    // -- test JAL/JALR override --
    is_jal = 1; is_jalr = 0;
    #1; if (reg_write_data !== pc + 4) $fatal("JAL failed");
    is_jal = 0; is_jalr = 1;
    #1; if (reg_write_data !== pc + 4) $fatal("JALR failed");
    is_jalr = 0;

    // -- test input device write-back --
    mem_to_reg = 0;
    en_input   = 1; done_input = 0;
    #1; if (reg_write_data !== alu_result) $fatal("input hold failed");
    done_input = 1;
    #1; if (reg_write_data !== input_data) $fatal("input done failed");

    $display("All WriteBackMUX tests passed");
    #1 $finish;
  end

endmodule
