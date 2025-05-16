// UartOutputSerializer.v
// Serialize one 32-bit word into 4 UART bytes, LSB first.
// Handshake with UartTx.busy to insure each byte is actually sent.

module UartOutputSerializer (
    input  wire        clk,
    input  wire        rst,             // active-high reset
    input  wire        data_valid_in,   // pulse when data_in_32 is fresh
    input  wire [31:0] data_in_32,
    // handshake to UartTx:
    output reg         send_en_out,
    output reg  [7:0]  send_byte,
    input  wire        busy_in          // from UartTx.busy
);

    // state encoding
    localparam IDLE    = 3'd0,
               SEND0   = 3'd1,
               WAIT0   = 3'd2,
               SEND1   = 3'd3,
               WAIT1   = 3'd4,
               SEND2   = 3'd5,
               WAIT2   = 3'd6,
               SEND3   = 3'd7,
               WAIT3   = 3'd0; // wrap to IDLE

    reg [2:0] state;
    reg [31:0] buffer;

    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            state       <= IDLE;
            buffer      <= 32'd0;
            send_en_out <= 1'b0;
            send_byte   <= 8'd0;
        end else begin
            send_en_out <= 1'b0;  // only pulse in SENDx states

            case (state)
            IDLE: begin
                if (data_valid_in) begin
                    buffer <= data_in_32;
                    state  <= SEND0;
                end
            end

            // byte 0
            SEND0: begin
                if (!busy_in) begin       // wait until TX is idle
                    send_byte   <= buffer[7:0];
                    send_en_out <= 1'b1;   // trigger TX
                    state       <= WAIT0;
                end
            end
            WAIT0: begin
                if (busy_in)              // wait for TX to pick it up
                    state <= SEND1;
            end

            // byte 1
            SEND1: begin
                if (!busy_in) begin
                    send_byte   <= buffer[15:8];
                    send_en_out <= 1'b1;
                    state       <= WAIT1;
                end
            end
            WAIT1: begin
                if (busy_in)
                    state <= SEND2;
            end

            // byte 2
            SEND2: begin
                if (!busy_in) begin
                    send_byte   <= buffer[23:16];
                    send_en_out <= 1'b1;
                    state       <= WAIT2;
                end
            end
            WAIT2: begin
                if (busy_in)
                    state <= SEND3;
            end

            // byte 3
            SEND3: begin
                if (!busy_in) begin
                    send_byte   <= buffer[31:24];
                    send_en_out <= 1'b1;
                    state       <= WAIT3;
                end
            end
            WAIT3: begin
                if (busy_in)
                    state <= IDLE;  // all done, back to idle
            end

            default: state <= IDLE;
            endcase
        end
    end
endmodule
