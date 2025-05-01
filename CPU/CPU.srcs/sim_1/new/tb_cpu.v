module tb_cpu();

    reg clk;
    reg rst;

    top_module uut_tm(.clk(clk),.rst(rst));
    
    initial begin
        clk =1'b0;
        forever #30 clk = ~clk;
    end
    
    initial begin
        rst = 1'b1;
        #10 rst = 1'b0;
        #10 rst = 1'b1;
    end

endmodule
