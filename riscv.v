`include "define.vh"

module riscv(
    input   wire                        rst         , // 复位
    input   wire                        clk         , // 时钟
    input   wire    [`RegBus]           inst        , // 要执行的指令
    output  wire    [`RegBus]           instaddr    , // 下一条指令地址
    output  wire                        romen        // rom 使能
);

// 连接 PC 与 IF/ID
wire    [`InstAddrBus]  pc_pc           ;
wire                    pc_ce           ;

// 连接 IF/ID 与 ID
wire    [`InstAddrBus]  if_id_pc        ;
wire    [`InstBus]      if_id_inst      ;

// 连接 ID 与 ID/EX
wire    [`AluSelBus]    id_alusel       ;
wire    [`RegBus]       id_s1data       ;
wire    [`RegBus]       id_s2data       ;
wire    [`RegAddrBus]   id_rd           ;
wire                    id_regwe        ;

// 连接 ID/EX 与 EX
wire    [`AluSelBus]    id_ex_alusel    ;
wire    [`RegBus]       id_ex_s1data    ;
wire    [`RegBus]       id_ex_s2data    ;
wire    [`RegAddrBus]   id_ex_rd        ;
wire                    id_ex_regwe     ;

// 连接 EX 与 EX/MEM
wire    [`RegAddrBus]   ex_rd           ;
wire                    ex_regwe        ;
wire    [`RegBus]       ex_result       ;

// 连接 EX/MEM 与 MEM
wire    [`RegAddrBus]   ex_mem_rd       ;
wire                    ex_mem_regwe    ;
wire    [`RegBus]       ex_mem_wbdata   ;

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

pc pc0(.clk(clk), .rst(rst), .pc(pc_pc), .ce(pc_ce));
assign romen = pc_ce;
assign instaddr = pc_pc;

if_id if_id0(.clk(clk), .rst(rst), .pc(pc_pc), .inst(inst), .pc_o(if_id_pc), .inst_o(if_id_inst));

id id0(
    .rst(rst), .pc(if_id_pc), .inst(if_id_inst),
    // 来自 regfile 的输入
    .reg1data(id_reg1data), .reg2data(id_reg2data),
    // 送到 regfile 的输出
    .reg1re(id_reg1re), .reg2re(id_reg2re),
    .reg1addr(id_reg1addr), .reg2addr(id_reg2addr),
    // 送到 ID/EX
    .alusel(id_alusel), .s1data(id_s1data),
    .s2data(id_s2data), .rd(id_rd), .regwe(id_regwe)
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
    // 送到 EX 的输出
    .alusel_o(id_ex_alusel), .s1data_o(id_ex_s1data), .s2data_o(id_ex_s2data), .rd_o(id_ex_rd), .regwe_o(id_ex_regwe)
);

ex ex0(
    .rst(rst),
    // 来自 ID/EX 的输入
    .alusel(id_ex_alusel), .s1data(id_ex_s1data), .s2data(id_ex_s2data), .rd(id_ex_rd), .regwe(id_ex_regwe),
    // 送到 EX/MEM 的输出
    .rd_o(ex_rd), .regwe_o(ex_regwe), .result(ex_result)
);

ex_mem ex_mem0(
    .clk(clk), .rst(rst),
    // 来自 EX 的输入
    .rd(ex_rd), .regwe(ex_regwe), .result(ex_result),
    // 送到 MEM 的输出
    .rd_o(ex_mem_rd), .regwe_o(ex_mem_regwe), .wbdata(ex_mem_wbdata)
);

mem mem0(
    .rst(rst),
    // 来自 EX/MEM 的输入
    .rd(ex_mem_rd), .regwe(ex_mem_regwe), .wbdata(ex_mem_wbdata),
    // 送到 MEM/WB 的输出
    .rd_o(mem_rd), .regwe_o(mem_regwe), .wbdata_o(mem_wbdata)
);

mem_wb mem_wb0(
    .clk(clk), .rst(rst),
    // 来自 MEM 的输入
    .rd(mem_rd), .regwe(mem_regwe), .wbdata(mem_wbdata),
    // 送到写回阶段的信息
    .rd_o(wb_rd), .regwe_o(wb_regwe), .wbdata_o(wb_wbdata)
);

endmodule