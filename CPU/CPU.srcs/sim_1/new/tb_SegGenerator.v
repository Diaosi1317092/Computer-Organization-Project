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

  // generate clk_dis pulses every 20 ns
  initial clk_dis = 0;
  always #10 clk_dis = ~clk_dis;

  integer i;
  reg [3:0] expected_sel;
  reg [7:0] expected_an;

  initial begin
    // dump waveform
    $dumpfile("tb_SegGenerator.vcd");
    $dumpvars(0, tb_SegGenerator);

    // apply reset
    rst = 1;
    #25;
    rst = 0;  // release reset, select¡ú0, an¡ú1000_0000
    #25;
    rst = 1;  // release reset, select¡ú0, an¡ú1000_0000

    // verify 10 cycles of clk_dis
    expected_sel = 0;
    expected_an  = 8'b1000_0000;
    for (i = 0; i < 10; i = i + 1) begin
      #20;  // wait for posedge clk_dis
      // compute next expected values
      expected_sel = (expected_sel == 4'd7) ? 4'd0 : expected_sel + 1;
      expected_an  = 8'b1000_0000 >> expected_sel;
      // check select
      if (select !== expected_sel)
        $fatal("Cycle %0d: select = %0d, expected %0d", i, select, expected_sel);
      // check an
      if (an !== expected_an)
        $fatal("Cycle %0d: an = %b, expected %b", i, an, expected_an);
    end

    $display("SegGenerator tests passed");
    #10;
    $finish;
  end

endmodule
