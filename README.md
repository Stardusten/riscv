![riscv](https://user-images.githubusercontent.com/38722307/209060148-d9966a4d-620e-4a79-b0bc-6ff4da353405.png)

## Roadmap

已完成:

- 实现了 ori 指令
- 实现了所有 I-type 和 R-type 的算术、逻辑、比较和移位指令
- 使用数据前推，解决了所有真相关（不考虑 Load、Store）
- 实现了所有分支指令，包括 B-type，jal 和 jalr
- 解决了所有控制相关，如果不能用数据前推获得要比较的两个数，则停止流水线
- 实现了所有 Load，Store 指令
- 解决所有由 Load，Store 带来的相关问题
- 使用静态分支预测代替流水线停滞

未完成:

- 实现控制状态寄存器指令
- 实现 ecall 指令，ebreak 指令
- 实现 fence 指令
- 使用两位动态分支预测代替静态分支预测
- 完成异常处理
