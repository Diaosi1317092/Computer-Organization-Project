module tb_pipeline();

    reg clk;
    reg rst;
    
    wire [7:0] input_data = 8'b00110011;
    
    reg done;
    
    top_module uut_tm(.init_clk(clk),.rst(rst),.sw_input(input_data),.done(done));
    
    initial begin
        clk =1'b0;
        forever #3 clk = ~clk;
    end
    
    initial begin
        rst = 1'b1;
        #1 rst = 1'b0;
        #1 rst = 1'b1;
    end
    
    initial begin
    done = 1'b0;
    #350 done = 1'b1;
    #800 done = 1'b0;
    end
endmodule