module InputModule(
    input clk,
    input clk_de,
    input rst,
    input [7:0] sw_input,
    input [7:0] cp_input,
    input done,
    input cp_done,
    output [31:0] input_data,
    output wire true_done_input
);
    reg done_input,cp_done_input;
    assign input_data = (cp_done_input ? {{24{cp_input[7]}},cp_input} : {{24{sw_input[7]}},sw_input});
    assign true_done_input = cp_done_input | done_input;
    parameter DEBOUNCE_THRESHOLD = 4'b0001;  
    reg done_stable;
    reg cp_done_stable;    
    reg [3:0] done_counter;
    reg [3:0] cp_done_counter;
    reg next_done_input, period_done, next_period_done;
    reg next_cp_done_input, period_cp_done, next_period_cp_done;

    always @(posedge clk_de, negedge rst) begin
        if(~rst) begin
            done_stable <= 0;
        end else begin
            if (done) begin
                if (done_counter < DEBOUNCE_THRESHOLD) begin
                    done_counter <= done_counter + 1;
                end else begin
                    done_stable <= 1;
                end
            end else begin
                done_counter <= 0;
                done_stable <= 0;
            end
        end
    end
    
    always @(posedge clk, negedge rst) begin
        if(~rst) begin
            done_input <= 0;
            period_done <= 0;
        end else begin
            done_input <= next_done_input;
            period_done <= next_period_done;
        end
    end
    
    always @(*) begin
        if (done_stable) begin
            if(done_input) begin
                next_period_done = 1;
                next_done_input = 0;
            end else begin
                next_period_done = period_done;
                if(~period_done) begin
                    next_done_input =1;
                end else begin
                    next_done_input = 0;
                end
            end
        end else begin
            next_period_done = 0;
            next_done_input = 0;
        end
    end

//---------------------------------------------

    always @(posedge clk_de, negedge rst) begin
        if(~rst) begin
            cp_done_stable <= 0;
        end else begin
            if (cp_done) begin
                if (cp_done_counter < DEBOUNCE_THRESHOLD) begin
                    cp_done_counter <= cp_done_counter + 1;
                end else begin
                    cp_done_stable <= 1;
                end
            end else begin
                cp_done_counter <= 0;
                cp_done_stable <= 0;
            end
        end
    end
    
    always @(posedge clk, negedge rst) begin
        if(~rst) begin
            cp_done_input <= 0;
            period_cp_done <= 0;
        end else begin
            cp_done_input <= next_cp_done_input;
            period_cp_done <= next_period_cp_done;
        end
    end
    
    always @(*) begin
        if (cp_done_stable) begin
            if(cp_done_input) begin
                next_period_cp_done = 1;
                next_cp_done_input = 0;
            end else begin
                next_period_cp_done = period_cp_done;
                if(~period_cp_done) begin
                    next_cp_done_input =1;
                end else begin
                    next_cp_done_input = 0;
                end
            end
        end else begin
            next_period_cp_done = 0;
            next_cp_done_input = 0;
        end
    end
    
endmodule
