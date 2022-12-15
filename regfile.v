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

reg[`RegBus]    regs[0:`RegNum - 1];

always @(posedge clk) begin
    if (rst == `Enabled) begin
        rdata1 = `Zero;
        rdata2 = `Zero;
    end else begin
        if (we == `Enabled) begin
            regs[waddr] <= wdata;
        end
        if (re1 == `Enabled) begin
            // 解决译码 - 回写冲突
            // 如果下一指令译码时需要访问上一指令回写的目标寄存器，
            // 则直接将上一指令要写的数据作为下一指令读出的数据
            if ((raddr1 == waddr) && (we == `Enabled)) begin
                rdata1  <=  wdata           ;
            end else begin
                rdata1  <= regs[raddr1]     ;
            end
        end
        if (re2 == `Enabled) begin
            // 解决译码 - 回写冲突
            if ((raddr2 == waddr) && (we == `Enabled)) begin
                rdata2  <=  wdata           ;
            end else begin
                rdata2  <=  regs[raddr2]    ;
            end
        end
    end
end

endmodule