`include "define.vh"

module mem_wb(
    input   wire                        clk         ,
    input   wire                        rst         ,
    input   wire    [`RegAddrBus]       rd          ,
    input   wire                        regwe       ,
    input   wire    [`RegBus]           wbdata      ,
    output  reg     [`RegAddrBus]       rd_o        ,
    output  reg                         regwe_o     ,
    output  reg     [`RegBus]           wbdata_o    
);

always @(posedge clk) begin
    if (rst == `Enabled) begin
        rd_o        <=  `NopRegAddr ;
        regwe_o     <=  `Disabled   ;
        wbdata_o    <=  `Zero       ;
    end else begin
        rd_o        <=  rd          ;
        regwe_o     <=  regwe       ;
        wbdata_o    <=  wbdata      ;
    end
end

endmodule