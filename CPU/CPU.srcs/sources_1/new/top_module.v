`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/01 13:11:59
// Module Name: top_module
// Description: Top-level integration of IFetch, ALU, Controller, and Decoder
//////////////////////////////////////////////////////////////////////////////////

module top_module(
    input init_clk,
    input fpga_rst,
    input start_pg,
    input swt_tx,
    input done,
    input cp_done,
    input [7:0] sw_input,
    input  wire rx,
    input is_output_count,
    output wire tx,
    output [7:0] seg1,
    output [7:0] seg2,
    output [7:0] led,
    output wire [7:0] an   //control the 8-segment
);
    // about IO
    wire en_pc;
    wire clk;
    wire en_input;
    wire en_output;
    wire done_input;
    wire [31:0] output_data;
    wire [31:0] input_data;
    wire is_ecall;
    wire [31:0] reg_a7;
    wire [7:0] cp_input;
    wire [31:0] regs [0:31];
    
    reg [31:0] count;
    
    wire clk1;
    wire clk2;
    wire clk_in1;
    //divided clock
    wire clk_de;
    
    // IFetch <-> Controller/ALU signals
    wire [31:0] inst;
    wire [31:0] imm32;
    wire        branch;
    wire        zero;
    wire [31:0] pc;
    wire [31:0] uart_reg_a7;
    wire [31:0] uart_output_data;

    // ALU control and output
    wire        alu_src;
    wire [1:0]  alu_op;
    wire [31:0] alu_result;

    // Controller output control signals
    wire mem_read;
    wire mem_write;
    wire mem_to_reg;
    wire reg_write;
    wire is_jal;
    wire is_jalr;
    wire is_lui;
    wire is_auipc;

    // Decoder output and input signals
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] write_data;  // Can be hardcoded or linked to a MEM stage in full CPU
    wire [31:0] mem_read_data;
    wire [31:0] reg_write_data; 

    // R-type decoding fields (to be extracted from inst)
    wire [2:0] funct3 = inst[14:12];
    wire [6:0] funct7 = inst[31:25];
    
    // UART Programmer Pinouts
    wire upg_clk, upg_clk_o;
    wire upg_wen_o;      
    //Uart write out enable
    wire upg_done_o;     //Uart rx data have done
    //data to which  memory unit of program_rom/dmemory32 
    wire [14:0] upg_adr_o;     
    //data to program_rom or dmemory32 
    wire [31:0] upg_dat_o;
    wire upg_tx, top_tx;
    
    wire spg_bufg;
    
    reg start_de;
    reg [31:0] start_cnt;

    parameter DEBOUNCE_THRESHOLD = 4'b0001;
    
    wire rst;
    always @(posedge clk, negedge rst) begin
        if (~rst) begin 
            count <= 0;
        end else begin 
            if (en_pc) count<=count+1;
            else count<=count;
        end
    end
    always @(posedge clk_de, negedge rst) begin
        if(~rst) begin
            start_de <= 0;
        end else begin
            if (start_pg) begin
                if (start_cnt < DEBOUNCE_THRESHOLD) begin
                    start_cnt <= start_cnt + 1;
                end else begin
                    start_de <= 1;
                end
            end else begin
                start_cnt <= 0;
                start_de <= 0;
            end
        end
    end
    
    
    BUFG U1(.I(start_de), .O(spg_bufg));     // de-twitter
    // Generate UART Programmer reset signal
    reg upg_rst;
    always @ (posedge clk_in1) begin
        if (~fpga_rst)upg_rst <= 1;
        if (spg_bufg)upg_rst <= 0;
    end
    
    assign rst = fpga_rst | !upg_rst;
    
    assign tx = (swt_tx ? upg_tx : top_tx);
    
    // =========================
    // Module Instantiations
    // =========================
    ClockDivider uut_debounce_divider(
        .clk(clk_in1),//init_clk
        .rst(rst),
        .period(1000000),
        .clk_out(clk_de)
    );
    
    clk_wiz_0 uut_clk_wiz(
        .clk_in1(clk_in1),
        .clk_out1(clk1),
        .clk_out2(upg_clk)
    );
    IBUFG clk_buf (
       .I(init_clk),  
       .O(clk_in1)   
    );
    
    uart_bmpg_0 uut_bmpg(
        .upg_clk_i(upg_clk),
        .upg_rst_i(upg_rst),
        .upg_rx_i(rx),
        .upg_clk_o(upg_clk_o),
        .upg_wen_o(upg_wen_o),
        .upg_done_o(upg_done_o),
        .upg_adr_o(upg_adr_o),
        .upg_dat_o(upg_dat_o),
        .upg_tx_o(upg_tx)
    );
    
    ClockDivider uut_clk_divider(
        .clk(clk_in1),
        .rst(rst),
        .period(4),
        .clk_out(clk)
    );
    
    // IFetch unit
    IFetch uut_if (
        .clk(clk),
        .rst(rst),
        .imm32(imm32),
        .branch(branch),
        .zero(zero),
        .inst(inst),
        .out_pc(pc),
        .is_jal(is_jal),
        .is_jalr(is_jalr),
        .new_pc(alu_result),
        .en_pc(en_pc),
        .upg_rst_i(upg_rst),
        .upg_clk_i(upg_clk),
        .upg_wen_i(upg_wen_o & !upg_adr_o[14]),
        .upg_adr_i(upg_adr_o),
        .upg_dat_i(upg_dat_o),
        .upg_done_i(upg_done_o)
    );

    // Decoder unit
    Decoder uut_decoder (
        .clk(clk),
        .rst(rst),
        .reg_write(reg_write),
        .inst(inst),
        .write_data(reg_write_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .imm32(imm32),
        .en_input(en_input),
        .en_output(en_output),
        .output_data(output_data),
        .reg_a7(reg_a7),
        .en_pc(en_pc)
    );

    // ALU unit
    ALU uut_alu (
        .read_data1(rs1_data),
        .read_data2(rs2_data),
        .imm32(imm32),
        .alu_src(alu_src),
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7(funct7),
        .alu_result(alu_result),
        .zero(zero),
        .pc(pc),
        .is_lui(is_lui),
        .is_auipc(is_auipc)
    );

    // Controller unit
    Controller uut_ctrl (
        .inst(inst),
        .branch(branch),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .alu_op(alu_op),
        .is_jal(is_jal),
        .is_jalr(is_jalr),
        .is_lui(is_lui),
        .is_auipc(is_auipc),
        .is_ecall(is_ecall),
        .en_pc(en_pc),
        .en_input(en_input),
        .en_output(en_output),
        .reg_a7(reg_a7),
        .done_input(done_input)
    );
    
    // Data Memory unit
    DMem uut_dmem(
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .addr(alu_result),
        .din(rs2_data), 
        .dout(mem_read_data),
        .funct3(funct3),
        .en_pc(en_pc),
        .upg_rst_i(upg_rst),
        .upg_clk_i(upg_clk_o),
        .upg_wen_i(upg_wen_o & upg_adr_o[14]),
        .upg_adr_i(upg_adr_o),
        .upg_dat_i(upg_dat_o),
        .upg_done_i(upg_done_o)
    );
    
    // MemOrIO unit
    WriteBackMUX uut_writebackmux(
        .mem_to_reg(mem_to_reg),
        .mem_read_data(mem_read_data),
        .alu_result(alu_result),
        .reg_write_data(reg_write_data),
        .addr(alu_result),
        .funct3(funct3),
        .pc(pc),
        .is_jal(is_jal),
        .is_jalr(is_jalr),
        .en_input(en_input),
        .done_input(done_input),
        .input_data(input_data)
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
        .clk(clk_in1),
        .rst(rst),
        .en_output(en_output),
        .reg_a7(reg_a7),
        .output_data(is_output_count?count:output_data),
        .uart_reg_a7(uart_reg_a7),
        .uart_output_data(uart_output_data),
        .seg1(seg1),
        .seg2(seg2),
        .led(led),
        .an(an)
    );

    UartTop uut_uart(
        .clk(clk_in1),
        .rst(rst),
        .rx(rx),
        .tx(top_tx),
        .uart_reg_a7(uart_reg_a7),
        .uart_output_data(uart_output_data),
        .cp_input(cp_input)
    );
    
endmodule