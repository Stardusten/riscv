`include "define.vh"

module stall_ctl(
    input   wire                    rst         ,
    input   wire                    id_stallreq ,
    input   wire                    ex_stallreq ,
    output  wire    [`StallCtlBus]  stall
    // stall[0] == `True 表示 pc 保持不变
    // stall[i] == `True, i > 0 表示暂停第 i 个阶段
);

assign stall = rst == `Enabled           ?   6'b000000
             : ex_stallreq == `Enabled   ?   6'b001111
             : id_stallreq == `Enabled   ?   6'b000111
             : 6'b000000;

endmodule