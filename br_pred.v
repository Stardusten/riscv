`include "define.vh"

module br_pred(
    input   wire                    clk             ,
    input   wire                    rst             ,
    input   wire    [`InstAddrBus]  pc              ,
    input   wire                    predreq         , // 这一周期是否需要分支预测
    input   wire    [2:0]           funct3          , // 这一周期指令的 funct3
    input   wire    [`RegBus]       s1data_n        , // 这一周期指令分支判断条件中，读到的第一个操作数
    input   wire    [`RegBus]       s2data_n        , // 这一个周期指令分支判断条件中，读到的第一个操作数
    input   wire                    reg1known       , // s1data_n 是否已知
    input   wire                    reg2known       , // s2data_n 是否已知
    input   wire    [`RegBus]       offset          , // 跳转的偏移量，有符号数
    input   wire    [`RegBus]       ex_mem_wbdata   , // 数据前推，用于替换上个周期未知操作数的值，也是前一条指令要写到寄存器的值
    output  reg                     brpred_o        , // 是否跳转
    output  reg     [`RegBus]       btpred_o        , // 跳转目标
    output  reg                     mispred_o         // 是否预测错误
);

// 组合
// mispred_o        brpred_o        btpred_o
// `Enabled         `Enabled        pc +- offset    预测后一周期：预测错误，该跳转没跳转
// `Enabled         `Enabled        pc + 4          预测后一周期：预测错误，不该跳转跳转
// `Disabled        `Enabled        pc + offset     预测周期：预测跳转
// `Disabled        `Disabled       -               预测周期：预测不跳转 OR 不需要预测

reg [2:0]           funct3_prev          ; // 上个周期的 funct3
reg                 reg1known_prev       ; // 上个周期的 s1data_n 能否确定
reg                 reg2known_prev       ; // 上个周期的 s2data_n 能否确定
reg [`RegBus]       offset_prev          ; // 上个周期跳转的偏移量
reg                 predreq_prev         ; // 上个周期是否实行了分支预测
reg [`InstAddrBus]  pc_prev              ; // 上个周期的 pc
reg                 brpred_prev          ; 

// 时钟信号上升沿更新，保证这个周期读的时候，存的是上个周期的状况
always @(posedge clk) begin
    funct3_prev     <=      funct3      ;
    reg1known_prev  <=      reg1known   ;
    reg2known_prev  <=      reg2known   ;
    offset_prev     <=      offset      ;
    predreq_prev    <=      predreq     ;
    pc_prev         <=      pc          ;
    brpred_prev     <=      brpred_o    ;
end

wire should_br;
assign should_br    =   funct3_prev == `Beq  ?   s1data_n == s2data_n
                    :   funct3_prev == `Bne  ?   s1data_n != s2data_n
                    :   funct3_prev == `Blt  ?   $signed(s1data_n) < $signed(s2data_n)
                    :   funct3_prev == `Bge  ?   $signed(s1data_n) >= $signed(s2data_n)
                    :   funct3_prev == `Bltu ?   $unsigned(s1data_n) < $unsigned(s2data_n)
                    :   funct3_prev == `Bgeu ?   $unsigned(s1data_n) >= $unsigned(s2data_n)
                    :   `Disabled
                    ;

always @(*) begin
    if (predreq == `Enabled) begin // 如果这个周期要求进行分支预测
        mispred_o <= `Disabled;
        if ($signed(offset) > 0) begin // offset 为正，则预测跳转
            brpred_o <= `Enabled;
            btpred_o <= pc + $signed(offset);
        end else begin // 否则预测不跳转
            brpred_o <= `Disabled;
            btpred_o <= `Zero;
        end
    end else if (predreq_prev == `Enabled) begin // 如果上一周期进行了分支预测
        // 错误预测：应该跳转没跳转
        if (should_br == `Enabled && brpred_prev == `Disabled) begin
            mispred_o   <=  `Enabled                        ;
            brpred_o    <=  `Enabled                        ; // 需要跳转到正确目标
            btpred_o    <=  pc_prev + $signed(offset_prev)  ; // 上个周期 pc +- offset
        end
        // 错误预测：不该跳转跳转了
        else if (should_br == `Disabled && brpred_prev == `Enabled) begin
            mispred_o   <=  `Enabled                    ;
            brpred_o    <=  `Enabled                    ; // 需要跳转到正确目标
            btpred_o    <=  pc_prev + 4                 ; // 上个周期 pc + 4
        end else begin // 预测正确
            mispred_o   <=  `Disabled                   ;
            brpred_o    <=  `Disabled                   ;
            btpred_o    <=  `Zero                       ;
        end
    end else begin
        mispred_o   <=  `Disabled   ;
        brpred_o    <=  `Disabled   ;
        btpred_o    <=  `Zero       ;
    end
end

endmodule