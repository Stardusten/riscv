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
    input   wire    [`LSBus]        id_ex_loadctl   ,
    input   wire    [`RegAddrBus]   ex_mem_rd       ,
    input   wire                    ex_mem_regwe    ,
    input   wire    [`RegBus]       ex_mem_wbdata   ,
    input   wire    [`LSBus]        ex_mem_loadctl  ,
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
    output  reg     [`RegBus]       bt_o            , // 跳转目标
    output  reg     [`LSBus]        loadctl_o       , // load 控制信号
    output  reg     [`LSBus]        storectl_o      , // store 控制信号
    output  reg     [`RegBus]       storedata_o     , // 要写的数据
    output  reg                     fromreg1        , // s1data_o 是否来自寄存器，用于判断是否要做数据前推
    output  reg                     fromreg2        , // s2data_o 是否来自寄存器，用于判断是否要做数据前推
    // ========= 送分支预测模块 =========
    output  reg     [2:0]           funct3_o        ,
    output  reg                     predreq_o       ,
    output  reg                     reg1known_o     ,
    output  reg                     reg2known_o     ,
    output  reg     [`RegBus]       offset_o        ,
    output  reg     [`InstAddrBus]  pc_o            
);

wire    [6:0]           opcode                                                   ;
wire    [2:0]           funct3                                                   ;
wire    [6:0]           funct7                                                   ;
wire    [`AluSelBus]    alusel                                                   ;
wire    [`RegBus]       imm, reg1data_n, reg2data_n, rd                          ;
wire                    isRtype, isItype, isStype, isBtype, isUtype, isJtype, br ;
wire    [`RegAddrBus]   reg1addr, reg2addr                                       ;

assign opcode   =   inst[6:0]                                                    ;
assign funct3   =   inst[14:12]                                                  ;
assign funct7   =   inst[31:25]                                                  ;
assign reg1addr =   inst[19:15]                                                  ;
assign reg2addr =   inst[24:20]                                                  ;
assign rd       =   inst[11:7]                                                   ;

// 计算 alusel
assign alusel   = isItype
                ? ( funct3 == 3'b000 ? `AluAdd
                  : funct3 == 3'b001 ? `AluSll
                  : funct3 == 3'b010 ? `AluSlt
                  : funct3 == 3'b011 ? `AluUlt
                  : funct3 == 3'b100 ? `AluXor
                  : funct3 == 3'b101 ? (funct7 == 7'b0100000 ? `AluSra : `AluSrl)
                  : funct3 == 3'b110 ? `AluOr
                  : funct3 == 3'b111 ? `AluAnd
                  : `AluNop )
                : (isRtype
                ? ( funct3 == 3'b000 ? (funct7 == 7'b0100000 ? `AluSub : `AluAdd)
                  : funct3 == 3'b001 ? `AluSll
                  : funct3 == 3'b010 ? `AluSlt
                  : funct3 == 3'b011 ? `AluUlt
                  : funct3 == 3'b100 ? `AluXor
                  : funct3 == 3'b101 ? (funct7 == 7'b0100000 ? `AluSra : `AluSrl)
                  : funct3 == 3'b110 ? `AluOr
                  : funct3 == 3'b111 ? `AluAnd
                  : `AluNop )
                : `AluNop )
                ;

// 判断指令类型
assign isRtype  =   opcode == `ROpcode;
assign isItype  =   (opcode == `IOpcode1) | (opcode == `IOpcode2) | (opcode == `IOpcode3) | (opcode == `IOpcode4);
assign isStype  =   opcode == `SOpcode;
assign isBtype  =   opcode == `BOpcode;
assign isUtype  =   (opcode == `UOpcode1) | (opcode == `UOpcode2);
assign isJtype  =   opcode == `JOpcode;

// 判断是否需要分支
assign br       =   funct3 == `Beq  ?   reg1data_n == reg2data_n
                :   funct3 == `Bne  ?   reg1data_n != reg2data_n
                :   funct3 == `Blt  ?   $signed(reg1data_n) < $signed(reg2data_n)
                :   funct3 == `Bge  ?   $signed(reg1data_n) >= $signed(reg2data_n)
                :   funct3 == `Bltu ?   $unsigned(reg1data_n) < $unsigned(reg2data_n)
                :   funct3 == `Bgeu ?   $unsigned(reg1data_n) >= $unsigned(reg2data_n)
                :   `Disabled
                ;

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



always @(*) begin
    funct3_o    <=  funct3  ;
    offset_o    <=  imm     ;
    pc_o        <=  pc      ;
    if (rst == `Enabled || inst == `Zero) begin // reset 有效，或者是空指令，则什么都不做
        reg1addr_o      <=  `NopRegAddr     ;
        reg2addr_o      <=  `NopRegAddr     ;
        reg1re_o        <=  `Disabled       ;
        reg2re_o        <=  `Disabled       ;
        alusel_o        <=  `AluNop         ;
        s1data_o        <=  `Zero           ;
        s2data_o        <=  `Zero           ;
        rd_o            <=  `NopRegAddr     ;
        regwe_o         <=  `Disabled       ;
        stallreq_o      <=  `Disabled       ;
        br_o            <=  `Disabled       ;
        bt_o            <=  `Zero           ;
        loadctl_o       <=  `NoLoad         ;
        storectl_o      <=  `NoStore        ;
        storedata_o     <=  `Zero           ;
        fromreg1        <=  `Disabled       ;
        fromreg2        <=  `Disabled       ;
        predreq_o       <=  `Disabled       ;
        reg1known_o     <=  `Disabled       ;
        reg2known_o     <=  `Disabled       ;
    end else begin
        case (opcode)
            `IOpcode1: begin // I-type 算术指令：op rd, rs1, imm
                reg1addr_o      <=  reg1addr        ;
                reg2addr_o      <=  `NopRegAddr     ;
                reg1re_o        <=  `Enabled        ;
                reg2re_o        <=  `Disabled       ;
                alusel_o        <=  alusel          ;
                s1data_o        <=  reg1data        ;
                s2data_o        <=  imm             ;
                rd_o            <=  rd              ;
                regwe_o         <=  `Enabled        ;
                stallreq_o      <=  `Disabled       ;
                br_o            <=  `Disabled       ;
                bt_o            <=  `Zero           ;
                loadctl_o       <=  `NoLoad         ;
                storectl_o      <=  `NoStore        ;
                storedata_o     <=  `Zero           ;
                fromreg1        <=  `Enabled        ;
                fromreg2        <=  `Enabled        ;
                predreq_o       <=  `Disabled       ;
                reg1known_o     <=  `Disabled       ;
                reg2known_o     <=  `Disabled       ;
            end
            `ROpcode: begin // R-type 算术指令：op rd, rs1, rs2
                reg1addr_o      <=  reg1addr        ;
                reg2addr_o      <=  reg2addr        ;
                reg1re_o        <=  `Enabled        ;
                reg2re_o        <=  `Enabled        ;
                alusel_o        <=  alusel          ;
                s1data_o        <=  reg1data        ;
                s2data_o        <=  reg2data        ;
                rd_o            <=  rd              ;
                regwe_o         <=  `Enabled        ;
                stallreq_o      <=  `Disabled       ;
                br_o            <=  `Disabled       ;
                bt_o            <=  `Zero           ;
                loadctl_o       <=  `NoLoad         ;
                storectl_o      <=  `NoStore        ;
                storedata_o     <=  `Zero           ;
                fromreg1        <=  `Enabled        ;
                fromreg2        <=  `Enabled        ;
                predreq_o       <=  `Disabled       ;
                reg1known_o     <=  `Disabled       ;
                reg2known_o     <=  `Disabled       ;
            end
            `BOpcode: begin // B-type 分支指令：op rs1, rs2, imm
                // 存在数据相关
                // 1. 上条指令（看 id_ex_loadctl）为 load 指令， 
                //    而且 load 到现在要读的寄存器，则暂停流水线 (goto 2.)
                // 2. 上上条指令（看 ex_mem_loadctl）为 load 指令，
                //    而且 load 到现在要读的寄存器，则暂停流水线 (goto 3.)
                // 3. 上上上条指令为 load 指令，而且 load 到现在要读的寄存器，
                //    则当前应该正在写，regfile 会自动解决此冲突
                if (id_ex_loadctl  != `NoLoad && id_ex_regwe  == `Enabled && (reg1addr == id_ex_rd  || reg2addr == id_ex_rd )   // 1.
                 || ex_mem_loadctl != `NoLoad && ex_mem_regwe == `Enabled && (reg1addr == ex_mem_rd || reg2addr == ex_mem_rd)   // 2.
                ) begin
                    //======== Debug =======
                    if (id_ex_regwe    == `Enabled && (reg1addr == id_ex_rd || reg2addr == id_ex_rd)) begin
                        $display("stall 4."); 
                    end else if (id_ex_loadctl  != `NoLoad && id_ex_regwe  == `Enabled && (reg1addr == id_ex_rd  || reg2addr == id_ex_rd)) begin
                        $display("stall 1.");
                    end else if (ex_mem_loadctl != `NoLoad && ex_mem_regwe == `Enabled && (reg1addr == ex_mem_rd || reg2addr == ex_mem_rd)) begin
                        $display("stall 2.");
                    end else begin
                        $display("IMPOSSIBLE!!!");
                    end
                    //======================
                    reg1addr_o      <=  `NopRegAddr     ;
                    reg2addr_o      <=  `NopRegAddr     ;
                    reg1re_o        <=  `Disabled       ;
                    reg2re_o        <=  `Disabled       ;
                    alusel_o        <=  `AluNop         ;
                    s1data_o        <=  `Zero           ;
                    s2data_o        <=  `Zero           ;
                    rd_o            <=  `NopRegAddr     ;
                    regwe_o         <=  `Disabled       ;
                    stallreq_o      <=  `Enabled        ; // 暂停流水线
                    br_o            <=  `Disabled       ;
                    bt_o            <=  `Zero           ;
                    loadctl_o       <=  `NoLoad         ;
                    storectl_o      <=  `NoStore        ;
                    storedata_o     <=  `Zero           ;
                    fromreg1        <=  `Disabled       ;
                    fromreg2        <=  `Disabled       ;
                    predreq_o       <=  `Disabled       ;
                    reg1known_o     <=  `Disabled       ;
                    reg2known_o     <=  `Disabled       ;
                end
                // 4. 上一条不是 load 指令，要写寄存器，但还在执行阶段，要写入的值还没算出来， 
                //    导致无法判断是否需要跳转
                //    静态分支预测：先按不跳转处理，记录无法确定值的寄存器地址，下一个周期的时候
                //    这个值应该就能在 ex_mem_wbdata 里取到了。取出后执行分支条件判断，看之前的预
                //    测是否正确。
                //    risc v 规定的分支预测逻辑：正 offset 预测为跳，负 offset 预测为不跳
                else if (id_ex_regwe == `Enabled && (reg1addr == id_ex_rd || reg2addr == id_ex_rd)) begin // 4.
                    reg1addr_o      <=  reg1addr                    ;
                    reg2addr_o      <=  reg2addr                    ;
                    reg1re_o        <=  `Enabled                    ;
                    reg2re_o        <=  `Enabled                    ;
                    alusel_o        <=  `AluNop                     ;
                    s1data_o        <=  reg1data_n                  ;
                    s2data_o        <=  reg1data_n                  ;
                    rd_o            <=  `NopRegAddr                 ;
                    regwe_o         <=  `Disabled                   ;
                    stallreq_o      <=  `Disabled                   ;
                    br_o            <=  `Disabled                   ;
                    bt_o            <=  `Zero                       ;
                    loadctl_o       <=  `NoLoad                     ;
                    storectl_o      <=  `NoStore                    ;
                    storedata_o     <=  `Zero                       ;
                    fromreg1        <=  `Enabled                    ;
                    fromreg2        <=  `Enabled                    ;
                    predreq_o       <=  `Enabled                    ; // 需要分支预测
                    reg1known_o     <=  reg1addr == id_ex_rd        ;
                    reg2known_o     <=  reg2addr == id_ex_rd        ;
                end else begin // 可以判断是否需要跳转
                    // 5. 上一条读指令已经到了访存阶段，要写入的值可以在 EX/MEM
                    //    中找到，数据前推！(reg1data_n 和 reg2data_n 计算时完成) (goto 6.)
                    // 6. 上一条读指令已经到了写回阶段，此时直接读即可，regfile 在
                    //    同时读写时会自动将要写的值作为输出，自动解决这一冲突
                    reg1addr_o      <=  reg1addr                                    ;
                    reg2addr_o      <=  reg2addr                                    ;
                    reg1re_o        <=  `Enabled                                    ;
                    reg2re_o        <=  `Enabled                                    ;
                    alusel_o        <=  `AluNop                                     ;
                    s1data_o        <=  `Zero                                       ;
                    s2data_o        <=  `Zero                                       ;
                    rd_o            <=  `NopRegAddr                                 ;
                    regwe_o         <=  `Disabled                                   ;
                    stallreq_o      <=  `Disabled                                   ;
                    br_o            <=  br                                          ;
                    bt_o            <=  br == `Enabled ? pc + $signed(imm) : `Zero  ;
                    loadctl_o       <=  `NoLoad                                     ;
                    storectl_o      <=  `NoStore                                    ;
                    storedata_o     <=  `Zero                                       ;
                    fromreg1        <=  `Disabled                                   ;
                    fromreg2        <=  `Disabled                                   ;
                    predreq_o       <=  `Disabled                                   ;
                    reg1known_o     <=  `Disabled                                   ;
                    reg2known_o     <=  `Disabled                                   ;
                end
            end
            `JOpcode: begin // J-type 无条件跳转：op rd, imm(as offset) 只有 jal
                reg1addr_o      <=  `NopRegAddr                                 ;
                reg2addr_o      <=  `NopRegAddr                                 ;
                reg1re_o        <=  `Disabled                                   ;
                reg2re_o        <=  `Disabled                                   ;
                alusel_o        <=  `AluAdd                                     ; // pc + 4 写回 rd
                s1data_o        <=  pc                                          ;
                s2data_o        <=  32'h4                                       ;
                rd_o            <=  rd                                          ;
                regwe_o         <=  `Enabled                                    ;
                stallreq_o      <=  `Disabled                                   ;
                br_o            <=  br                                          ;
                bt_o            <=  br == `Enabled ? pc + $signed(imm) : `Zero  ;
                loadctl_o       <=  `NoLoad                                     ;
                storectl_o      <=  `NoStore                                    ;
                storedata_o     <=  `Zero                                       ;
                fromreg1        <=  `Disabled                                   ; // pc
                fromreg2        <=  `Disabled                                   ; // 4
                predreq_o       <=  `Disabled                                   ;
                reg1known_o     <=  `Disabled                                   ;
                reg2known_o     <=  `Disabled                                   ;
            end
            `IOpcode3: begin // jalr rd, rs1, imm
                reg1addr_o      <=  reg1addr                                            ;
                reg2addr_o      <=  `NopRegAddr                                         ;
                reg1re_o        <=  `Enabled                                            ;
                reg2re_o        <=  `Disabled                                           ;
                alusel_o        <=  `AluAdd                                             ; // pc + 4 写回 rd
                s1data_o        <=  pc                                                  ;
                s2data_o        <=  32'h4                                               ;
                rd_o            <=  rd                                                  ;
                regwe_o         <=  `Enabled                                            ;
                stallreq_o      <=  `Disabled                                           ;
                br_o            <=  br                                                  ;
                bt_o            <=  br == `Enabled ? reg1data + $signed(imm) : `Zero    ;
                loadctl_o       <=  `NoLoad                                             ;
                storectl_o      <=  `NoStore                                            ;
                storedata_o     <=  `Zero                                               ;
                fromreg1        <=  `Disabled                                           ; // pc
                fromreg2        <=  `Disabled                                           ; // 4
                predreq_o       <=  `Disabled                                           ;
                reg1known_o     <=  `Disabled                                           ;
                reg2known_o     <=  `Disabled                                           ;
            end
            `IOpcode2: begin // load rd, rs1, imm
                reg1addr_o      <=  reg1addr        ;
                reg2addr_o      <=  `NopRegAddr     ;
                reg1re_o        <=  `Enabled        ;
                reg2re_o        <=  `Disabled       ;
                alusel_o        <=  `AluAdd         ; // 要读的内存地址为 rs1 + imm
                s1data_o        <=  reg1data        ;
                s2data_o        <=  imm             ;
                rd_o            <=  rd              ; // 读到的数据存到 rd
                regwe_o         <=  `Enabled        ;
                stallreq_o      <=  `Disabled       ;
                br_o            <=  `Disabled       ;
                bt_o            <=  `Zero           ;
                loadctl_o       <=  funct3          ;
                storectl_o      <=  `NoStore        ;
                storedata_o     <=  `Zero           ;
                fromreg1        <=  `Enabled        ; // reg1data
                fromreg2        <=  `Disabled       ; // imm
                predreq_o       <=  `Disabled       ;
                reg1known_o     <=  `Disabled       ;
                reg2known_o     <=  `Disabled       ;
            end
            `SOpcode: begin // store rs1, rs2, imm
                reg1addr_o      <=  reg1addr        ;
                reg2addr_o      <=  reg2addr        ;
                reg1re_o        <=  `Enabled        ;
                reg2re_o        <=  `Enabled        ;
                alusel_o        <=  `AluAdd         ; // 要写的内存地址为 rs1 + imm
                s1data_o        <=  reg1data        ;
                s2data_o        <=  imm             ;
                rd_o            <=  `NopRegAddr     ;
                regwe_o         <=  `Disabled       ;
                stallreq_o      <=  `Disabled       ;
                br_o            <=  `Disabled       ;
                bt_o            <=  `Zero           ;
                loadctl_o       <=  `NoLoad         ;
                storectl_o      <=  funct3          ;
                storedata_o     <=  reg2data        ; // 要写的值来自 rs2
                fromreg1        <=  `Enabled        ; // reg1data
                fromreg2        <=  `Disabled       ; // imm
                predreq_o       <=  `Disabled       ;
                reg1known_o     <=  `Disabled       ;
                reg2known_o     <=  `Disabled       ;
            end
            default: begin
            end
        endcase
    end
end

endmodule