`include "define.vh"

module rom(
    input   wire                                    ce      , // 使能
    input   wire    [`InstAddrBus]                  addr    , // 指令地址
    output  reg     [`InstBus]                      inst      // 指令
);

reg [`RomMemSize]  MEM[0:`RomMemNum - 1];

initial begin
    $readmemh(`RomFile, MEM); // 从 `RomFile 文件初始化 ROM
end

always @(*) begin
    if (ce == `Disabled) begin
        inst    <=  `Zero;
    end else begin
        // 按字节寻址，小端序 TODO 文件是大端序输入，懒得改了
        inst    <=  { MEM[addr], MEM[addr + 1], MEM[addr + 2], MEM[addr + 3] };
    end
end

endmodule