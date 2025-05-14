module UartTop (
    input wire clk,
    input wire clk_de,
    input wire rst,
    input wire rx,
    output wire tx,
    output reg [7:0] now_input,
    output reg cp_done
);
    wire [7:0] rx_data;
    wire rx_valid;
    
    reg [7:0] cp_input;
    reg [7:0] next_now_input;
    reg next_cp_done;

    UartRx #(.CLK_FREQ(100_000_000), .BAUD_RATE(115200)) u_rx (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .data_out(rx_data),
        .data_valid(rx_valid)
    );

    assign tx = 1'b1;  // not used, keep idle high

    always @(posedge clk) begin
        if (rx_valid)
            cp_input <= rx_data;
    end
    
    always @(posedge clk_de or negedge rst) begin
        if (!rst) begin
            now_input <= 8'b0;
            cp_done   <= 1'b0;
        end else begin
            cp_done   <= (cp_input != now_input);
            now_input <= cp_input;
        end
    end
/*
    always @(posedge clk_de, negedge rst) begin
        if (~rst) begin
            now_input <= 8'b0;
            cp_done <= 1'b0;
        end else begin
            now_input <= next_now_input;
            cp_done <= next_cp_done;
        end
    end
    
    always @(*) begin
        next_now_input = cp_input;
        next_cp_done = (next_now_input != now_input ? 1'b1 : 1'b0);
    end
*/
endmodule
