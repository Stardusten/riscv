`include "define.vh"

module ram(
    input   wire                                clk     ,
    input   wire                                we      , // 写使能
    input   wire    [`DataAddrBus]              waddr   , // 写地址
    input   wire    [`DataBus]                  wdata   , // 要写入的数据
    input   wire                                re      , // 读使能
    input   wire    [`DataAddrBus]              raddr   , // 读地址
    output  reg     [`DataBus]                  data_o    // 读到的数据
);

reg [`RamMemSize]   MEM[0:`RamMemNum];

// 全 0 初始化
integer i;
initial begin
    for (i = 0; i < `RamMemSize; i = i + 1) begin
        MEM[i] = `Zero;
    end
end

always @(*) begin
    // 写
    if (we == `Enabled) begin
        MEM[waddr]      <=  wdata[31:24];
        MEM[waddr + 1]  <=  wdata[23:16];
        MEM[waddr + 2]  <=  wdata[15:8] ;
        MEM[waddr + 3]  <=  wdata[7:0]  ;
    end
    // 读
    data_o  <=  re == `Enabled
            ?   { MEM[raddr], MEM[raddr + 1], MEM[raddr + 2], MEM[raddr + 3] }
            :   `Zero;
end

endmodule