`include "define.vh"

module ex(
    input   wire                    rst         , // 复位
    input   wire    [`AluSelBus]    alusel      , // ALU 选择信号
    input   wire    [`RegBus]       s1data      , // 操作数 1
    input   wire    [`RegBus]       s2data      , // 操作数 2
    input   wire    [`RegAddrBus]   rd          , // 结果要写入哪个目的寄存器
    input   wire                    regwe       , // 写使能
    output  reg     [`RegAddrBus]   rd_o        ,
    output  reg                     regwe_o     ,
    output  reg     [`RegBus]       result        // 运算结果
);

always @(*) begin
    // rd 和 regwe 直接送入下一阶段
    rd_o    <=  rd;
    regwe_o <=  regwe;
    if (rst == `Enabled) begin
        result  <= `Zero;
    end else begin
        case (alusel)
            `AluOr: begin
                result  <= s1data | s2data;
            end
            default: begin
                result  <= `Zero; // TODO impl other types
            end
        endcase
    end
end

endmodule