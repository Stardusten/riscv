`include "define.vh"

module ex(
    input   wire                    rst             , // 复位
    input   wire    [`AluSelBus]    alusel          , // ALU 选择信号
    input   wire    [`RegBus]       s1data          , // 操作数 1
    input   wire    [`RegBus]       s2data          , // 操作数 2
    input   wire    [`RegAddrBus]   rd              , // 结果要写入哪个目的寄存器
    input   wire                    regwe           , // 写使能
    // 用于数据前推的输入 ----------
    input   wire    [`RegAddrBus]   reg1addr        ,
    input   wire                    reg1en          ,
    input   wire    [`RegAddrBus]   reg2addr        ,
    input   wire                    reg2en          ,
    input   wire    [`RegAddrBus]   ex_mem_rd       ,
    input   wire                    ex_mem_regwe    ,
    input   wire    [`RegBus]       ex_mem_wbdata   ,
    input   wire    [`RegAddrBus]   wb_rd           ,
    input   wire                    wb_regwe        ,
    input   wire    [`RegBus]       wb_wbdata       ,
    // ------------------------------
    output  reg     [`RegAddrBus]   rd_o            ,
    output  reg                     regwe_o         ,
    output  reg     [`RegBus]       result             // 运算结果
);

// 数据前推
wire    [`RegBus]   s1data_n, s2data_n; // 新的输入输出
assign s1data_n = ex_mem_regwe == `True && reg1en == `True && ex_mem_rd == reg1addr   ?   ex_mem_wbdata
            :   wb_regwe     == `True && reg1en == `True && wb_rd     == reg1addr   ?   wb_wbdata
            :   s1data;

assign s2data_n = ex_mem_regwe == `True && reg2en == `True && ex_mem_rd == reg2addr   ?   ex_mem_wbdata
            :   wb_regwe     == `True && reg2en == `True && wb_rd     == reg2addr   ?   wb_wbdata
            :   s2data;

always @(*) begin
    // rd 和 regwe 直接送入下一阶段
    rd_o    <=  rd;
    regwe_o <=  regwe;
    if (rst == `Enabled) begin
        result  <= `Zero;
    end else begin
        case (alusel) // 根据 alusel 选择运算类型
            `AluAdd     :   result  <=  $signed(s1data_n) + $signed(s2data_n)       ;
            `AluSub     :   result  <=  $signed(s1data_n) - $signed(s2data_n)       ;
            `AluSll     :   result  <=  s1data_n << s2data_n                        ;
            `AluSrl     :   result  <=  s1data_n >> s2data_n                        ;
            `AluSra     :   result  <=  s1data_n >>> s2data_n                       ;
            `AluXor     :   result  <=  s1data_n ^ s2data_n                         ;
            `AluOr      :   result  <=  s1data_n | s2data_n                         ;
            `AluAnd     :   result  <=  s1data_n & s2data_n                         ;
            `AluUlt     :   result  <=  $unsigned(s1data_n) < $unsigned(s2data_n)   ;
            `AluSlt     :   result  <=  $signed(s1data_n) < $signed(s2data_n)       ;
            default     :   result  <= `Zero                                    ;
        endcase
    end
end

endmodule