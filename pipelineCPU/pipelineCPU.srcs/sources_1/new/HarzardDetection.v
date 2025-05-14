`timescale 1ns / 1ps

module HarzardDetection(
    input clk,
    input rst,
    input en_pc,//to do
    input is_jal,
    input is_jalr,
    input branch,
    input zero,
    input [31:0] imm32,
    output reg[31:0] pc,
    output reg is_nop
    );
    parameter base_address = 32'h0000_3000;
    reg[31:0] count,next_count;
    reg[31:0] next_pc;
    reg next_is_nop;
    always @(posedge clk, negedge rst) begin
        if(~rst) begin
            count <= 0;
            pc <= base_address;
            is_nop <= 1;
        end else begin
            count <= next_count;
            pc <= next_pc;
            is_nop <= next_is_nop;
        end
    end
    // always @(*) begin
    //     if (count==4) next_count=0;
    //     else next_count=count+1;
    //     if (count==0) begin
    //         next_pc=pc+4;
    //         next_is_nop=0;
    //     end
    //     else begin
    //         next_pc=pc;
    //         next_is_nop=1;
    //     end
    // end

    always @(*) begin
        if (count==4) next_count=0;
        else next_count=count+1;
        if (count==0) begin
            if (!en_pc) begin
                next_pc = pc;
                next_is_nop = 1;
            end else if (is_jalr) begin
                next_pc = new_pc;
                next_is_nop=0;
            end else if (branch && zero || is_jal) begin
                next_pc = pc + imm32;   // branch taken
                next_is_nop=0;
            end else begin
                next_pc = pc + 32'd4;   // normal sequential execution
                next_is_nop=0;
            end
        end
        else begin
            next_pc = pc;
            next_is_nop = 1;
        end
    end
    
endmodule
