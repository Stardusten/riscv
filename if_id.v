`include "define.vh"

module if_id(
    input   wire                    clk     ,
    input   wire                    rst     ,
    input   wire    [`InstAddrBus]  pc      ,
    input   wire    [`InstBus]      inst    ,
    output  reg     [`InstAddrBus]  pc_o    ,
    output  reg     [`InstBus]      inst_o  
);

always @(posedge clk) begin
    if (rst == `Enabled) begin
        pc_o   <=  0       ;
        inst_o <=  `Zero   ;
    end else begin
        pc_o   <=  pc      ;
        inst_o <=  inst    ;
    end
end

endmodule