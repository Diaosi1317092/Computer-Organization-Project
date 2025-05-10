`timescale 1ns / 1ps

module tb_SegDisplay;

  // inputs
  reg  [31:0] reg_a7;
  reg  [31:0] val;
  reg  [3:0]  select;

  // outputs
  wire [7:0] led;
  wire [7:0] seg1;
  wire [7:0] seg2;

  // instantiate DUT
  SegDisplay uut (
    .reg_a7 (reg_a7),
    .val    (val),
    .select (select),
    .led    (led),
    .seg1   (seg1),
    .seg2   (seg2)
  );

  initial begin
    // dump waveforms
    $dumpfile("tb_SegDisplay.vcd");
    $dumpvars(0, tb_SegDisplay);

    // ----- Test decimal display (reg_a7 = 1) -----
    reg_a7 = 32'd1;
    val    = 32'd12345678;   // eight-digit decimal
    for (select = 0; select < 8; select = select + 1) begin
      #1;
      $display("DEC sel=%0d: seg1=%b seg2=%b led=%b",
               select, seg1, seg2, led);
    end

    // ----- Test hex display (reg_a7 = 34) -----
    reg_a7 = 32'd34;
    val    = 32'hDEADBEEF;    // eight-nibble hex
    for (select = 0; select < 8; select = select + 1) begin
      #1;
      $display("HEX sel=%0d: seg1=%b seg2=%b led=%b",
               select, seg1, seg2, led);
    end

    // ----- Test LED output (reg_a7 = 35) -----
    reg_a7 = 32'd35;
    val    = 32'h000000FF;    // low 8 bits to LEDs
    for (select = 0; select < 2; select = select + 1) begin
      #1;
      $display("LED mode sel=%0d: seg1=%b seg2=%b led=%b",
               select, seg1, seg2, led);
    end

    $display("SegDisplay testbench complete");
    #1 $finish;
  end

endmodule
