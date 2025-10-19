`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/14 18:38:06
// Design Name: 
// Module Name: MEM
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


module MEM(
    input clk,
    input mem_read,
    input mem_write,
    input [31:0] addr,
    input [31:0] din,
    input [2:0] funct3,
    input [31:0] reg_write_data_in,
    output [31:0] reg_write_data_out,
    input have_reg_write_data_in
);
    wire [31:0] mem_read_data;
    reg [31:0] dout;
    assign reg_write_data_out = have_reg_write_data_in ? reg_write_data_in : dout;
    
    parameter SB=3'b000,SH=3'b001,SW=3'b010;
    reg [3:0] write_byte;
    reg [31:0] tmp_write_data;
    always@(*) begin
        if (mem_write) begin
            case(funct3)
                SW: begin
                    write_byte = 4'b1111;
                    tmp_write_data = din;
                end 
                SH: begin
                    tmp_write_data = {2{din[15:0]}};
                    case(addr[1])
                        0: write_byte = 4'b0011;
                        1: write_byte = 4'b1100;
                        default: write_byte = 4'b0000;
                    endcase
            end
                SB: begin
                    tmp_write_data = {4{din[7:0]}};
                    case(addr[1:0])
                        0: write_byte = 4'b0001;
                        1: write_byte = 4'b0010;
                        2: write_byte = 4'b0100;
                        3: write_byte = 4'b1000;
                        default: write_byte = 4'b0000;
                    endcase
                end
                default: write_byte = 4'b0000;
            endcase
        end else begin 
            write_byte = 4'b0000;
        end
    end
    
    wire [31:0] tmp_data = mem_read_data;
    parameter LB=0,LH=1,LW=2,LBU=4,LHU=5;
    always @(*) begin
        case (funct3)
            LB: begin
                case (addr[1:0])
                    0: dout={{24{tmp_data[7]}},tmp_data[7:0]};
                    1: dout={{24{tmp_data[15]}},tmp_data[15:8]};
                    2: dout={{24{tmp_data[23]}},tmp_data[23:16]};
                    3: dout={{24{tmp_data[31]}},tmp_data[31:24]};                   
                endcase
            end
            LH: begin
                case (addr[1])
                    0: dout={{16{tmp_data[15]}},tmp_data[15:0]};
                    1: dout={{16{tmp_data[31]}},tmp_data[31:16]};            
                endcase
            end
            LW: begin
                dout=tmp_data;
            end
            LBU: begin
                case (addr[1:0])
                    0: dout={24'b0,tmp_data[7:0]};
                    1: dout={24'b0,tmp_data[15:8]};
                    2: dout={24'b0,tmp_data[23:16]};
                    3: dout={24'b0,tmp_data[31:24]};
                endcase
            end
            LHU: begin
                case (addr[1])
                    0: dout={16'b0,tmp_data[15:0]};
                    1: dout={16'b0,tmp_data[31:16]};
                endcase
            end
        endcase
    end
    pgram udram(.clka(~clk), .wea(write_byte), .addra(addr[15:2]), .dina(tmp_write_data), .douta(mem_read_data));
endmodule
