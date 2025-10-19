module clk_tb( ); // a reference testbench for 'cpuclk' reg clkin;
    wire clkout;
    reg clkin;
    cpuclk clk1( .clk_in1(clkin), .clk_out1(clkout) );
    initial clkin = 1'b0;
    always #10 clkin=~clkin;
endmodule