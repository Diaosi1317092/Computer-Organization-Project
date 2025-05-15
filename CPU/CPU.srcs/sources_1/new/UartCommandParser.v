module UartCommandParser (
    input  wire       clk,
    input  wire       clk_cpu,
    input  wire       rst,
    input  wire [7:0] rx_byte,
    input  wire       rx_valid,

    output reg  [7:0] data_out,
    output reg        data_done
);

    reg  [7:0] low_byte;
    reg        byte_phase;
    reg        toggle_clk;
    reg        toggle_ff;

    reg  [7:0] payload_buf;

    reg handshk_tog_clk;

    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            byte_phase      <= 1'b0;
            toggle_clk      <= 1'b0;
            toggle_ff       <= 1'b0;
            handshk_tog_clk <= 1'b0;
            payload_buf     <= 8'd0;
        end
        else if (rx_valid) begin
            if (byte_phase == 1'b0) begin
                low_byte   <= rx_byte;
                byte_phase <= 1'b1;
            end
            else begin
                toggle_clk <= rx_byte[0];
                byte_phase <= 1'b0;

                if (rx_byte[0] ^ toggle_ff) begin
                    toggle_ff       <= rx_byte[0];
                    payload_buf     <= low_byte;
                    handshk_tog_clk <= ~handshk_tog_clk;
                end
            end
        end
    end

    reg sync1 = 0, sync2 = 0;
    always @(posedge clk_cpu or negedge rst) begin
        if (~rst) begin
            sync1 <= 0;
            sync2 <= 0;
        end
        else begin
            sync1 <= handshk_tog_clk;
            sync2 <= sync1;
        end
    end

    wire pulse_cpu = sync1 ^ sync2;

    always @(posedge clk_cpu or negedge rst) begin
        if (~rst) begin
            data_out  <= 8'd0;
            data_done <= 1'b0;
        end
        else begin
            if (pulse_cpu)
                data_out <= payload_buf;
            data_done <= pulse_cpu;
        end
    end

endmodule
