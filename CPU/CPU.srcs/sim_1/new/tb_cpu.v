module tb_cpu();

    reg clk;
    reg rst;

    top_module uut_tm(.init_clk(clk),.rst(rst));
    
    initial begin
        clk =1'b0;
        forever #3 clk = ~clk;
    end
    
    initial begin
        rst = 1'b1;
        #1 rst = 1'b0;
        #1 rst = 1'b1;
    end

endmodule
