module top_module(
    input init_clk,
    input rst,
    input done,
    input cp_done,
    input [7:0] sw_input,
    input debug,
    input debug_on,
    input  wire rx,
    output wire tx,
    output [7:0] seg1,
    output [7:0] seg2,
    output [7:0] led,
    output wire [7:0] an   //control the 8-segment
);
    parameter nop_inst = 32'h00000013, base_address = 32'h00003000;
    wire[31:0] regs [0:31];
    wire [31:0] output_regs [0:37];
    reg [31:0] output_inst [0:5];
    assign output_regs = {regs, output_inst};
    
    wire [31:0] input_data;
    wire en_pc, done_input;
    wire clk, clk_de;
    
    wire [7:0] cp_input;
    wire [31:0] uart_reg_a7;
    wire [31:0] uart_output_data;

    wire en_pc2;
    assign en_pc2 = debug_on ? done_input : en_pc;

    // ecall's stalling
    wire is_ecall;
    reg [1:0] ecall_cnt;
    wire check_a7=(ecall_cnt==3);
    
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
    wire [31:0] u2_inst;
    reg [31:0] v2_inst;
    assign u2_inst = v1_inst;
    
    wire [31:0] u2_rs1_data, u2_rs2_data, u2_imm32,u2_output_data,u2_reg_a7;
    reg [31:0] v2_rs1_data, v2_rs2_data, v2_imm32,v2_output_data,v2_reg_a7;

    // wire [31:0] u2_input_data;
    // reg [31:0] v2_input_data;
    // wire u2_en_input;
    // reg v2_en_input;

    wire [31:0] u2_pc;
    reg [31:0] v2_pc;
    assign u2_pc = v1_pc;

    wire [31:0] u2_reg_write_data;
    reg [31:0] v2_reg_write_data;

    wire u2_have_reg_write_data;
    reg v2_have_reg_write_data;

    wire [2:0] u2_funct3;
    wire [6:0] u2_funct7;
    reg [2:0] v2_funct3;
    reg [6:0] v2_funct7;
    
    wire [4:0] u2_rs1, u2_rs2;
    reg [4:0] v2_rs1, v2_rs2;
    wire [4:0] u2_rd;
    reg [4:0] v2_rd;
    
    wire u2_branch, u2_alu_src, u2_mem_read, u2_mem_write, u2_mem_to_reg, u2_reg_write, u2_en_output;
    wire u2_is_jal, u2_is_jalr, u2_is_lui, u2_is_auipc;
    wire [1:0] u2_alu_op;

    reg v2_branch, v2_alu_src, v2_mem_read, v2_mem_write, v2_mem_to_reg, v2_reg_write, v2_en_output;
    reg v2_is_jal, v2_is_jalr, v2_is_lui, v2_is_auipc;
    reg [1:0] v2_alu_op;
    
    //Forwarding in EXE stage
    wire [31:0] exe_operand1_data, exe_operand2_data;

    //EXE-MEM u3-v3
    wire [31:0] u3_inst;
    reg [31:0] v3_inst;
    assign u3_inst = v2_inst;
    
    wire u3_branch;
    reg v3_branch;
    assign u3_branch = v2_branch;

    wire [31:0] u3_imm32;
    reg [31:0] v3_imm32;
    assign u3_imm32 = v2_imm32;

    // wire [31:0] u3_input_data;
    // reg [31:0] v3_input_data;
    // wire u3_en_input;
    // reg v3_en_input;
    // assign u3_en_input = v2_en_input;
    // assign u3_input_data = v2_input_data;

    wire [31:0] u3_reg_write_data;
    reg [31:0] v3_reg_write_data;

    wire u3_have_reg_write_data;
    reg v3_have_reg_write_data;

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

    assign u3_mem_to_reg = v2_mem_to_reg;
    assign u3_reg_write = v2_reg_write;
    assign u3_funct3 = v2_funct3;
    assign u3_is_jal = v2_is_jal;
    assign u3_is_jalr = v2_is_jalr;

    //MEM-WB u4-v4
    wire [31:0] u4_inst;
    reg [31:0] v4_inst;
    assign u4_inst = v3_inst;
        
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

    wire [31:0] u4_reg_write_data;
    reg [31:0] v4_reg_write_data;

    wire u4_have_reg_write_data;
    reg v4_have_reg_write_data;

    wire [2:0] u4_funct3;

    // wire [31:0] u4_input_data;
    // reg [31:0] v4_input_data;
    // wire u4_en_input;
    // reg v4_en_input;
    // assign u4_en_input = v3_en_input;
    // assign u4_input_data = v3_input_data;

    reg v4_mem_to_reg, v4_reg_write;
    reg [31:0] v4_alu_result;
    reg [2:0] v4_funct3;
    assign u4_funct3 = v3_funct3;
    assign u4_mem_to_reg = v3_mem_to_reg;
    assign u4_reg_write = v3_reg_write;
    
    // control hazard
    wire clr_if = u2_is_jal | u2_is_jalr | u2_branch;
    wire is_stalling;
    always @(posedge clk, negedge rst) begin
        if(~rst)begin
            ecall_cnt <= 0;
            v1_inst <= nop_inst;
            v1_pc <= base_address;
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
            v2_funct3 <= 3'b0;
            v2_funct7 <= 7'b0;
            v2_pc <= base_address;
            v2_reg_a7 <= 0;
            v2_output_data <= 0;
            // v2_en_input <= 0;
            // v2_input_data <= 0;
            v2_reg_write_data <= 0;
            v2_have_reg_write_data <= 0;
            v2_rs1 <= 0;
            v2_rs2 <= 0;
            v2_inst <= nop_inst;
            

            v3_alu_result <= 0;
            v3_zero <= 0;
            v3_mem_read <= 0;
            v3_mem_write <= 0;
            v3_rs2_data <= 32'b0;
            v3_mem_to_reg <= 0;
            v3_reg_write <= 0;
            v3_funct3 <= 3'b0;
            v3_pc <= base_address;
            v3_rd <= 0;
            v3_branch <= 0;
            v3_imm32 <= 32'b0;
            // v3_en_input <= 0;
            // v3_input_data <= 0;
            v3_reg_write_data <= 0;
            v3_have_reg_write_data <= 0;
            v3_inst <= nop_inst;

            v4_mem_read_data <= 32'b0;
            v4_mem_to_reg <= 0;
            v4_reg_write <= 0;
            v4_alu_result <= 32'b0;
            v4_funct3 <= 3'b0;
            v4_pc <= base_address;
            v4_rd <= 0;
            // v4_en_input <= 0;
            // v4_input_data <= 0;
            v4_reg_write_data <= 0;
            v4_have_reg_write_data <= 0;
            v4_inst <= nop_inst;

        end else begin
            if (en_pc2) begin 
                if (!is_stalling) begin
                    if (!is_ecall) begin 
                        ecall_cnt <= 0;
                        if (!clr_if) begin
                            v1_inst <= u1_inst;
                            v1_pc <= u1_pc;
                        end else begin
                            v1_inst <= nop_inst;
                            v1_pc <= base_address;
                        end
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
                        v2_reg_a7 <= u2_reg_a7;
                        v2_output_data <= u2_output_data;
                        v2_en_output <= u2_en_output;
                        // v2_en_input <= u2_en_input;
                        // v2_input_data <= u2_input_data;
                        v2_reg_write_data <= u2_reg_write_data;
                        v2_have_reg_write_data <= u2_have_reg_write_data;
                        v2_rs1 <= u2_rs1;
                        v2_rs2 <= u2_rs2;
                        v2_inst <= u2_inst;
                        
        
                    end else begin
                        ecall_cnt <= ecall_cnt + 1;

                        v1_inst <= v1_inst;
                        v1_pc <= v1_pc;

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
                        v2_alu_op <= 0;
                        v2_funct3 <= 0;
                        v2_funct7 <= 0;
                        v2_pc <= base_address;
                        v2_rd <= 0;
                        v2_reg_a7 <= 0;
                        v2_output_data <= 0;
                        v2_en_output <= 0;
                        // v2_en_input <= u2_en_input;
                        // v2_input_data <= u2_input_data;
                        v2_reg_write_data <= 0;
                        v2_have_reg_write_data <= 0;
                        v2_rs1 <= 0;
                        v2_rs2 <= 0;
                        v2_inst <= nop_inst;
                    end
                    v3_alu_result <= u3_alu_result;
                    v3_zero <= u3_zero;
                    v3_mem_read <= u3_mem_read;
                    v3_mem_write <= u3_mem_write;
                    v3_rs2_data <= u3_rs2_data;
                    v3_pc <= u3_pc;
                    v3_mem_to_reg <= u3_mem_to_reg;
                    v3_reg_write <= u3_reg_write;
                    v3_funct3 <= u3_funct3;
                    v3_rd <= u3_rd;
                    v3_branch <= u3_branch;
                    v3_imm32 <= u3_imm32;
                    // v3_en_input <= u3_en_input;
                    // v3_input_data <= u3_input_data;
                    v3_reg_write_data <= u3_reg_write_data;
                    v3_have_reg_write_data <= u3_have_reg_write_data;
                    v3_inst <= u3_inst;
                    
                end else begin
                    ecall_cnt <= ecall_cnt;

                    v1_inst <= v1_inst;
                    v1_pc <= v1_pc;

                    v2_imm32 <= v2_imm32;
                    v2_rs1_data <= exe_operand1_data;
                    v2_rs2_data <= exe_operand2_data;
                    v2_branch <= v2_branch;
                    v2_alu_src <= v2_alu_src;
                    v2_mem_read <= v2_mem_read;
                    v2_mem_write <= v2_mem_write;
                    v2_mem_to_reg <= v2_mem_to_reg;
                    v2_reg_write <= v2_reg_write;
                    v2_is_jal <= v2_is_jal;
                    v2_is_jalr <= v2_is_jalr;
                    v2_is_lui <= v2_is_lui;
                    v2_is_auipc <= v2_is_auipc;
                    v2_alu_op <= v2_alu_op;
                    v2_funct3 <= v2_funct3;
                    v2_funct7 <= v2_funct7;
                    v2_pc <= v2_pc;
                    v2_rd <= v2_rd;
                    v2_reg_a7 <= v2_reg_a7;
                    v2_output_data <= v2_output_data;
                    v2_en_output <= v2_en_output;
                    // v2_en_input <= v2_en_input;
                    // v2_input_data <= v2_input_data;
                    v2_reg_write_data <= v2_reg_write_data;
                    v2_have_reg_write_data <= v2_have_reg_write_data;
                    v2_rs1 <= v2_rs1;
                    v2_rs2 <= v2_rs2;
                    v2_inst <= v2_inst;
    
                    v3_alu_result <= 0;
                    v3_zero <= 0;
                    v3_mem_read <= 0;
                    v3_mem_write <= 0;
                    v3_rs2_data <= 0;
                    v3_pc <= base_address;
                    v3_mem_to_reg <= 0;
                    v3_reg_write <= 0;
                    v3_funct3 <= 0;
                    v3_rd <= 0;
                    v3_branch <= 0;
                    v3_imm32 <= 0;
                    // v3_en_input <= v3_en_input;
                    // v3_input_data <= v3_input_data;
                    v3_reg_write_data <= 0;
                    v3_have_reg_write_data <= 1;
                    v3_inst <= nop_inst;
                end
                v4_mem_read_data <= u4_mem_read_data;
                v4_mem_to_reg <= u4_mem_to_reg;
                v4_reg_write <= u4_reg_write;
                v4_alu_result <= u4_alu_result;
                v4_funct3 <= u4_funct3;
                v4_pc <= u4_pc;
                v4_rd <= u4_rd;
                // v4_en_input <= u4_en_input;
                // v4_input_data <= u4_input_data;
                v4_reg_write_data <= u4_reg_write_data;
                v4_have_reg_write_data <= u4_have_reg_write_data;
                v4_inst <= u4_inst;
            end else begin
                ecall_cnt <= ecall_cnt ;

                v1_inst <= v1_inst;
                v1_pc <= v1_pc;

                v2_imm32 <= v2_imm32;
                v2_rs1_data <= v2_rs1_data;
                v2_rs2_data <= v2_rs2_data;
                v2_branch <= v2_branch;
                v2_alu_src <= v2_alu_src;
                v2_mem_read <= v2_mem_read;
                v2_mem_write <= v2_mem_write;
                v2_mem_to_reg <= v2_mem_to_reg;
                v2_reg_write <= v2_reg_write;
                v2_is_jal <= v2_is_jal;
                v2_is_jalr <= v2_is_jalr;
                v2_is_lui <= v2_is_lui;
                v2_is_auipc <= v2_is_auipc;
                v2_alu_op <= v2_alu_op;
                v2_funct3 <= v2_funct3;
                v2_funct7 <= v2_funct7;
                v2_pc <= v2_pc;
                v2_rd <= v2_rd;
                v2_reg_a7 <= v2_reg_a7;
                v2_output_data <= v2_output_data;
                v2_en_output <= v2_en_output;
                // v2_en_input <= v2_en_input;
                // v2_input_data <= v2_input_data;
                v2_reg_write_data <= v2_reg_write_data;
                v2_have_reg_write_data <= v2_have_reg_write_data;
                v2_inst <= v2_inst;

                v3_alu_result <= v3_alu_result;
                v3_zero <= v3_zero;
                v3_mem_read <= v3_mem_read;
                v3_mem_write <= v3_mem_write;
                v3_rs2_data <= v3_rs2_data;
                v3_pc <= v3_pc;
                v3_mem_to_reg <= v3_mem_to_reg;
                v3_reg_write <= v3_reg_write;
                v3_funct3 <= v3_funct3;
                v3_rd <= v3_rd;
                v3_branch <= v3_branch;
                v3_imm32 <= v3_imm32;
                // v3_en_input <= v3_en_input;
                // v3_input_data <= v3_input_data;
                v3_reg_write_data <= v3_reg_write_data;
                v3_have_reg_write_data <= v3_have_reg_write_data;
                v3_inst <= v3_inst;

                v4_reg_write <= v4_reg_write;
                v4_rd <= v4_rd;
                v4_reg_write_data <= v4_reg_write_data;
                v4_inst <= v4_inst;
            end
        end
    end
    
    //transmitting output to uart as array
    always @(*) begin
        output_inst[0] = pc;
        output_inst[5] = pc;// IF
        output_inst[4] = v1_inst;// ID
        output_inst[3] = v2_inst;// EXE
        output_inst[2] = v3_inst;// MEM
        output_inst[1] = v4_inst;// WB
    end
      
    ClockDivider uut_clk_divider(
            .clk(init_clk),
            .rst(rst),
            .period(10000),// in order to do simulation, still needed to change for pipeline
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
        .en_pc(en_pc2),
        .clr_if(clr_if),
        .imm32(u3_imm32),
        .new_pc(u3_alu_result),
        .is_jal(u3_is_jal),
        .is_jalr(u3_is_jalr),
        .branch(u3_branch),
        .zero(u3_zero),
        .is_nop(is_nop),
        .pc(pc),
        .is_ecall(is_ecall),
        .is_stalling(is_stalling)
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

        .input_data(input_data),
        .pc(v1_pc),
        .reg_write_data(u2_reg_write_data),
        .have_reg_write_data(u2_have_reg_write_data),
        
        .rs1_data(u2_rs1_data),
        .rs2_data(u2_rs2_data),
        .imm32(u2_imm32),
        .funct3(u2_funct3),
        .funct7(u2_funct7),
        .rd(u2_rd),
        .rs1(u2_rs1),
        .rs2(u2_rs2),
        .reg_a7(u2_reg_a7),
        .output_data(u2_output_data),

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
        .en_output(u2_en_output),
        
        // ecall's stalling
        .is_ecall(is_ecall),
        .check_a7(check_a7)

    );

    EXE exe_uut (
        .reg_write_data_in(v2_reg_write_data),
        .have_reg_write_data_in(v2_have_reg_write_data),
        .reg_write_data_out(u3_reg_write_data),
        .have_reg_write_data_out(u3_have_reg_write_data),
        .read_data1(exe_operand1_data),
        .read_data2(exe_operand2_data),
        .imm32(v2_imm32),
        .alu_src(v2_alu_src),
        .alu_op(v2_alu_op),
        .mem_to_reg(v2_mem_to_reg),
        .funct3(v2_funct3),
        .funct7(v2_funct7),
        .pc(v2_pc),
        .is_lui(v2_is_lui),
        .is_auipc(v2_is_auipc),
        .alu_result(u3_alu_result),
        .zero(u3_zero)
    );
    
    FW fw_uut(
        .rs1(v2_rs1),
        .rs2(v2_rs2),
        .exe_rd(v3_rd),
        .mem_rd(v4_rd),
        .fw_exe_data(v3_reg_write_data),
        .fw_mem_data(v4_reg_write_data),
        .rs1_data(v2_rs1_data),
        .rs2_data(v2_rs2_data),
        .fw_reg_write1(v3_reg_write),
        .fw_reg_write2(v4_reg_write),
        .fw_exe_have_write_data(v3_have_reg_write_data),
        .operand1_data(exe_operand1_data),
        .operand2_data(exe_operand2_data),
        .is_stalling(is_stalling)
        );
            
    
    MEM mem_uut(
        .reg_write_data_in(v3_reg_write_data),
        .have_reg_write_data_in(v3_have_reg_write_data),
        .reg_write_data_out(u4_reg_write_data),
        .clk(clk),
        .mem_read(v3_mem_read),
        .mem_write(v3_mem_write),
        .addr(v3_alu_result),
        .din(v3_rs2_data),
        .funct3(v3_funct3)
        
    );

    WB wb_uut(
        .reg_write_data(v4_reg_write_data),
        .clk(clk),
        .rst(rst),
        .reg_write(v4_reg_write),
        .rd(v4_rd),
        // .done_input(done_input),
        .regs(regs)
    );

    InputModule uut_input(
        .clk(clk),
        .clk_de(clk_de),
        .rst(rst),
        .sw_input(sw_input),
        .cp_input(cp_input),
        .done(done),
        .cp_done(cp_done),
        .input_data(input_data),
        .true_done_input(done_input)
    );
    
    OutputModule uut_output(
        .clk(init_clk),
        .rst(rst),
        .en_output(v2_en_output),
        .reg_a7(v2_reg_a7),
        .output_data(v2_output_data),
        .seg1(seg1),
        .seg2(seg2),
        .led(led),
        .an(an)
    );
    
    UartTop uut_uart(
        .clk(init_clk),
        .rst(rst),
        .rx(rx),
        .tx(tx),
        .uart_reg_a7(uart_reg_a7),
        .uart_output_data(uart_output_data),
        .cp_input(cp_input),
        .regs(output_regs)
    );
    
endmodule
