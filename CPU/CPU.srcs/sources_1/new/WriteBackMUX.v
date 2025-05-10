`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/01 16:41:27
// Design Name: 
// Module Name: MemorIO
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


module WriteBackMUX(
    input mem_to_reg,
    input [31:0] mem_read_data,
    input [31:0] alu_result,
    input [31:0] input_data,
    input en_input,
    input done_input,
    output [31:0] reg_write_data,
    input [2:0] funct3,
    input [31:0] addr,
    input is_jal,
    input is_jalr,    
    input [31:0] pc
);
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
