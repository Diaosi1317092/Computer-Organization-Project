`timescale 1ns / 1ps

module tb_ClockDivider;

  reg         clk;
  reg         rst;
  reg [31:0]  period;

  wire        clk_out;

  // Instantiate DUT
  ClockDivider uut (
    .clk     (clk),
    .rst     (rst),
    .period  (period),
    .clk_out (clk_out)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $dumpfile("tb_ClockDivider.vcd");
    $dumpvars(0, tb_ClockDivider);

    rst    = 0;
    period = 32'd20;   // output clk toggles every (20/2)=10 cycles -> 100 ns period
    #10;
    rst    = 1;

    #500;

    period = 32'd10;   // output clk toggles every (10/2)=5 cycles -> 50 ns period
    #500;

    $finish;
  end

endmodule
