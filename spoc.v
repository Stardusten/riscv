`include "define.vh"

module spoc(
    input   wire        clk         ,
    input   wire        rst         
);

wire                    romen       ;
wire    [`InstAddrBus]  instaddr    ;
wire    [`InstBus]      inst        ;

wire                    ramwe       ;
wire    [`DataAddrBus]  ramwaddr    ;
wire    [`DataBus]      ramwdata    ;
wire                    ramre       ;
wire    [`DataAddrBus]  ramraddr    ;
wire    [`DataBus]      ramdata     ;

riscv riscv0(
    .clk(clk), .rst(rst),
    .inst(inst), .ramdata(ramdata),
    .instaddr(instaddr), .romen(romen),
    .ramwe(ramwe), .ramwaddr(ramwaddr), .ramwdata(ramwdata), .ramre(ramre), .ramraddr(ramraddr)
);

rom rom0(.ce(romen), .addr(instaddr), .inst(inst));

ram ram0(
    .clk(clk),
    .we(ramwe), .waddr(ramwaddr), .wdata(ramwdata),
    .re(ramre), .raddr(ramraddr),
    .data_o(ramdata));

endmodule