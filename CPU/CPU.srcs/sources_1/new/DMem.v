module DMem(
    input clk,
    input mem_read,
    input mem_write,
    input [31:0] addr,
    input [31:0] din,
    input [2:0] funct3,
    output[31:0] dout,
    input en_pc,
    
    input upg_rst_i,
    input upg_clk_i,
    input upg_wen_i,
    input [13:0] upg_adr_i,
    input [31:0] upg_dat_i,
    input upg_done_i
);
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
    
    wire wen = en_pc ? write_byte : 0;
    
    wire kickOff = upg_rst_i | (~upg_rst_i & upg_done_i);
    
    prgram udram(
        .clka(kickOff ? ~clk : upg_clk_i),
        .wea(kickOff ? wen : upg_wen_i),
        .addra(kickOff ? addr[15:2] : upg_adr_i),
        .dina(kickOff ? tmp_write_data : upg_dat_i),
        .douta(dout)
    );
endmodule