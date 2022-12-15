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
    output  reg     [`RegBus]       rdata2    // 读数据 2
);

reg     [`RegBus]    regs[0:`RegNum - 1];

// 初始化为全 0
integer i;
initial begin
    for (i = 0; i < `RegNum; i = i + 1) begin
        regs[i] <= `Zero;
    end
end

always @(*) begin
    // 写
    if (rst == `Disabled && we == `Enabled) begin
        regs[waddr] <= wdata;
    end

    // 读：如果同时读写同一个寄存器，则先写后读，即令读者读到的是写者要写入的值
    if (rst == `Enabled) begin
        rdata1 = `Zero;
        rdata2 = `Zero;
    end else begin
        if (re1 == `Enabled) begin
            rdata1 <= we == `Enabled && waddr == raddr1
                ?  wdata
                :  regs[raddr1];
        end
        if (re2 == `Enabled) begin
            rdata2 <= we == `Enabled && waddr == raddr2
                ?  wdata
                :  regs[raddr2];
        end
    end
end

endmodule