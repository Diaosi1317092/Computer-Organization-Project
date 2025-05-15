module UartTop (
    input  wire       clk,       // UART domain clock (e.g. 100 MHz)
    input  wire       clk_cpu,   // user domain clock
    input  wire       rst,       // active-high reset
    input  wire       rx,
    output wire       tx,
    output wire [7:0] cp_input,  // low 8-bit payload
    output wire       cp_done    // one clk_cpu-cycle pulse
);

    // ©¤©¤©¤©¤©¤©¤©¤©¤©¤©¤ UART 8-bit receiver ©¤©¤©¤©¤©¤©¤©¤©¤©¤©¤
    wire [7:0] rx_byte;
    wire       rx_valid;

    uart_rx #(
        .CLK_FREQ (100_000_000),
        .BAUD_RATE(115200)
    ) u_rx (
        .clk       (clk),
        .rst       (rst),
        .rx        (rx),
        .data_out  (rx_byte),
        .data_valid(rx_valid)
    );

    // ©¤©¤©¤©¤©¤©¤©¤©¤©¤©¤ Command parser + CDC bridge ©¤©¤©¤©¤©¤©¤©¤©¤©¤©¤
    UartCommandParser u_parser (
        .clk       (clk),
        .clk_cpu   (clk_cpu),
        .rst       (rst),
        .rx_byte   (rx_byte),
        .rx_valid  (rx_valid),
        .data_out  (cp_input),
        .data_done (cp_done)
    );

    // We do not transmit back for now
    assign tx = 1'b1;

endmodule
