module UartTx (
    input wire clk,
    input wire rst,
    input wire send_en,
    input wire [7:0] data_in,
    output reg tx,
    output reg busy
);
    parameter CLK_FREQ = 100_000_000;
    parameter BAUD_RATE = 115200;
    localparam BAUD_CNT = CLK_FREQ / BAUD_RATE;

    reg [15:0] baud_cnt = 0;
    reg baud_tick = 0;
    reg [3:0] bit_cnt = 0;
    reg [9:0] tx_data;

    always @(posedge clk or posedge rst) begin
        if (~rst) begin
            baud_cnt <= 0;
            baud_tick <= 0;
        end else if (busy) begin
            if (baud_cnt == BAUD_CNT - 1) begin
                baud_cnt <= 0;
                baud_tick <= 1;
            end else begin
                baud_cnt <= baud_cnt + 1;
                baud_tick <= 0;
            end
        end else begin
            baud_cnt <= 0;
            baud_tick <= 0;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (~rst) begin
            tx <= 1;
            busy <= 0;
            bit_cnt <= 0;
        end else if (send_en && !busy) begin
            tx_data <= {1'b1, data_in, 1'b0}; // stop + data + start
            busy <= 1;
            bit_cnt <= 0;
        end else if (busy && baud_tick) begin
            tx <= tx_data[bit_cnt];
            bit_cnt <= bit_cnt + 1;
            if (bit_cnt == 9) busy <= 0;
        end
    end
endmodule
