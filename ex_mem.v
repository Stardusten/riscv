`include "define.vh"

module ex_mem(
    input   wire                        clk         ,
    input   wire                        rst         ,
    input   wire    [`RegAddrBus]       rd          ,
    input   wire                        regwe       ,
    input   wire    [`RegBus]           result      ,
    output  reg     [`RegAddrBus]       rd_o        ,
    output  reg                         regwe_o     ,
    output  reg     [`RegBus]           wbdata      
);

always @(posedge clk) begin
    if (rst == `Enabled) begin
        rd_o    <=  `NopRegAddr ;
        regwe_o <=  `Disabled   ;
        wbdata  <=  `Zero       ;
    end else begin
        rd_o    <=  rd          ;
        regwe_o <=  regwe       ;
        wbdata  <=  result      ;
    end
end

endmodule