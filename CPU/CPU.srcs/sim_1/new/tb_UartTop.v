`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/14 20:16:53
// Design Name: 
// Module Name: tb_UartTop
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_UartTop;

  // inputs
  reg rst;       
  reg clk_de;
  reg [7:0] cp_input;
  
  wire [7:0] now_input;
  
  wire cp_done;
  // instantiate DUT
  UartTop uut (
    .rst     (rst),
    .clk_de (clk_de),
    .cp_input  (cp_input),
    .now_input (now_input),
    .cp_done      (cp_done)
  );

  // clk_dis: toggle every 10 ns ¡ú 50 MHz display clock
  initial clk_de = 1'b0;
  initial cp_input = 8'b0;
  always #10 clk_de = ~clk_de;
  
  
  integer i;

initial begin
    rst = 0;        // assert reset
    #20;
    rst = 1;        // release reset
  for(i=0;i<10;i=i+1) begin
    #40;
    cp_input = cp_input + 1;
  end
  $finish;
end
endmodule
