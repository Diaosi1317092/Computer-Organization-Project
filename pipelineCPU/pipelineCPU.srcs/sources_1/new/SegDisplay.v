module SegDisplay(
    input [31:0] reg_a7,
    input [31:0] val,
    input [3:0] select,
    output reg [7:0] led,
    output reg [7:0] seg1,
    output reg [7:0] seg2
);

    reg [7:0] seg_map [0:15];
    reg [7:0] dash;
    wire [31:0] neg_val;
    
    assign neg_val = ~(val - 1);
    
    initial begin
        dash = 8'b00000010;
        seg_map[0] = 8'b11111100;
        seg_map[1] = 8'b01100000;
        seg_map[2] = 8'b11011010;
        seg_map[3] = 8'b11110010;
        seg_map[4] = 8'b01100110;
        seg_map[5] = 8'b10110110;
        seg_map[6] = 8'b10111110;
        seg_map[7] = 8'b11100000;
        seg_map[8] = 8'b11111110;
        seg_map[9] = 8'b11110110;
        seg_map[10] = 8'b11101110;
        seg_map[11] = 8'b00111110;
        seg_map[12] = 8'b10011100;
        seg_map[13] = 8'b01111010;
        seg_map[14] = 8'b10011110;
        seg_map[15] = 8'b10001110;
    end
    
    always @(*) begin
        case (reg_a7)
            32'd1: begin
                led = 8'b00000000;
                case (val[31])
                    1'b0:
                        case (select)
                            4'd0: seg1 = seg_map[(val % 100000000) / 10000000];
                            4'd1: seg1 = seg_map[(val % 10000000) / 1000000];
                            4'd2: seg1 = seg_map[(val % 1000000) / 100000];
                            4'd3: seg1 = seg_map[(val % 100000) / 10000];
                            4'd4: seg2 = seg_map[(val % 10000) / 1000];
                            4'd5: seg2 = seg_map[(val % 1000) / 100];
                            4'd6: seg2 = seg_map[(val % 100) / 10];
                            4'd7: seg2 = seg_map[val % 10];
                            default: begin seg1 = 8'b00000000; seg2 = 8'b00000000; led = 8'b00000000; end
                        endcase
                    1'b1:
                        case (select)
                            4'd0: seg1 = dash;
                            4'd1: seg1 = seg_map[(neg_val % 10000000) / 1000000];
                            4'd2: seg1 = seg_map[(neg_val % 1000000) / 100000];
                            4'd3: seg1 = seg_map[(neg_val % 100000) / 10000];
                            4'd4: seg2 = seg_map[(neg_val % 10000) / 1000];
                            4'd5: seg2 = seg_map[(neg_val % 1000) / 100];
                            4'd6: seg2 = seg_map[(neg_val % 100) / 10];
                            4'd7: seg2 = seg_map[neg_val % 10];
                            default: begin seg1 = 8'b00000000; seg2 = 8'b00000000; led = 8'b00000000; end
                        endcase
                    default: begin seg1 = 8'b00000000; seg2 = 8'b00000000; led = 8'b00000000; end
                endcase
            end
            32'd34: begin
                led = 8'b00000000;
                case (select)
                    4'd0: seg1 = seg_map[val[31:28]];
                    4'd1: seg1 = seg_map[val[27:24]];
                    4'd2: seg1 = seg_map[val[23:20]];
                    4'd3: seg1 = seg_map[val[19:16]];
                    4'd4: seg2 = seg_map[val[15:12]];
                    4'd5: seg2 = seg_map[val[11:8]];
                    4'd6: seg2 = seg_map[val[7:4]];
                    4'd7: seg2 = seg_map[val[3:0]];
                    default: begin seg1 = 8'b00000000; seg2 = 8'b00000000; led = 8'b00000000; end
                endcase
            end
            32'd35: begin
                seg1 = 8'b00000000; seg2 = 8'b00000000; led = val [7:0];
            end
            default: begin seg1 = 8'b00000000; seg2 = 8'b00000000; led = 8'b00000000; end
        endcase
    end

endmodule