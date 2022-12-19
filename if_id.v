`include "define.vh"

module if_id(
    input   wire                    clk         ,
    input   wire                    rst         ,
    input   wire                    flushreq    ,
    input   wire    [`StallCtlBus]  stall       ,
    input   wire    [`InstAddrBus]  pc          ,
    input   wire    [`InstBus]      inst        ,
    output  reg     [`InstAddrBus]  pc_o        ,
    output  reg     [`InstBus]      inst_o  
);

always @(posedge clk) begin
    if (rst == `Enabled
     || flushreq == `Enabled                    // 如果 flush 有效，则说明分支发生，需要清空 ID/IF
     || stall[1] == `True && stall[2] == `False  // IF 暂停，ID 继续，则插入一个空指令
    ) begin
        pc_o   <=  0       ;
        inst_o <=  `Zero   ;
    end else if (stall[1] == `False) begin      // IF 继续
        pc_o   <=  pc      ;
        inst_o <=  inst    ;
    end                                         // 否则保持不变
end

endmodule