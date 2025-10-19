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
    reg [31:0] last_out;
    reg        out_strobe;
    integer    i;
    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            last_out    <= 32'd0;
            out_strobe <= 1'b0;
        end else begin
            out_strobe <= 1'b0;
            if (uart_output_data != last_out) begin
                last_out    <= uart_output_data;
                out_strobe <= 1'b1;
            end
        end
    end
    
    wire send_en, busy_tx;
    wire [7:0] send_byte;
    
    UartReg u_reg (
        .clk(clk),
        .rst_n(rst),
        .uart_output_data(uart_output_data),
        .busy_in(busy_tx),
        .data_valid_in(out_strobe),
        .send_en(send_en),
        .send_byte(send_byte)
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