module UartRx (
    input wire clk,
    input wire rst,
    input wire rx,
    output reg [7:0] data_out,
    output reg data_valid
);
    parameter CLK_FREQ = 100_000_000;
    parameter BAUD_RATE = 115200;
    localparam BAUD_CNT = CLK_FREQ / BAUD_RATE;
    localparam HALF_BAUD = BAUD_CNT / 2;

    reg [15:0] baud_cnt = 0;
    reg [3:0]  bit_cnt = 0;
    reg [7:0]  rx_data = 0;
    reg [1:0]  state = 0;

    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            baud_cnt   <= 0;
            bit_cnt    <= 0;
            data_valid <= 0;
            state      <= 0;
        end else begin
            data_valid <= 0;
            case (state)
                0: if (!rx) begin
                        state <= 1;
                        baud_cnt <= 0;
                end
                1: if (baud_cnt == HALF_BAUD) begin
                        baud_cnt <= 0;
                        bit_cnt  <= 0;
                        state    <= 2;
                    end else baud_cnt <= baud_cnt + 1;
                2: if (baud_cnt == BAUD_CNT - 1) begin
                        baud_cnt <= 0;
                        rx_data[bit_cnt] <= rx;
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 7) state <= 3;
                    end else baud_cnt <= baud_cnt + 1;
                3: if (baud_cnt == BAUD_CNT - 1) begin
                        state      <= 0;
                        data_out   <= rx_data;
                        data_valid <= 1;
                    end else baud_cnt <= baud_cnt + 1;
                default: state <= 0;
            endcase
        end
    end
endmodule
