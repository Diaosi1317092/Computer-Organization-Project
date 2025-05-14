module WB(
    input clk,
    input rst,
    input en_pc,
    input mem_to_reg,
    input reg_write,
    input [4:0] rd,
    input [31:0] mem_read_data,
    input [31:0] alu_result,
    input [31:0] input_data,
    input en_input,
    input done_input,
    input [2:0] funct3,
    input [31:0] addr,
    input is_jal,
    input is_jalr,    
    input [31:0] pc,
    // output [31:0] reg_write_data
    output reg [31:0] regs[0:31]
);  
    reg [31:0] reg_write_data;
    integer i;
    parameter sp_base = 32'h00002ffc, gb_base = 32'h00001800;
    always @(posedge clk, negedge rst) begin
        if (!rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'h00000000;
            regs[2] <= sp_base;
            regs[3] <= gb_base;
        end else if (reg_write && en_pc) begin
            if (en_input) regs[10] <= reg_write_data;
            else if (rd != 0) regs[rd] <= reg_write_data;
        end
    end

    wire [31:0] tmp_data=mem_read_data;
    reg [31:0] tmp_data2;
    parameter LB=0,LH=1,LW=2,LBU=4,LHU=5;
    always @(*) begin
        case (funct3)
            LB: begin
                case (addr[1:0])
                    0: tmp_data2={{24{tmp_data[7]}},tmp_data[7:0]};
                    1: tmp_data2={{24{tmp_data[15]}},tmp_data[15:8]};
                    2: tmp_data2={{24{tmp_data[23]}},tmp_data[23:16]};
                    3: tmp_data2={{24{tmp_data[31]}},tmp_data[31:24]};                   
                endcase
            end
            LH: begin
                case (addr[1])
                    0: tmp_data2={{16{tmp_data[15]}},tmp_data[15:0]};
                    1: tmp_data2={{16{tmp_data[31]}},tmp_data[31:16]};            
                endcase
            end
            LW: begin
                tmp_data2=tmp_data;
            end
            LBU: begin
                case (addr[1:0])
                    0: tmp_data2={24'b0,tmp_data[7:0]};
                    1: tmp_data2={24'b0,tmp_data[15:8]};
                    2: tmp_data2={24'b0,tmp_data[23:16]};
                    3: tmp_data2={24'b0,tmp_data[31:24]};
                endcase
            end
            LHU: begin
                case (addr[1])
                    0: tmp_data2={16'b0,tmp_data[15:0]};
                    1: tmp_data2={16'b0,tmp_data[31:16]};
                endcase
            end

        endcase
    end
    assign reg_write_data = ((en_input && done_input) ? input_data 
        : ( (is_jal || is_jalr) ? pc + 4 
        : (mem_to_reg ? tmp_data2: alu_result)));
    //assign tmp_data = (mem_to_reg ? mem_read_data: alu_result);
        

endmodule