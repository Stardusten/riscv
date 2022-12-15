`include "define.vh"

module regfile(
    input   wire                    clk     , // 时钟
    input   wire                    rst     , // 复位
    input   wire                    we      , // 写使能
    input   wire    [`RegAddrBus]   waddr   , // 写地址
    input   wire    [`RegBus]       wdata   , // 写数据
    input   wire                    re1     , // 读使能 1
    input   wire                    re2     , // 读使能 2
    input   wire    [`RegAddrBus]   raddr1  , // 读地址 1
    input   wire    [`RegAddrBus]   raddr2  , // 读地址 2
    output  reg     [`RegBus]       rdata1  , // 读数据 1
    output  reg     [`RegBus]       rdata2   // 读数据 2
);

reg     [`RegBus]    regs[0:`RegNum - 1];

// 初始化为全 0
integer i;
initial begin
    for (i = 0; i < `RegNum; i = i + 1) begin
        regs[i] <= `Zero;
    end
end

// 上升沿写
always @(posedge clk) begin
    if (rst == `Disabled && we == `Enabled) begin
        regs[waddr] <= wdata;
    end
end

// 下降沿读
always @(negedge clk) begin
    if (rst == `Enabled) begin
        rdata1 = `Zero;
        rdata2 = `Zero;
    end else begin
        if (re1 == `Enabled) begin
            rdata1  <= regs[raddr1];
        end
        if (re2 == `Enabled) begin
            rdata2  <=  regs[raddr2];
        end
    end
end

endmodule