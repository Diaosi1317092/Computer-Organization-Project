`timescale 1ns / 1ps

module tb_InputModule;

  // inputs
  reg        clk;
  reg        clk_de;
  reg        rst;
  reg  [7:0] sw_input;
  reg        done;

  // outputs
  wire [31:0] input_data;
  wire        done_input;

  // instantiate DUT
  InputModule uut (
    .clk        (clk),
    .clk_de     (clk_de),
    .rst        (rst),
    .sw_input   (sw_input),
    .done       (done),
    .input_data (input_data),
    .done_input (done_input)
  );

  // 100 MHz main clock
  initial clk = 0;
  always #5 clk = ~clk;

  // 1 MHz debounce clock
  initial clk_de = 0;
  always #500 clk_de = ~clk_de;

  initial begin
    // waveform dump
    $dumpfile("tb_InputModule.vcd");
    $dumpvars(0, tb_InputModule);

    // apply reset
    rst = 0; done = 0; sw_input = 8'h00;
    #20;
    rst = 1;

    // test sign-extension of sw_input
    sw_input = 8'hF0;  #10;
    if (input_data !== 32'hFFFF_FFF0) $fatal("Sign-ext failed");

    sw_input = 8'h7A;  #10;
    if (input_data !== 32'h0000_007A) $fatal("Zero-ext fail");

    // test done debounce: short glitch (< threshold)
    // assert done for one clk_de cycle ¡ú stable since threshold=1
    done = 1;  #1000;
    done = 0;  #1000;
    if (done_input !== 1) $fatal("Debounce fail: first pulse");

    // further pulses ignored until cleared
    done = 1;  #1000;
    done = 0;  #1000;
    if (done_input !== 0) $fatal("Debounce fail: should clear after one");

    // second valid pulse after release
    done = 1;  #1000;
    done = 0;  #1000;
    if (done_input !== 1) $fatal("Debounce fail: second pulse");

    $display("All InputModule tests passed");
    #100;
    $finish;
  end

endmodule
