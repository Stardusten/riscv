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
        reg1addr     <=  `NopRegAddr    ;
        reg2addr     <=  `NopRegAddr    ;
        reg1re       <=  `Disabled      ;
        reg2re       <=  `Disabled      ;
        alusel       <=  `AluNop        ;
        s1data       <=  `Zero          ;
        s2data       <=  `Zero          ;
        rd           <=  `NopRegAddr    ;
        regwe        <=  `Disabled      ;
    end else begin
        reg2addr        <=  inst[24:20] ;
        if (isItype == `True && funct3 == 3'b110) begin
            // 只考虑 ORI 指令
            rd          <=  inst[11:7]  ;
            regwe       <=  `Enabled    ;
            alusel      <=  `AluOr      ;
            reg1re      <=  `True       ;   // 需要第一个寄存器的值
            reg1addr    <=  inst[19:15] ;
            reg2re      <=  `False      ;   // 不需要第二个寄存器的值，操作数 2 是 imm
            reg2addr    <=  `NopRegAddr ;
        end else begin
            // TODO impl other types
        end

        // 确定操作数 1 是来自寄存器还是立即数
        if (reg1re == `True) begin
            s1data      <=  reg1data    ;
        end else begin
            s1data      <=  imm         ;
        end

        // 确定操作数 2 是来自寄存器还是立即数
        if (reg2re == `True) begin
            s2data      <=  reg2data     ;
        end else begin
            s1data      <=  imm         ;
        end
    end
end

endmodule