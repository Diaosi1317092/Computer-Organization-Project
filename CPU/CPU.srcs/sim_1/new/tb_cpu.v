module tb_cpu();

    reg clk;
    reg rst;
    
    initial begin
        clk =1'b0;
        forever #1 clk = ~clk;
    end
    
    initial begin
        rst = 1'b1;
        #1 rst = 1'b0;
        #1 rst = 1;
    end
    reg start_pg;
    initial begin
        start_pg = 0;
        #100 start_pg = 1;
        #800 start_pg = 0;
    end
    reg rx;
    initial begin
        rx = 0;
        #10 rx = 1;
        #1000 rx = 0;
    end
    top_module uut_tm(.init_clk(clk),.fpga_rst(rst),.start_pg(start_pg));
endmodule
