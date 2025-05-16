// UartTop.v
// Top-level: receive 8-bit RX into cp_input; also serialize 32-bit uart_output_data back to PC
module UartTop (
    input  wire        clk,             // UART domain clock
    input  wire        rst,             // active-high reset
    // incoming UART RX
    input  wire        rx,
    output wire        tx,
    // control/status from your core
    input  wire [31:0] uart_reg_a7,     // choose which base to highlight
    input  wire [31:0] uart_output_data,// data to send back to PC
    output reg  [7:0]  cp_input         // show received low 8 bits
);

    // --------------------------------------------------
    // 1) simple pass-through receiver to cp_input
    // --------------------------------------------------
    wire [7:0] rx_byte;
    wire       rx_valid;
    UartRx #(
        .CLK_FREQ (100_000_000),
        .BAUD_RATE(115200)
    ) u_rx (
        .clk       (clk),
        .rst       (rst),
        .rx        (rx),
        .data_out  (rx_byte),
        .data_valid(rx_valid)
    );

    always @(posedge clk or negedge rst) begin
        if (~rst)
            cp_input <= 8'd0;
        else if (rx_valid)
            cp_input <= rx_byte;
    end

    // ------------------------------
    //  Detect changes in uart_output_data
    //  and generate one-cycle strobe
    // ------------------------------
    reg [31:0] last_output;
    reg        out_strobe;
    

    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            last_output <= 32'b0;
            out_strobe  <= 1'b0;
        end else begin
            out_strobe  <= 1'b0;
            if (uart_output_data != last_output) begin
                last_output <= uart_output_data;
                out_strobe  <= 1'b1;
            end
        end
    end

    wire send_en, busy_tx;
    wire [7:0] send_byte;

    UartOutputSerializer u_out (
        .clk           (clk),
        .rst           (rst),
        .data_valid_in (out_strobe),
        .data_in_32    (uart_output_data),
        .send_en_out   (send_en),
        .send_byte     (send_byte),
        .busy_in       (busy_tx)
    );

    UartTx u_tx (
        .clk     (clk),
        .rst     (rst),
        .send_en (send_en),
        .data_in (send_byte),
        .tx      (tx),
        .busy    (busy_tx)
    );


endmodule