`include "define.vh"

module spoc(
    input   wire        clk         ,
    input   wire        rst         
);

wire                    romen       ;
wire    [`InstAddrBus]  instaddr    ;
wire    [`InstBus]      inst        ;

riscv riscv0(
    .clk(clk), .rst(rst),
    .inst(inst), .instaddr(instaddr), .romen(romen)
);

rom rom(.ce(romen), .addr(instaddr), .inst(inst));

endmodule