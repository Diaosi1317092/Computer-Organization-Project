module UartReg (
    input  wire        clk             ,
    input  wire        rst_n           ,
    input  wire [31:0] uart_output_data,
    input  wire [31:0] regs [0:37]     ,
    input              busy_in         , //busy signal from uart_tx
    input              data_valid_in   , //pulse for input
    output             send_en         , //pulse for output
    output       [7:0] send_byte         //data for uart_tx
);


    wire        signel_done;
    reg  [ 7:0] send_cnt   ;
    reg  [31:0] data_send  ;

    reg data_flag;


    reg     [31:0] data_send_buffer[0:38]    ;
    integer        i                      = 0;




    reg [3:0] state;

    localparam IDLE           = 4'b0000;
    localparam LOAD_DATA      = 4'b0001;
    localparam SEND_DATA_INIT = 4'b0010;
    localparam SEND_DATA      = 4'b0011;
    localparam SEND_DONE      = 4'b0100;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            send_cnt  <= 0;
            data_flag <= 0;
            data_send <= 0;

            for (i = 0; i < 39; i=i+1) begin
                data_send_buffer[i] <= 0;
            end

            state <= IDLE;


        end
        else begin



            case (state)
                IDLE : begin
                    state     <= LOAD_DATA;
                    send_cnt  <= 0;
                    data_flag <= 0;
                    data_send <= 0;
                end

                LOAD_DATA : begin
                    if(data_valid_in)begin
                        data_send_buffer[0] <= uart_output_data;
                        for (i = 1; i < 39; i=i+1) begin
                            data_send_buffer[i] <= regs[i-1];
                        end
                        state <= SEND_DATA_INIT;
                    end
                end

                SEND_DATA_INIT : begin
                    data_flag <= 1;
                    data_send <= data_send_buffer[send_cnt];
                    state     <= SEND_DATA;
                    send_cnt  <= send_cnt +1;
                end

                SEND_DATA : begin
                    if(signel_done)begin
                        data_flag <= 1;
                        if(send_cnt == 38)begin
                            send_cnt <= 0;
                            state    <= SEND_DONE;
                        end
                        else begin
                            send_cnt <= send_cnt +1;
                        end

                        data_send <= data_send_buffer[send_cnt];
                    end
                    else begin
                        data_flag <= 0;
                    end

                end
                SEND_DONE : begin
                    if(signel_done)begin
                        state <= IDLE;
                        data_flag <= 0;
                    end
                    else begin
                        data_flag <= 0;
                        state     <= SEND_DONE;
                    end
                end
                default : begin
                    /* default */
                end
            endcase


        end
    end



    uart32_8 u_uart32_8 (
        .sys_clk    (clk        ),
        .sys_rst_n  (rst_n      ),
        .data       (data_send  ),
        .data_flag  (data_flag  ),
        .tx_busy    (busy_in    ),
        .tx_data    (send_byte  ),
        .tx_en      (send_en    ),
        .signel_done(signel_done)
    );



endmodule









module uart32_8 (
    input sys_clk, // 50Mhz
    input sys_rst_n,

    input [31 :0] data,
    input data_flag,

    input tx_busy,


    output reg  [7:0] tx_data,
    output reg tx_en,

    output reg signel_done
);


reg [4:0] state;
wire tx_done;
reg tx_busy_d;


    always @(posedge sys_clk or negedge sys_rst_n) begin
        if(!sys_rst_n)begin
            tx_busy_d <= 0;
        end
        else begin
            tx_busy_d <= tx_busy;
        end
    end
    assign tx_done = !tx_busy && tx_busy_d;  // pulse




    always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        state <= 0;
        tx_data <= 0;
        tx_en <= 0;
        signel_done <= 0;
    end
    else begin
        case (state)
            0: if (data_flag) begin
                    tx_data <=data[31:24];
                    tx_en <= 1;
                    state <= 1;
                    signel_done <= 0;
                end
                else begin
                    state <= 0;
                    signel_done <= 0;
                end

            1: if (tx_done) begin
                    tx_data <= data[23:16];
                    tx_en <= 1;
                    state <= 2;
                end
                else begin
                    tx_data <= tx_data;
                    tx_en <= 0;
                end

            2: if (tx_done) begin
                    tx_data <= data[15:8];
                    tx_en <= 1;
                    state <= 3;
                end
                else begin
                    tx_data <= tx_data;
                    tx_en <= 0;
                end

            3: if (tx_done) begin
                    tx_data <=  data[7:0];
                    tx_en <= 1;
                    state <= 4;
                end
                else begin
                    tx_data <= tx_data;
                    tx_en <= 0;
                end

            4: if (tx_done) begin
                    tx_data <= 8'h00;
                    tx_en <= 0;
                    state <= 0;
                    signel_done <= 1;
                end
                else begin
                    tx_data <= tx_data;
                    tx_en <= 0;
                end

            default: state <= 0;
        endcase
    end
end


endmodule
