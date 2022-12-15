`include "define.vh"

module id(
    input   wire                    rst         , // 复位
    input   wire    [`InstAddrBus]  pc          , // 译码阶段指令的地址
    input   wire    [`InstBus]      inst        , // 译码阶段的指令
    input   wire    [`RegBus]       reg1data    , // 从 regfile 读到的第一个寄存器的值
    input   wire    [`RegBus]       reg2data    , // 从 regfile 读到的第二个寄存器的值
    output  reg     [`RegAddrBus]   reg1addr    , // 连 regfile，要读的第一个寄存器地址
    output  reg     [`RegAddrBus]   reg2addr    , // 连 regfile，要读的第二个寄存器地址
    output  reg                     reg1re      , // 连 regfile，第一个寄存器的读使能
    output  reg                     reg2re      , // 连 regfile，第二个寄存器的读使能
    output  reg     [`AluSelBus]    alusel      , // 执行阶段 ALU 的选择信号
    output  reg     [`RegBus]       s1data      , // 执行阶段操作数 1
    output  reg     [`RegBus]       s2data      , // 执行阶段操作数 2
    output  reg     [`RegAddrBus]   rd          , // 目的寄存器地址
    output  reg                     regwe         // 连 regfile，寄存器的读使能
);

wire    [6:0]       opcode;
wire    [2:0]       funct3;
wire    [6:0]       funct7;
wire    [`RegBus]   imm;
wire                isRtype, isItype, isStype, isBtype, isUtype, isJtype;

assign opcode   =   inst[6:0];
assign funct3   =   inst[14:12];
assign funct7   =   inst[31:25];

// 判断指令类型
assign isRtype  =   opcode == `ROpcode;
assign isItype  =   (opcode == `IOpcode1) | (opcode == `IOpcode2) | (opcode == `IOpcode3) | (opcode == `IOpcode4);
assign isStype  =   opcode == `SOpcode;
assign isBtype  =   opcode == `BOpcode;
assign isUtype  =   (opcode == `UOpcode1) | (opcode == `UOpcode2);
assign isJtype  =   opcode == `JOpcode;

// 根据指令类型，拼接得到 imm
assign imm = isRtype ? {32{1'b0}} :
             isItype ? {{20{inst[31]}}, inst[31:20]} :
             isStype ? {{20{inst[31]}}, inst[31:25], inst[11:7]} :
             isBtype ? {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0} :
             isUtype ? {inst[31:12], {12{1'b0}}} :
             isJtype ? {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0} :
             {32{1'b0}}; // 未知指令

always @(*) begin
    if (rst == `Enabled) begin
        reg1addr        <=  `NopRegAddr    ;
        reg2addr        <=  `NopRegAddr    ;
        reg1re          <=  `Disabled      ;
        reg2re          <=  `Disabled      ;
        alusel          <=  `AluNop        ;
        s1data          <=  `Zero          ;
        s2data          <=  `Zero          ;
        rd              <=  `NopRegAddr    ;
        regwe           <=  `Disabled      ;
    end else begin

        // 计算 alusel
        if (isItype) begin
            case (funct3)
                3'b000  :   alusel  <=   `AluAdd                                    ;
                3'b001  :   alusel  <=   `AluSll                                    ;
                3'b010  :   alusel  <=   `AluSlt                                    ;
                3'b011  :   alusel  <=   `AluUlt                                    ;
                3'b100  :   alusel  <=   `AluXor                                    ;
                3'b101  :   alusel  <=   funct7 == 7'b0100000 ? `AluSra : `AluSrl   ;
                3'b110  :   alusel  <=   `AluOr                                     ;
                3'b111  :   alusel  <=   `AluAnd                                    ;
            endcase
        end else if (isRtype) begin
            case (funct3)
                3'b000  :   alusel  <=   funct7 == 7'b0100000 ? `AluSub : `AluAnd   ;
                3'b001  :   alusel  <=   `AluSll                                    ;
                3'b010  :   alusel  <=   `AluSlt                                    ;
                3'b011  :   alusel  <=   `AluUlt                                    ;
                3'b100  :   alusel  <=   `AluXor                                    ;
                3'b101  :   alusel  <=   funct7 == 7'b0100000 ? `AluSra : `AluSrl   ;
                3'b110  :   alusel  <=   `AluOr                                     ;
                3'b111  :   alusel  <=   `AluAnd                                    ;
            endcase
        end

        case (opcode)
            `IOpcode1: begin // I-type 算术指令：op rd, rs1, imm
                rd          <=  inst[11:7]      ; // 需要写回
                regwe       <=  `Enabled        ;
                reg1re      <=  `True           ; // 第一个操作数为寄存器
                reg1addr    <=  inst[19:15]     ;
                reg2re      <=  `False          ; // 第二个操作数为立即数
                reg2addr    <=  `NopRegAddr     ;
            end
            `ROpcode: begin // R-type 算术指令：op rd, rs1, rs2
                rd          <=  inst[11:7]      ; // 需要写回
                regwe       <=  `Enabled        ;
                reg1re      <=  `True           ; // 第一个操作数为寄存器
                reg1addr    <=  inst[19:15]     ;
                reg2re      <=  `True           ; // 第二个操作数也为寄存器
                reg2addr    <=  inst[24:20]     ;
            end
        endcase

        //  确定操作数是来自寄存器还是立即数
        s1data  <=  reg1re ? reg1data : imm ;
        s2data  <=  reg2re ? reg2data : imm ;
    end
end

endmodule