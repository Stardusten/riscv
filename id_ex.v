`include "define.vh"

module id_ex(
    input   wire                                clk         ,
    input   wire                                rst         ,
    input   wire    [`AluSelBus]                alusel      ,
    input   wire    [`RegBus]                   s1data      ,
    input   wire    [`RegBus]                   s2data      ,
    input   wire    [`RegAddrBus]               rd          ,
    input   wire                                regwe       ,
    output  reg     [`AluSelBus]                alusel_o    ,
    output  reg     [`RegBus]                   s1data_o    ,
    output  reg     [`RegBus]                   s2data_o    ,
    output  reg     [`RegAddrBus]               rd_o        ,
    output  reg                                 regwe_o     
);

always @(posedge clk) begin
    if (rst == `Enabled) begin
        alusel_o    <=  `AluNop     ;
        s1data_o    <=  `Zero       ;
        s2data_o    <=  `Zero       ;
        rd_o        <=  `NopRegAddr ;
        regwe_o     <=  `Disabled   ;
    end else begin
        alusel_o    <=  alusel      ;
        s1data_o    <=  s1data      ;
        s2data_o    <=  s2data      ;
        rd_o        <=  rd          ;
        regwe_o     <=  regwe       ;
    end
end

endmodule