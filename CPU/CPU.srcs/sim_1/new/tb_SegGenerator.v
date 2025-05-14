`timescale 1ns / 1ps

module tb_SegGenerator;

  // inputs
  reg rst;       
  reg clk_dis;   

  // outputs
  wire [3:0] select;
  wire [7:0] an;

  // instantiate DUT
  SegGenerator uut (
    .rst     (rst),
    .clk_dis (clk_dis),
    .select  (select),
    .an      (an)
  );

  // clk_dis: toggle every 10 ns ¡ú 50 MHz display clock
  initial clk_dis = 0;
  always #10 clk_dis = ~clk_dis;

  integer i;
  reg [3:0] expected_sel;
  reg [7:0] expected_an;

  initial begin
    // dump waveforms
    $dumpfile("tb_SegGenerator.vcd");
    $dumpvars(0, tb_SegGenerator);

    // apply active-low reset: assert low, then release high
    rst = 0;        // assert reset
    #20;
    rst = 1;        // release reset
    #1;
    // after release, before any clk_dis, select should be 0
    if (select !== 4'd0 || an !== 8'b10000000)
      $fatal("After reset: select=%0d an=%b, expected 0 and 10000000", select, an);

    // now step through several clk_dis edges
    expected_sel = 4'd0;
    expected_an  = 8'b10000000;

    for (i = 1; i <= 10; i = i + 1) begin
      #20;  // wait one display-clock tick
      // compute next expected
      expected_sel = (expected_sel == 4'd7) ? 4'd0 : expected_sel + 1;
      expected_an  = 8'b10000000 >> expected_sel;

      // check DUT outputs
      if (select !== expected_sel)
        $fatal("Cycle %0d: select=%0d, expected=%0d", i, select, expected_sel);
      if (an !== expected_an)
        $fatal("Cycle %0d: an=%b, expected=%b", i, an, expected_an);
    end

    $display("SegGenerator tests passed");
    #10;
    $finish;
  end

endmodule
