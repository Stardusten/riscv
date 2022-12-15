`include "define.vh"

`timescale 1ns/1ps

module spoc_tb();

reg     CLOCK_50;
reg     rst;

initial begin
    // 每隔 10ns，CLOCK_50 信号反转，主频 50MHz
    CLOCK_50 = 1'b0;
    forever begin
        #10 CLOCK_50 = ~ CLOCK_50;
    end
end

initial begin
    rst = `Enabled;         // 开始时 rst 有效
    #195 rst = `Disabled;   // 195ns 时 rst 无效，开始仿真
    #1000 $stop;            // 1000ns 后停止
end

spoc spoc0(.clk(CLOCK_50), .rst(rst));

endmodule
