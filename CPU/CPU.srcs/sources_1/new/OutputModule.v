module OutputModule(
    input clk,
    input rst,
    input en_output,
    input [31:0] reg_a7,
    input [31:0] output_data,
    output [7:0] seg1,
    output [7:0] seg2,
    output [7:0] led,
    output [31:0] uart_reg_a7,
    output reg [31:0] uart_output_data,
    output wire [7:0] an   //control the 8-segment
);
    parameter PERIOD_SEG = 1<<16;
    
    wire [31:0] val,tmp_reg_a7;
    wire [3:0] select;
    wire clk_dis;
    
    assign val = (en_output ? output_data: val);
    assign tmp_reg_a7 = (en_output ? reg_a7: tmp_reg_a7);
    always @(posedge clk_dis) begin
        uart_output_data = val;
    end
//    assign uart_output_data = val;
//    assign uart_output_data = (en_output ? output_data: uart_output_data);
    assign uart_reg_a7 = (en_output ? reg_a7: uart_reg_a7);
    
    SegGenerator uut_seg_gen (
        .rst(rst),
        .clk_dis(clk_dis),
        .select(select),
        .an(an)
    );
    
    ClockDivider uut_clk_display (// 2^16 bits for display
        .clk(clk),
        .rst(rst),
        .period(PERIOD_SEG),
        .clk_out(clk_dis)
    );
    
    SegDisplay uut_seg_display (// display module
        .reg_a7(tmp_reg_a7),
        .val(val),
        .select(select),
        .led(led),
        .seg1(seg1),
        .seg2(seg2)
    );
    
endmodule