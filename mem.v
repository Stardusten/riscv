`include "define.vh"

module mem(
    input   wire                        rst         ,
    input   wire    [`RegAddrBus]       rd          ,
    input   wire                        regwe       ,
    input   wire    [`RegBus]           result      ,
    input   wire    [`DataBus]          ramdata     , // ram 读出的 data
    input   wire    [`LSBus]            loadctl     ,
    input   wire    [`LSBus]            storectl    ,
    input   wire    [`RegBus]           storedata   ,
    output  reg     [`RegAddrBus]       rd_o        ,
    output  reg                         regwe_o     ,
    output  reg     [`RegBus]           wbdata_o    ,
    // 送 ram 的输出
    output  reg                         ramwe       , // 是否写 ram
    output  reg     [`DataAddrBus]      ramwaddr    , // 写 ram 地址
    output  reg     [`DataBus]          ramwdata    , // 写入的数据
    output  reg                         ramre       , // 是否读 ram
    output  reg     [`DataAddrBus]      ramraddr      // 读 ram 地址
);

always @(*) begin
    if (rst == `Enabled) begin
        rd_o        <=  `NopRegAddr ;
        regwe_o     <=  `Disabled   ;
        wbdata_o    <=  `Zero       ;
        ramwe       <=  `Disabled   ;
        ramwaddr    <=  `Zero       ;
        ramwdata    <=  `Zero       ;
        ramre       <=  `Disabled   ;
        ramraddr    <=  `Zero       ;
    end else begin
        if (loadctl != `NoLoad) begin
            ramwe       <=  `Disabled   ; // 不写 ram
            ramwaddr    <=  `Zero       ;
            ramwdata    <=  `Zero       ;
            ramre       <=  `Enabled    ; // 读 ram
            ramraddr    <=  result      ;
            rd_o        <=  rd          ; // 写回读到的值
            regwe_o     <=  regwe       ;
            case (loadctl)
                `LoadByte   :  wbdata_o <= { {24{ramdata[7]}}, ramdata[7:0] };
                `LoadHalf   :  wbdata_o <= { {16{ramdata[15]}}, ramdata[15:0] };
                `LoadWord   :  wbdata_o <= ramdata;
                `LoadByteU  :  wbdata_o <= { {24{1'b0}}, ramdata[7:0] };
                `LoadHalfU  :  wbdata_o <= { {16{1'b0}}, ramdata[15:0] };
            endcase 
        end else if (storectl != `NoStore) begin
            ramwe       <=  `Enabled    ; // 写 ram
            ramwaddr    <=  result      ;
            ramre       <=  `Disabled   ; // 不读 ram
            ramraddr    <=  `Zero       ;
            rd_o        <=  `NopRegAddr ; // 不写回
            regwe_o     <=  `Disabled   ;
            wbdata_o    <=  `Zero       ;
            case(storectl)
                `StoreByte  :  ramwdata <= { {24{1'b0}}, storedata[7:0] };
                `StoreHalf  :  ramwdata <= { {16{1'b0}}, storedata[15:0] };
                `StoreWord  :  ramwdata <= storedata;
            endcase 
        end else begin
            rd_o        <=  rd          ;
            regwe_o     <=  regwe       ;
            wbdata_o    <=  result      ;
            ramwe       <=  `Disabled   ; // 不写
            ramwaddr    <=  `Zero       ;
            ramwdata    <=  `Zero       ;
            ramre       <=  `Disabled   ; // 不读
            ramraddr    <=  `Zero       ;
        end
    end
end

endmodule