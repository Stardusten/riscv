`include "define.vh"

module mem_wb(
    input   wire                        clk         ,
    input   wire                        rst         ,
    input   wire    [`RegAddrBus]       rd          ,
    input   wire                        regwe       ,
    input   wire    [`RegBus]           wbdata      ,
    input   wire    [`StallCtlBus]      stall       ,
    output  reg     [`RegAddrBus]       rd_o        ,
    output  reg                         regwe_o     ,
    output  reg     [`RegBus]           wbdata_o    
);

always @(posedge clk) begin
    if (rst == `Enabled
     || stall[4] == `True && stall[5] == `False // MEM 暂停，WB 继续，则插入一个空指令
    ) begin
        rd_o        <=  `NopRegAddr ;
        regwe_o     <=  `Disabled   ;
        wbdata_o    <=  `Zero       ;
    end else if (stall[4] == `False) begin      // MEM 继续
        rd_o        <=  rd          ;
        regwe_o     <=  regwe       ;
        wbdata_o    <=  wbdata      ;
    end                                         // 否则保持不变
end

endmodule