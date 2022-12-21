`include "define.vh"

module id_ex(
    input   wire                                clk         ,
    input   wire                                rst         ,
    input   wire    [`AluSelBus]                alusel      ,
    input   wire    [`RegBus]                   s1data      ,
    input   wire    [`RegBus]                   s2data      ,
    input   wire    [`RegAddrBus]               rd          ,
    input   wire                                regwe       ,
    input   wire    [`StallCtlBus]              stall       ,
    input   wire    [`LSBus]                    loadctl     ,
    input   wire    [`LSBus]                    storectl    ,
    input   wire    [`RegBus]                   storedata   ,
    // 用于 EX 数据前推的输入 ---------
    input   wire    [`RegAddrBus]               reg1addr    , 
    input   wire                                reg1en      ,
    input   wire    [`RegAddrBus]               reg2addr    ,
    input   wire                                reg2en      ,
    input   wire                                fromreg1    ,
    input   wire                                fromreg2    ,
    // ----------------------------
    output  reg     [`AluSelBus]                alusel_o    ,
    output  reg     [`RegBus]                   s1data_o    ,
    output  reg     [`RegBus]                   s2data_o    ,
    output  reg     [`LSBus]                    loadctl_o   ,
    output  reg     [`LSBus]                    storectl_o  ,
    output  reg     [`RegBus]                   storedata_o ,
    // 用于 ID 分支检测数据前推的输出 ---
    output  reg     [`RegAddrBus]               rd_o        ,
    output  reg                                 regwe_o     ,
    // -----------------------------------
    // 用于 EX 数据前推的输出 ---------
    output  reg     [`RegAddrBus]               reg1addr_o  , 
    output  reg                                 reg1en_o    ,
    output  reg     [`RegAddrBus]               reg2addr_o  ,
    output  reg                                 reg2en_o    ,
    output  reg                                 fromreg1_o  ,
    output  reg                                 fromreg2_o  
    // ---------------------------------  
);

always @(posedge clk) begin
    if (rst == `Enabled
     || stall[2] == `True && stall[3] == `False // ID 暂停，EX 继续，则插入一个空指令
     ) begin
        alusel_o    <=  `AluNop     ;
        s1data_o    <=  `Zero       ;
        s2data_o    <=  `Zero       ;
        rd_o        <=  `NopRegAddr ;
        regwe_o     <=  `Disabled   ;
        reg1addr_o  <=  `NopRegAddr ;
        reg1en_o    <=  `Disabled   ;
        reg2addr_o  <=  `NopRegAddr ;
        reg2en_o    <=  `Disabled   ;
        loadctl_o   <=  `NoLoad     ;
        storectl_o  <=  `NoStore    ;
        storedata_o <=  `Zero       ;
        fromreg1_o  <=  `Disabled   ;
        fromreg2_o  <=  `Disabled   ;
    end else if (stall[2] == `False) begin      // ID 继续
        alusel_o    <=  alusel      ;
        s1data_o    <=  s1data      ;
        s2data_o    <=  s2data      ;
        rd_o        <=  rd          ;
        regwe_o     <=  regwe       ;
        reg1addr_o  <=  reg1addr    ;
        reg1en_o    <=  reg1en      ;
        reg2addr_o  <=  reg2addr    ;
        reg2en_o    <=  reg2en      ;
        loadctl_o   <=  loadctl     ;
        storectl_o  <=  storectl    ;
        storedata_o <=  storedata   ;
        fromreg1_o  <=  fromreg1    ;
        fromreg2_o  <=  fromreg2    ;
    end                                         // 否则保持不变
end

endmodule