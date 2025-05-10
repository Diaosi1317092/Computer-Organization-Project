`timescale 1ns / 1ps

module tb_DMem;

  // signals
  reg         clk;
  reg         mem_read;
  reg         mem_write;
  reg  [31:0] addr;
  reg  [31:0] din;
  reg  [2:0]  funct3;
  reg         en_pc;
  wire [31:0] dout;

  // instantiate DUT
  DMem uut (
    .clk       (clk),
    .mem_read  (mem_read),
    .mem_write (mem_write),
    .addr      (addr),
    .din       (din),
    .funct3    (funct3),
    .dout      (dout),
    .en_pc     (en_pc)
  );

  // clock: 50 MHz
  initial clk = 0;
  always #10 clk = ~clk;

  initial begin
    // dump waveform
    $dumpfile("tb_DMem.vcd");
    $dumpvars(0, tb_DMem);

    // Test SW: write full word
    en_pc     = 1;
    mem_write = 1;
    funct3    = 3'b010;       // SW
    addr      = 32'h0000_0004;
    din       = 32'hDEAD_BEEF;
    #20;
    mem_write = 0;
    mem_read  = 1;
    #20;
    $display("SW readback at 0x4 = %h", dout);

    // Test SH lower half
    mem_read  = 0;
    mem_write = 1;
    funct3    = 3'b001;       // SH
    addr      = 32'h0000_0008; // addr[1]=0
    din       = 32'h0000_1234;
    #20;
    mem_write = 0;
    mem_read  = 1;
    #20;
    $display("SH lower at 0x8 = %h", dout);

    // Test SH upper half
    mem_read  = 0;
    mem_write = 1;
    addr      = 32'h0000_000A; // addr[1]=1
    #20;
    mem_write = 0;
    mem_read  = 1;
    #20;
    $display("SH upper at 0xA = %h", dout);

    // Test SB byte 0
    mem_read  = 0;
    mem_write = 1;
    funct3    = 3'b000;       // SB
    addr      = 32'h0000_000C; // addr[1:0]=00
    din       = 32'h0000_00AA;
    #20;
    mem_write = 0;
    mem_read  = 1;
    #20;
    $display("SB at byte0 0xC = %h", dout);

    // Test SB byte 3
    mem_read  = 0;
    mem_write = 1;
    addr      = 32'h0000_000F; // addr[1:0]=11
    #20;
    mem_write = 0;
    mem_read  = 1;
    #20;
    $display("SB at byte3 0xF = %h", dout);

    $finish;
  end

endmodule
