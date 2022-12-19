`include "define.vh"

module id(
    input   wire                    rst             , // 复位
    input   wire    [`InstAddrBus]  pc              , // 译码阶段指令的地址
    input   wire    [`InstBus]      inst            , // 译码阶段的指令
    input   wire    [`RegBus]       reg1data        , // 从 regfile 读到的第一个寄存器的值
    input   wire    [`RegBus]       reg2data        , // 从 regfile 读到的第二个寄存器的值
    // 用于分支检测数据前推的输入 --------------
    input   wire    [`RegAddrBus]   id_ex_rd        ,
    input   wire                    id_ex_regwe     ,
    input   wire    [`RegAddrBus]   ex_mem_rd       ,
    input   wire                    ex_mem_regwe    ,
    input   wire    [`RegBus]       ex_mem_wbdata   ,
    // -----------------------------------------
    output  reg     [`RegAddrBus]   reg1addr_o      , // 连 regfile，要读的第一个寄存器地址
    output  reg     [`RegAddrBus]   reg2addr_o      , // 连 regfile，要读的第二个寄存器地址
    output  reg                     reg1re_o        , // 连 regfile，第一个寄存器的读使能
    output  reg                     reg2re_o        , // 连 regfile，第二个寄存器的读使能
    output  reg     [`AluSelBus]    alusel_o        , // 执行阶段 ALU 的选择信号
    output  reg     [`RegBus]       s1data_o        , // 执行阶段操作数 1
    output  reg     [`RegBus]       s2data_o        , // 执行阶段操作数 2
    output  reg     [`RegAddrBus]   rd_o            , // 目的寄存器地址
    output  reg                     regwe_o         , // 连 regfile，寄存器的读使能
    output  reg                     stallreq_o      , // 是否暂停流水线
    output  reg                     br_o            , // 是否跳转
    output  reg     [`RegBus]       bt_o              // 跳转目标
);

wire    [6:0]           opcode;
wire    [2:0]           funct3;
wire    [6:0]           funct7;
wire    [`RegBus]       imm, reg1data_n, reg2data_n;
wire                    isRtype, isItype, isStype, isBtype, isUtype, isJtype;

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

// 分支预测数据前推
assign reg1data_n = ex_mem_regwe == `Enabled && reg1addr == ex_mem_rd   ?   ex_mem_wbdata   :   reg1data;
assign reg2data_n = ex_mem_regwe == `Enabled && reg2addr == ex_mem_rd   ?   ex_mem_wbdata   :   reg2data;

// 根据指令类型，拼接得到 imm
assign imm = isRtype ? {32{1'b0}} :
             isItype ? {{20{inst[31]}}, inst[31:20]} :
             isStype ? {{20{inst[31]}}, inst[31:25], inst[11:7]} :
             isBtype ? {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0} :
             isUtype ? {inst[31:12], {12{1'b0}}} :
             isJtype ? {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0} :
             {32{1'b0}}; // 未知指令

always @(rst, pc, inst, reg1data, reg2data) begin // 避免反馈回路
    if (rst == `Enabled || inst == `Zero) begin // reset 有效，或者是空指令，则什么都不做
        reg1addr        <=  `NopRegAddr    ;
        reg2addr        <=  `NopRegAddr    ;
        reg1re          <=  `Disabled      ;
        reg2re          <=  `Disabled      ;
        alusel          <=  `AluNop        ;
        s1data          <=  `Zero          ;
        s2data          <=  `Zero          ;
        rd              <=  `NopRegAddr    ;
        regwe           <=  `Disabled      ;
        stallreq        <=  `Disabled      ;
        br              <=  `Disabled      ;
        bt              <=  `Zero          ;
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
                3'b000  :   alusel  <=   funct7 == 7'b0100000 ? `AluSub : `AluAdd   ;
                3'b001  :   alusel  <=   `AluSll                                    ;
                3'b010  :   alusel  <=   `AluSlt                                    ;
                3'b011  :   alusel  <=   `AluUlt                                    ;
                3'b100  :   alusel  <=   `AluXor                                    ;
                3'b101  :   alusel  <=   funct7 == 7'b0100000 ? `AluSra : `AluSrl   ;
                3'b110  :   alusel  <=   `AluOr                                     ;
                3'b111  :   alusel  <=   `AluAnd                                    ;
            endcase
        end

        // 默认值
        reg1addr                    <=   inst[19:15]    ;
        reg2addr                    <=   inst[24:20]    ;
        rd                          <=   inst[11:7]     ;

        case (opcode)
            `IOpcode1: begin // I-type 算术指令：op rd, rs1, imm
                reg1re              <=   `Enabled       ;
                reg1addr            <=   inst[19:15]    ;
                reg2re              <=   `Disabled      ; // 不需要写第二个寄存器
                reg2addr            <=   `NopRegAddr    ;
                regwe               <=   `Enabled       ;
                stallreq            <=   `Disabled      ;
                s1data              <=   reg1data       ; // rd := rs1 (op) imm
                s2data              <=   imm            ;
                br                  <=   `False         ;
                bt                  <=   `Zero          ;
            end
            `ROpcode: begin // R-type 算术指令：op rd, rs1, rs2
                reg1re              <=   `Enabled       ;
                reg1addr            <=   inst[19:15]    ;
                reg2re              <=   `Enabled       ;
                reg2addr            <=   inst[24:20]    ;
                regwe               <=   `Enabled       ;
                rd                  <=   inst[11:7]     ;
                stallreq            <=   `Disabled      ;
                s1data              <=   reg1data       ;
                s2data              <=   reg2data       ;
                br                  <=   `False         ;
                bt                  <=   `Zero          ;
            end
            `BOpcode: begin // B-type 分支指令：op rs1, rs2, imm
                // 存在数据相关
                // 1. 上一条读指令还在执行阶段，要写入的值还没算出来，
                //    导致无法判断是否需要跳转，暂停流水线 TODO 分支预测
                if (id_ex_regwe == `Enabled && inst[19:15] == id_ex_rd
                 || id_ex_regwe == `Enabled && reg2addr == id_ex_rd) begin
                    reg1re          <=  `Disabled       ;
                    reg2re          <=  `Disabled       ;
                    reg1addr        <=  `NopRegAddr     ;
                    reg2addr        <=  `NopRegAddr     ;
                    regwe           <=  `Disabled       ;
                    rd              <=  `NopRegAddr     ;
                    alusel          <=  `AluNop         ;
                    s1data          <=  `Zero           ;
                    s2data          <=  `Zero           ;
                    stallreq        <=  `Enabled        ; // 暂停流水线
                    br              <=  `Disabled       ;
                    bt              <=  `Zero           ;
                end else begin // 可以判断是否需要跳转
                // 2. 上一条读指令已经到了访存阶段，要写入的值可以在 EX/MEM
                //    中找到，数据前推！(reg1data_n 和 reg2data_n 计算时完成)
                // 3. 上一条读指令已经到了写回阶段，此时直接读即可，regfile 在
                //    同时读写时会自动将要写的值作为输出，解决这一冲突
                    $display("No need to stall. %d %d %d %d %d %d", id_ex_regwe, id_ex_rd, reg1addr, reg2addr, reg1addr == id_ex_rd, reg2addr == id_ex_rd);
                    reg1re          <=  `Enabled        ;
                    reg2re          <=  `Enabled        ;
                    regwe           <=  `Disabled       ; // EX 阶段什么都不做
                    rd              <=  `NopRegAddr     ;
                    stallreq        <=  `Disabled       ;
                    alusel          <=  `AluNop         ;
                    s1data          <=  `Zero           ;
                    s2data          <=  `Zero           ;
                    case (funct3)
                        `Beq: begin
                            if (reg1data_n == reg2data_n) begin
                                br <= `True     ;
                                bt <= pc + imm  ;
                            end
                        end
                        `Bne: begin
                            if (reg1data_n != reg2data_n) begin
                                br <= `True     ;
                                bt <= pc + imm  ;
                            end
                        end
                        `Blt: begin
                            if ($signed(reg1data_n) < $signed(reg2data_n)) begin
                                br <= `True     ;
                                bt <= pc + imm  ;
                            end
                        end
                        `Bge: begin
                            if ($signed(reg1data_n) >= $signed(reg2data_n)) begin
                                br <= `True     ;
                                bt <= pc + imm  ;
                            end
                        end
                        `Bltu: begin
                            if ($unsigned(reg1data_n) < $unsigned(reg2data_n)) begin
                                br <= `True     ;
                                bt <= pc + imm  ;
                            end
                        end
                        `Bgeu: begin
                            if ($unsigned(reg1data_n) >= $unsigned(reg2data_n)) begin
                                br <= `True     ;
                                bt <= pc + imm  ;
                            end
                        end
                    endcase
                end
            end
            `JOpcode: begin // J-type 无条件跳转：op rd, imm(as offset) 只有 jal
                reg1re              <=  `Disabled           ;
                reg2re              <=  `Disabled           ;
                reg1addr            <=  `NopRegAddr         ;
                reg2addr            <=  `NopRegAddr         ;
                br                  <=  `Enabled            ;
                bt                  <=  pc + $signed(imm)   ; // 跳转地址，立即数作为有符号数解释
                alusel              <=  `AluAdd             ; // pc + 4 写回 rd
                s1data              <=  pc                  ;
                s2data              <=  32'h4               ;
                regwe               <=  `Enabled            ;
            end
            `IOpcode3: begin // jalr rd, rs1, imm
                reg1re              <=  `Enabled                ;
                reg2re              <=  `Disabled               ;
                reg2addr            <=  `NopRegAddr             ;   
                br                  <=  `Enabled                ;
                bt                  <=  reg1data + $signed(imm) ; // 跳转地址，立即数作为有符号数解释
                alusel              <=  `AluAdd                 ; // pc + 4 写回 rd
                s1data              <=  pc                      ;
                s2data              <=  32'h4                   ;
                regwe               <=  `Enabled                ;
            end
            default: begin
            end
        endcase
    end
end

endmodule