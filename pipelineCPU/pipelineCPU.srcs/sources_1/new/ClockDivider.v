module ClockDivider(
    input clk,
    input rst,
    input [31:0] period,
    output reg clk_out
    );
   reg [24:0] cnt;
       
   always @(posedge clk or negedge rst) begin
       if (~rst) begin
           cnt <= 0;
           clk_out <= 0;
       end else begin
           if (cnt == (period>>1)-1) begin
               cnt <= 0;
               clk_out <= ~clk_out;
           end else begin
               cnt <= cnt + 1;
           end
       end
   end
endmodule