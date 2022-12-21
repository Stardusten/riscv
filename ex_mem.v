`include "define.vh"

module ex_mem(
    input   wire                        clk         ,
    input   wire                        rst         ,
    input   wire    [`RegAddrBus]       rd          ,
    input   wire                        regwe       ,
    input   wire    [`RegBus]           result      ,
    input   wire    [`StallCtlBus]      stall       ,
    input   wire    [`LSBus]            loadctl     ,
    input   wire    [`LSBus]            storectl    ,
    input   wire    [`RegBus]           storedata   ,
    output  reg     [`RegAddrBus]       rd_o        ,
    output  reg                         regwe_o     ,
    output  reg     [`RegBus]           result_o    ,
    output  reg     [`LSBus]            loadctl_o   ,
    output  reg     [`LSBus]            storectl_o  ,
    output  reg     [`RegBus]           storedata_o 
);

always @(posedge clk) begin
    if (rst == `Enabled
     || stall[3] == `True && stall[4] == `False // EX 暂停，MEM 继续，则插入一个空指令
    ) begin
        rd_o        <=  `NopRegAddr ;
        regwe_o     <=  `Disabled   ;
        result_o    <=  `Zero       ;
        loadctl_o   <=  `NoLoad     ;
        storectl_o  <=  `NoStore    ;
        storedata_o <=  `Zero       ;
    end else if (stall[3] == `False) begin      // EX 继续
        rd_o        <=  rd          ;
        regwe_o     <=  regwe       ;
        result_o    <=  result      ;
        loadctl_o   <=  loadctl     ;
        storectl_o  <=  storectl    ;
        storedata_o <=  storedata   ;
    end                                         // 否则保持不变
end

endmodule