`timescale 1ns / 1ps

module top_module(
    input init_clk,
    input rst,
    input done,
    input [7:0] sw_input,
    output [7:0] seg1,
    output [7:0] seg2,
    output [7:0] led,
    output wire [7:0] an   //control the 8-segment
);
    parameter nop_inst = 32'b0;
    wire[31:0] regs [0:31];
    wire en_pc, done_input;
    wire en_input, en_output;
    wire [31:0] input_data;
    wire clk, clk_de;

    //HD-IF
    wire[31:0] pc;
    wire is_nop;

    //IF-ID u1-v1
    wire [31:0] u1_inst;
    reg [31:0] v1_inst;

    wire [31:0] u1_pc;
    reg [31:0] v1_pc;
    assign u1_pc = pc;
    
    //ID-EXE u2-v2
    wire [31:0] u2_rs1_data, u2_rs2_data, u2_imm32;
    reg [31:0] v2_rs1_data, v2_rs2_data, v2_imm32;

    wire [31:0] u2_pc;
    reg [31:0] v2_pc;
    assign u2_pc = v1_pc;

    wire [2:0] u2_funct3;
    wire [6:0] u2_funct7;
    reg [2:0] v2_funct3;
    reg [6:0] v2_funct7;
    
    wire [4:0] u2_rd;
    reg [4:0] v2_rd;
    
    wire u2_branch, u2_alu_src, u2_mem_read, u2_mem_write, u2_mem_to_reg, u2_reg_write;
    wire u2_is_jal, u2_is_jalr, u2_is_lui, u2_is_auipc;
    wire [1:0] u2_alu_op;

    reg v2_branch, v2_alu_src, v2_mem_read, v2_mem_write, v2_mem_to_reg, v2_reg_write;
    reg v2_is_jal, v2_is_jalr, v2_is_lui, v2_is_auipc;
    reg [1:0] v2_alu_op;

    //EXE-MEM u3-v3
    wire [31:0] u3_alu_result;
    wire u3_zero;
    reg [31:0] v3_alu_result;
    reg v3_zero;

    wire [31:0] u3_pc;
    reg [31:0] v3_pc;
    assign u3_pc = v2_pc;
    
    wire [4:0] u3_rd;
    reg [4:0] v3_rd;
    assign u3_rd = v2_rd;

    wire u3_mem_read;
    reg v3_mem_read;

    wire u3_mem_write;
    reg v3_mem_write;
    assign u3_mem_write = v2_mem_write;

    wire [31:0] u3_rs2_data;
    reg [31:0] v3_rs2_data;
    assign u3_rs2_data = v2_rs2_data;

    wire u3_mem_to_reg, u3_reg_write;
    wire [2:0] u3_funct3;
    wire u3_is_jal, u3_is_jalr;

    reg v3_mem_to_reg, v3_reg_write;
    reg [2:0] v3_funct3;
    reg v3_is_jal, v3_is_jalr;

    assign u3_mem_to_reg = v2_mem_to_reg;
    assign u3_reg_write = v2_reg_write;
    assign u3_funct3 = v2_funct3;
    assign u3_is_jal = v2_is_jal;
    assign u3_is_jalr = v2_is_jalr;

    //MEM-WB u4-v4
    wire [31:0] u4_mem_read_data;
    reg [31:0] v4_mem_read_data;

    wire [31:0] u4_pc;
    reg [31:0] v4_pc;
    assign u4_pc = v3_pc;
    
    wire [4:0] u4_rd;
    reg [4:0] v4_rd;
    assign u4_rd = v3_rd;

    wire u4_mem_to_reg, u4_reg_write;
    wire [31:0] u4_alu_result;
    assign u4_alu_result = v3_alu_result;

    wire [2:0] u4_funct3;
    wire u4_is_jal, u4_is_jalr;

    reg v4_mem_to_reg, v4_reg_write;
    reg [31:0] v4_alu_result;
    reg [2:0] v4_funct3;
    reg v4_is_jal, v4_is_jalr;
    assign u4_funct3 = v3_funct3;
    assign u4_mem_to_reg = v3_mem_to_reg;
    assign u4_reg_write = v3_reg_write;
    assign u4_is_jal = v3_is_jal;
    assign u4_is_jalr = v3_is_jalr;
    

    always @(posedge clk, negedge rst) begin
        if(~rst)begin
            v1_inst <= nop_inst;
            v1_pc <= 0;
            v2_imm32 <= 0;
            v2_rs1_data <= 0;
            v2_rs2_data <= 0;
            v2_branch <= 0;
            v2_alu_src <= 0;
            v2_mem_read <= 0;
            v2_mem_write <= 0;
            v2_mem_to_reg <= 0;
            v2_reg_write <= 0;
            v2_is_jal <= 0;
            v2_is_jalr <= 0;
            v2_is_lui <= 0;
            v2_is_auipc <= 0;
            v2_alu_op <= 2'b00;
            v2_rd <= 0;

            v3_alu_result <= 0;
            v3_zero <= 0;
            v3_mem_read <= 0;
            v3_mem_write <= 0;
            v3_rs2_data <= 32'b0;
            v3_mem_to_reg <= 0;
            v3_reg_write <= 0;
            v3_funct3 <= 3'b0;
            v3_is_jal <= 0;
            v3_is_jalr <= 0;
            v3_pc <= 0;
            v3_rd <= 0;

            v4_mem_read_data <= 32'b0;
            v4_mem_to_reg <= 0;
            v4_reg_write <= 0;
            v4_alu_result <= 32'b0;
            v4_funct3 <= 3'b0;
            v4_is_jal <= 0;
            v4_is_jalr <= 0;
            v4_pc <= 32'b0;
            v4_rd <= 0;

        end else begin
            v1_inst <= u1_inst;
            v1_pc <= u1_pc;

            v2_imm32 <= u2_imm32;
            v2_rs1_data <= u2_rs1_data;
            v2_rs2_data <= u2_rs2_data;
            v2_branch <= u2_branch;
            v2_alu_src <= u2_alu_src;
            v2_mem_read <= u2_mem_read;
            v2_mem_write <= u2_mem_write;
            v2_mem_to_reg <= u2_mem_to_reg;
            v2_reg_write <= u2_reg_write;
            v2_is_jal <= u2_is_jal;
            v2_is_jalr <= u2_is_jalr;
            v2_is_lui <= u2_is_lui;
            v2_is_auipc <= u2_is_auipc;
            v2_alu_op <= u2_alu_op;
            v2_funct3 <= u2_funct3;
            v2_funct7 <= u2_funct7;
            v2_pc <= u2_pc;
            v2_rd <= u2_rd;

            v3_alu_result <= u3_alu_result;
            v3_zero <= u3_zero;
            v3_mem_read <= u3_mem_read;
            v3_mem_write <= u3_mem_write;
            v3_rs2_data <= u3_rs2_data;
            v3_pc <= u3_pc;
            v3_mem_to_reg <= u3_mem_to_reg;
            v3_reg_write <= u3_reg_write;
            v3_funct3 <= u3_funct3;
            v3_is_jal <= u3_is_jal;
            v3_is_jalr <= u3_is_jalr;
            v3_rd <= u3_rd;
            

            v4_mem_read_data <= u4_mem_read_data;
            v4_mem_to_reg <= u4_mem_to_reg;
            v4_reg_write <= u4_reg_write;
            v4_alu_result <= u4_alu_result;
            v4_funct3 <= u4_funct3;
            v4_is_jal <= u4_is_jal;
            v4_is_jalr <= u4_is_jalr;
            v4_pc <= u4_pc;
            v4_rd <= u4_rd;
        end
    end
    ClockDivider uut_clk_divider(
            .clk(init_clk),
            .rst(rst),
            .period(10000),
            .clk_out(clk)
        );
    ClockDivider uut_debounce_divider(
            .clk(init_clk),
            .rst(rst),
            .period(1000000),
            .clk_out(clk_de)
        );
        
    HarzardDetection hd_uut(
        .clk(clk),
        .rst(rst),
        .en_pc(en_pc),//to do
        // .imm32(imm32),
        // .is_jal(is_jal),
        // .is_jalr(is_jalr),
        // .branch(branch),
        // .zero(zero),
        .is_nop(is_nop),
        .pc(pc)
    );
    
    IF if_uut(
        .clk(clk),
        .rst(rst),
        .pc(pc),
        .is_nop(is_nop),
        .output_inst(u1_inst)
    );

    ID id_uut(
        .done_input(done_input),
        .regs(regs),

        .inst(v1_inst),

        .rs1_data(u2_rs1_data),
        .rs2_data(u2_rs2_data),
        .imm32(u2_imm32),
        .funct3(u2_funct3),
        .funct7(u2_funct7),
        .rd(u2_rd),

        .alu_src(u2_alu_src),
        .alu_op(u2_alu_op),
        
        .branch(u2_branch),
        .mem_read(u2_mem_read),
        .mem_write(u2_mem_write),
        
        .mem_to_reg(u2_mem_to_reg),
        .reg_write(u2_reg_write),
        
        .is_jal(u2_is_jal),
        .is_jalr(u2_is_jalr),
        .is_lui(u2_is_lui),
        .is_auipc(u2_is_auipc),
        .en_pc(en_pc),//output
        .en_input(en_input),
        .en_output(en_output)
    );

    EXE exe_uut (
        .read_data1(v2_rs1_data),
        .read_data2(v2_rs2_data),
        .imm32(v2_imm32),
        .alu_src(v2_alu_src),
        .alu_op(v2_alu_op),
        .funct3(v2_funct3),
        .funct7(v2_funct7),
        .pc(v2_pc),
        .is_lui(v2_is_lui),
        .is_auipc(v2_is_auipc),
        .alu_result(u3_alu_result),
        .zero(u3_zero)
    );

    MEM mem_uut(
        .clk(clk),
        .mem_read(v3_mem_read),
        .mem_write(v3_mem_write),
        .addr(v3_alu_result),
        .din(v3_rs2_data),
        .funct3(v3_funct3),
        .dout(u4_mem_read_data),
        .en_pc(en_pc)//no change
    );

    WB wb_uut(
        .clk(clk),
        .rst(rst),
        .mem_to_reg(v4_mem_to_reg),
        .reg_write(v4_reg_write),
        .mem_read_data(v4_mem_read_data),
        .alu_result(v4_alu_result),
        .addr(v4_alu_result),
        .funct3(v4_funct3),
        .rd(v4_rd),
        .pc(v4_pc),
        .is_jal(v4_is_jal),
        .is_jalr(v4_is_jalr),
        .en_input(en_input),
        .done_input(done_input),
        .input_data(input_data),
        .regs(regs)
    );

    InputModule input_uut(
        .clk(clk),
        .clk_de(clk_de),
        .rst(rst),
        .sw_input(sw_input),
        .done(done),
        .input_data(input_data),
        .done_input(done_input)
    );

    OutputModule uut_output(
        .clk(init_clk),
        .rst(rst),
        .en_output(en_output),
        .reg_a7(regs[17]),
        .output_data(regs[10]),
        .seg1(seg1),
        .seg2(seg2),
        .led(led),
        .an(an)
    );
endmodule
