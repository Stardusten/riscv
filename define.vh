`define     Enabled     1'b1
`define     Disabled    1'b0
`define     Zero        32'b0
`define     InstAddrBus 31:0        // ROM 地址总线宽度
`define     InstBus     31:0        // ROM 数据总线宽度
`define     RegAddrBus  4:0         // Regfile 地址总线宽度（用几位编码寄存器号，32 个寄存器，5 位编码）
`define     RegBus      31:0        // Regfile 数据总线宽度
`define     RegNum      32
`define     AluSelBus   3:0
`define     NopRegAddr  5'b00000
`define     RomMemSize  7:0           // ROM 按字节寻址
`define     RomMemNum   128
`define     RomFile     "C:\\Users\\xx\\Desktop\\arch\\riscv\\rom.txt"

`define     True        1'b1
`define     False       1'b0

// 各种指令的 Opcode
`define		BOpcode			7'b1100011
`define		SOpcode			7'b0100011
`define		IOpcode1		7'b0010011 // 算数指令
`define     IOpcode2        7'b0000011 // load 指令
`define     IOpcode3        7'b1100111 // jalr
`define     IOpcode4        7'b1110011 // ecall, ebreak
`define		ROpcode			7'b0110011
`define     UOpcode1        7'b0110111 // lui
`define     UOpcode2        7'b0010111 // auipc
`define     JOpcode         7'b1101111 // jal

// 支持的五个 ALU 操作
`define     AluNop          4'b0000 // 空操作
`define     AluAdd          4'b0001 // 加
`define     AluSub          4'b0010 // 减
`define     AluSll           4'b0011 // 左移
`define     AluSrl          4'b0100 // 逻辑右移
`define     AluSra          4'b0101 // 算术右移
`define     AluXor          4'b0110 // 异或
`define     AluOr           4'b0111 // 或
`define     AluAnd          4'b1000 // 与
`define     AluUlt          4'b1001 // 无符号小于
`define     AluSlt          4'b1010 // 有符号小于