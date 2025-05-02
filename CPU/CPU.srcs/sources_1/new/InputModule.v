`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/02 15:13:34
// Design Name: 
// Module Name: InputModule
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


module InputModule(
    input clk,
    input clk_de,
    input rst,
    input [7:0] sw_input,
    input done,
    output [31:0] input_data,
    output reg done_input
    );
    assign input_data = {{24{sw_input[7]}},sw_input};
    parameter DEBOUNCE_THRESHOLD = 4'b0001;  
    reg done_stable;
    reg [3:0] done_counter;
    reg next_done_input, period_done, next_period_done;

    always @(posedge clk_de , negedge rst) begin
        if(~rst) begin
            done_stable <= 0;
        end else begin
            if (done) begin
                if (done_counter < DEBOUNCE_THRESHOLD) begin
                    done_counter <= done_counter + 1;
                end else begin
                    done_stable <= 1;
                end
            end else begin
                done_counter <= 0;
                done_stable <= 0;
            end
        end
    end
    
    always @(posedge clk, negedge rst) begin
        if(~rst) begin
            done_input <= 0;
            period_done <= 0;
        end else begin
            done_input <= next_done_input;
            period_done <= next_period_done;
        end
    end
    
    always @(*) begin
        if (done_stable) begin
            if(done_input) begin
                next_period_done = 1;
                next_done_input = 0;
            end else begin
                next_period_done = period_done;
                if(~period_done) begin
                    next_done_input =1;
                end else begin
                    next_done_input = 0;
                end
            end
        end else begin
            next_period_done = 0;
            next_done_input = 0;
        end
    end
endmodule
