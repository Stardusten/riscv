`include "define.vh"

module riscv(
    input   wire                        rst         , // 复位
    input   wire                        clk         , // 时钟
    input   wire    [`RegBus]           inst        , // 要执行的指令，从 rom 读出
    input   wire    [`DataBus]          ramdata     , // 从 ram 读出的数据
    // rom 控制线
    output  wire    [`RegBus]           instaddr    , // 下一条指令地址
    output  wire                        romen       , // rom 使能
    // ram 控制线
    output  wire                        ramwe       , // 是否写 ram
    output  wire     [`DataAddrBus]     ramwaddr    , // 写 ram 地址
    output  wire     [`DataBus]         ramwdata    , // 写入的数据
    output  wire                        ramre       , // 是否读 ram
    output  wire     [`DataAddrBus]     ramraddr      // 读 ram 地址
);

// 流水线暂停控制
wire    [`StallCtlBus]  stall           ;
wire                    id_stallreq     ;
wire                    ex_stallreq     ;

// 冲刷流水线
wire                    if_id_flushreq  ;

// 连接 PC 与 IF/ID
wire    [`InstAddrBus]  pc_pc           ;
wire                    pc_ce           ;

wire                    pc_stallreq     ;
wire                    pc_br           ;
wire    [`RegBus]       pc_bt           ;

// 连接 IF/ID 与 ID
wire    [`InstAddrBus]  if_id_pc        ;
wire    [`InstBus]      if_id_inst      ;

// 连接 ID 与 ID/EX
wire    [`AluSelBus]    id_alusel       ;
wire    [`RegBus]       id_s1data       ;
wire    [`RegBus]       id_s2data       ;
wire    [`RegAddrBus]   id_rd           ;
wire                    id_regwe        ;
wire                    id_br           ;
wire    [`RegBus]       id_bt           ;
wire    [`LSBus]        id_loadctl      ;
wire    [`LSBus]        id_storectl     ;
wire    [`RegBus]       id_storedata    ;
wire                    id_fromreg1     ;
wire                    id_fromreg2     ;

// 连接 ID/EX 与 EX
wire    [`AluSelBus]    id_ex_alusel    ;
wire    [`RegBus]       id_ex_s1data    ;
wire    [`RegBus]       id_ex_s2data    ;
wire    [`RegAddrBus]   id_ex_rd        ;
wire                    id_ex_regwe     ;
wire    [`RegAddrBus]   id_ex_reg1addr  ;
wire                    id_ex_reg1en    ;
wire    [`RegAddrBus]   id_ex_reg2addr  ;
wire                    id_ex_reg2en    ;
wire    [`LSBus]        id_ex_loadctl   ;
wire    [`LSBus]        id_ex_storectl  ;
wire    [`RegBus]       id_ex_storedata ;
wire                    id_ex_fromreg1  ;
wire                    id_ex_fromreg2  ;

// 连接 EX 与 EX/MEM
wire    [`RegAddrBus]   ex_rd           ;
wire                    ex_regwe        ;
wire    [`RegBus]       ex_result       ;
wire    [`LSBus]        ex_loadctl      ;
wire    [`LSBus]        ex_storectl     ;
wire    [`RegBus]       ex_storedata    ;

// 连接 EX/MEM 与 MEM
wire    [`RegAddrBus]   ex_mem_rd       ;
wire                    ex_mem_regwe    ;
wire    [`RegBus]       ex_mem_wbdata   ;
wire    [`LSBus]        ex_mem_loadctl  ;
wire    [`LSBus]        ex_mem_storectl ;
wire    [`RegBus]       ex_mem_storedata;

// 连接 MEM 与 MEM/WB
wire    [`RegAddrBus]   mem_rd          ;
wire                    mem_regwe       ;
wire    [`RegBus]       mem_wbdata      ;

// 连接 regfile
wire    [`RegAddrBus]   wb_rd           ;
wire                    wb_regwe        ;
wire    [`RegBus]       wb_wbdata       ;

wire                    id_reg1re       ;
wire                    id_reg2re       ;
wire    [`RegBus]       id_reg1data     ;
wire    [`RegBus]       id_reg2data     ;
wire    [`RegAddrBus]   id_reg1addr     ;
wire    [`RegAddrBus]   id_reg2addr     ;

pc pc0(
    .clk(clk), .rst(rst), .pc(pc_pc), .ce(pc_ce),
    // 流水线暂停
    .stallreq(pc_stallreq),
    // 分支
    .br(pc_br), .bt(pc_bt));
assign pc_stallreq = stall[0];
assign pc_br = id_br;
assign pc_bt = id_bt;

assign romen = pc_ce;
assign instaddr = pc_pc;

if_id if_id0(.clk(clk), .rst(rst), .pc(pc_pc), .inst(inst),
    .flushreq(if_id_flushreq), .stall(stall),
    .pc_o(if_id_pc), .inst_o(if_id_inst));
assign if_id_flushreq = id_br; // 如果需要跳转，则冲刷流水线

id id0(
    .rst(rst), .pc(if_id_pc), .inst(if_id_inst),
    // 来自 regfile 的输入
    .reg1data(id_reg1data), .reg2data(id_reg2data),
    // 用于数据前推的输入
    .id_ex_rd(id_ex_rd), .id_ex_regwe(id_ex_regwe),
    .ex_mem_rd(ex_mem_rd), .ex_mem_regwe(ex_mem_regwe), .ex_mem_wbdata(ex_mem_wbdata),
    // 送到 regfile 的输出
    .reg1re_o(id_reg1re), .reg2re_o(id_reg2re),
    .reg1addr_o(id_reg1addr), .reg2addr_o(id_reg2addr),
    // 送到 ID/EX
    .alusel_o(id_alusel), .s1data_o(id_s1data), .s2data_o(id_s2data),
    .rd_o(id_rd), .regwe_o(id_regwe),
    .stallreq_o(id_stallreq), .br_o(id_br), .bt_o(id_bt),
    // load, store 控制信号
    .loadctl_o(id_loadctl), .storectl_o(id_storectl), .storedata_o(id_storedata),
    // 是否来自寄存器
    .fromreg1(id_fromreg1), .fromreg2(id_fromreg2)
);

regfile regfile0(
    .clk(clk), .rst(rst),
    // 读 1
    .re1(id_reg1re), .raddr1(id_reg1addr), .rdata1(id_reg1data),
    // 读 2
    .re2(id_reg2re), .raddr2(id_reg2addr), .rdata2(id_reg2data),
    // 写
    .we(wb_regwe), .waddr(wb_rd), .wdata(wb_wbdata)
);

id_ex id_ex0(
    .clk(clk), .rst(rst),
    // 来自 ID 的输入
    .alusel(id_alusel), .s1data(id_s1data), .s2data(id_s2data), .rd(id_rd), .regwe(id_regwe),
    .loadctl(id_loadctl), .storectl(id_storectl), .storedata(id_storedata),
    .fromreg1(id_fromreg1), .fromreg2(id_fromreg2),
    // 流水线暂停控制
    .stall(stall),
    // 用于 EX 数据前推的输入
    .reg1addr(id_reg1addr), .reg1en(id_reg1re), .reg2addr(id_reg2addr), .reg2en(id_reg2re),
    // 送到 EX 的输出
    .alusel_o(id_ex_alusel), .s1data_o(id_ex_s1data), .s2data_o(id_ex_s2data), .rd_o(id_ex_rd), .regwe_o(id_ex_regwe),
    .reg1addr_o(id_ex_reg1addr), .reg1en_o(id_ex_reg1en),
    .reg2addr_o(id_ex_reg2addr), .reg2en_o(id_ex_reg2en),
    .loadctl_o(id_ex_loadctl), .storectl_o(id_ex_storectl), .storedata_o(id_ex_storedata),
    .fromreg1_o(id_ex_fromreg1), .fromreg2_o(id_ex_fromreg2)
);

ex ex0(
    .rst(rst),
    // 来自 ID/EX 的输入
    .alusel(id_ex_alusel), .s1data(id_ex_s1data), .s2data(id_ex_s2data), .rd(id_ex_rd), .regwe(id_ex_regwe),
    .reg1addr(id_ex_reg1addr), .reg1en(id_ex_reg1en),
    .reg2addr(id_ex_reg2addr), .reg2en(id_ex_reg2en),
    .loadctl(id_ex_loadctl), .storectl(id_ex_storectl), .storedata(id_ex_storedata),
    .fromreg1(id_ex_fromreg1), .fromreg2(id_ex_fromreg2),
    // 来自 EX/MEM 的输入
    .ex_mem_rd(ex_mem_rd), .ex_mem_regwe(ex_mem_regwe), .ex_mem_wbdata(ex_mem_wbdata),
    // 来自 MEM/WB 的输入
    .wb_rd(wb_rd), .wb_regwe(wb_regwe), .wb_wbdata(wb_wbdata),
    // 送到 EX/MEM 的输出
    .rd_o(ex_rd), .regwe_o(ex_regwe), .result(ex_result),
    .loadctl_o(ex_loadctl), .storectl_o(ex_storectl), .storedata_o(ex_storedata),
    // 流水线暂停控制
    .stallreq(ex_stallreq)
);

ex_mem ex_mem0(
    .clk(clk), .rst(rst),
    // 来自 EX 的输入
    .rd(ex_rd), .regwe(ex_regwe), .result(ex_result),
    .loadctl(ex_loadctl), .storectl(ex_storectl), .storedata(ex_storedata),
    // 流水线暂停控制
    .stall(stall),
    // 送到 MEM 的输出
    .rd_o(ex_mem_rd), .regwe_o(ex_mem_regwe), .result_o(ex_mem_wbdata),
    .loadctl_o(ex_mem_loadctl), .storectl_o(ex_mem_storectl), .storedata_o(ex_mem_storedata)
);

mem mem0(
    .rst(rst),
    // 来自 EX/MEM 的输入
    .rd(ex_mem_rd), .regwe(ex_mem_regwe), .result(ex_mem_wbdata),
    .loadctl(ex_mem_loadctl), .storectl(ex_mem_storectl), .storedata(ex_mem_storedata),
    // ram 输入
    .ramdata(ramdata),
    // 送到 MEM/WB 的输出
    .rd_o(mem_rd), .regwe_o(mem_regwe), .wbdata_o(mem_wbdata),
    // 送 ram 的输出
    .ramwe(ramwe), .ramwaddr(ramwaddr), .ramwdata(ramwdata),
    .ramre(ramre),. ramraddr(ramraddr)
);

mem_wb mem_wb0(
    .clk(clk), .rst(rst),
    // 来自 MEM 的输入
    .rd(mem_rd), .regwe(mem_regwe), .wbdata(mem_wbdata),
    // 流水线暂停控制
    .stall(stall),
    // 送到写回阶段的信息
    .rd_o(wb_rd), .regwe_o(wb_regwe), .wbdata_o(wb_wbdata)
);

stall_ctl stall_ctl0(.rst(rst), .id_stallreq(id_stallreq), .ex_stallreq(ex_stallreq), .stall(stall));

endmodule