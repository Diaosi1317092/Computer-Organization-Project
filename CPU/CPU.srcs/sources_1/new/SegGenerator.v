module SegGenerator(
    input rst,
    input clk_dis,
    output reg [3:0] select,
    output wire [7:0] an
);

    always @(posedge clk_dis or posedge rst) begin
        if (~rst) begin
            select <= 4'd0;
        end else begin
            if (select == 4'd7) begin
                select <= 4'd0;
            end else begin
                select <= select + 1;
            end
        end
    end
    
    assign an = (~rst) ? 8'b00000000 : 
            (select == 4'd0) ? 8'b10000000 :
            (select == 4'd1) ? 8'b01000000 :
            (select == 4'd2) ? 8'b00100000 :
            (select == 4'd3) ? 8'b00010000 : 
            (select == 4'd4) ? 8'b00001000 : 
            (select == 4'd5) ? 8'b00000100 : 
            (select == 4'd6) ? 8'b00000010 :
            (select == 4'd7) ? 8'b00000001 : 8'b11111111;
endmodule