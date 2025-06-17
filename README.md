# RISC-V RV32IM 处理器核心设计与验证

## 项目概述

本项目旨在设计和实现一个支持 RV32I 基本整数指令集和 M 扩展（乘法指令）的 RISC-V 处理器核心。该处理器采用经典的五级流水线结构（IF, ID, EX, MEM, WB），并包含了数据前推和冒险处理机制以提高性能。

项目的主要目标是：
1.  实现一个功能正确的 RV32IM 处理器。
2.  通过 Verilog HDL 进行硬件描述。
3.  使用 Verilog Testbench 和仿真工具（如 VCS）进行功能验证。
4.  逐步调试和完善设计，确保其能够正确执行给定的测试用例。

## 文件结构

```
/home/jiangchuanc/Desktop/Design_CPU/
├── rtl/                      # RTL Verilog 源代码
│   ├── cpu_top.v             # CPU顶层模块
│   ├── pc_logic.v            # PC逻辑单元
│   ├── instruction_memory.v  # 指令存储器
│   ├── if_stage.v            # 取指阶段
│   ├── if_id_register.v      # IF/ID 流水线寄存器
│   ├── id_stage.v            # 译码阶段
│   ├── register_file.v       # 寄存器堆
│   ├── immediate_generator.v # 立即数生成器
│   ├── control_unit.v        # 控制单元
│   ├── id_ex_register.v      # ID/EX 流水线寄存器
│   ├── ex_stage.v            # 执行阶段
│   ├── alu.v                 # 算术逻辑单元 (ALU)
│   ├── multiplier.v          # 乘法器 (M扩展)
│   ├── ex_alu_mul_mux.v      # EX阶段ALU和乘法器结果选择MUX
│   ├── ex_mem_register.v     # EX/MEM 流水线寄存器
│   ├── data_memory.v         # 数据存储器
│   ├── mem_stage.v           # 访存阶段
│   ├── mem_wb_register.v     # MEM/WB 流水线寄存器
│   ├── wb_stage.v            # 写回阶段
│   ├── hazard_unit.v         # 冒险处理单元
│   └── defines.v             # 全局宏定义
├── testbench/                # 测试平台相关文件
│   └── cpu_riscv_tb.v        # CPU Testbench
└── test/                     # 测试用例目录
    └── riscv_case/
        └── riscv.hex         # 包含指令的HEX文件 (由测试平台加载)
```

## 处理器特性

*   **指令集**: RV32I (基本整数指令集) + M 扩展 (乘法指令)。
*   **流水线**: 五级流水线 (IF, ID, EX, MEM, WB)。
*   **冒险处理**:
    *   **数据冒险**: 通过数据前推（Forwarding）解决大部分数据冒险。对于 Load-Use 冒险，采用流水线暂停（Stall）。
    *   **控制冒险**: 分支指令在 MEM 阶段解析，如果发生跳转，则冲刷（Flush）IF 和 ID 阶段的指令。
*   **存储器**:
    *   独立的指令存储器和数据存储器。
    *   指令存储器在仿真开始时从 `test/riscv_case/riscv.hex` 文件加载指令。
    *   数据存储器支持字节、半字和字访问。

## 如何运行测试

1.  **环境准备**:
    *   确保已安装 Synopsys VCS 仿真器或兼容的 Verilog 仿真工具。
    *   确保 `defines.v` 文件中的路径和宏定义正确。
2.  **编译与仿真**:
    *   通常使用 VCS 命令行进行编译和仿真。一个典型的命令可能如下：
        ```bash
        vcs -full64 -R -sverilog +v2k \
            rtl/*.v testbench/cpu_riscv_tb.v \
            +define+FSDB_ON \ # (可选，如果testbench支持通过宏开启FSDB)
            -l compile.log
        ```
    *   或者使用提供的 Makefile (如果存在)。
3.  **查看结果**:
    *   仿真日志会输出到控制台，并可能记录到文件中（如 `sim.log`）。
    *   Testbench 会报告测试的通过/失败状态，包括寄存器值的对比。
    *   如果生成了波形文件 (如 `cpu_riscv_test.fsdb` 或 `cpu_riscv_test.vcd`)，可以使用 Verdi 或 GTKWave 等工具查看详细的信号波形以进行调试。

## 当前调试状态与已知问题 (截至最新日志)

*   **整体功能**: 根据最新的仿真日志，CPU 能够成功执行提供的 `riscv.hex` 测试用例中的所有 232 条指令，并且最终所有 32 个通用寄存器的值与标准答案完全匹配。
*   **Testbench 报告**:
    *   `test_stage` 报告不准确的问题已通过将非阻塞赋值改为阻塞赋值解决，现在能正确报告 `5/5`。
    *   `unique_pc_count` 的报告已调整，在测试完成时会显示目标值。
    *   分支覆盖率已在 `test_summary` 中报告。
*   **`id_stage` 内部调试信息**:
    *   日志中曾出现 `[ID] PC=0x00000210, instruction=0x14029463, opcode=0x63, rd=x 8` 的打印，其中指令 `0x14029463` (XOR) 的操作码被错误地显示为 `0x63` (BRANCH) 而不是正确的 `0x33` (ARITH)。
    *   然而，CPU 的整体行为和 `cpu_top.v` 中针对此情况的调试打印并未触发，表明 `id_stage` 实际输出给后续流水线的操作码是正确的。
    *   **推测**: `id_stage.v` 模块内部用于产生上述 `[ID]` 日志的 `$display` 语句可能引用了错误的内部变量来显示操作码。**建议检查并修正 `id_stage.v` 中的这条调试打印逻辑**，以避免未来调试时的混淆。
*   **冒险处理与前推**:
    *   数据前推机制和 Load-Use 冒险暂停机制已实现。
    *   分支预测采用“分支不发生”策略，分支在 MEM 阶段解析，若跳转则冲刷流水线。
*   **乘法指令**:
    *   M 扩展指令（MUL, MULH, MULHSU, MULHU）已在控制单元和 ALU/乘法器路径中处理。
    *   `ex_alu_mul_mux.v` 模块负责根据操作码选择 ALU 结果或乘法器结果。

## 后续工作与改进方向

1.  **完善 `id_stage.v` 调试信息**: 修正内部操作码打印问题。
2.  **更全面的 Testbench**:
    *   增加更多针对性的测试用例，覆盖所有指令类型、数据冒险、控制冒险的各种组合。
    *   考虑引入随机指令序列生成和自校验的 Testbench。
    *   实现更详细的覆盖率收集（指令覆盖、功能覆盖等）。
3.  **异常处理**: 当前设计未包含完整的异常处理机制（如非法指令、访存错误等）。
4.  **中断处理**: 添加中断控制器和中断响应逻辑。
5.  **性能优化**:
    *   考虑更高级的分支预测方案。
    *   分析流水线瓶颈，进行可能的微架构调整。
6.  **综合与后端**: 如果目标是 FPGA 或 ASIC 实现，需要进行逻辑综合、时序分析和布局布线。

## 贡献者

*   jiangchuanc 

---

希望这个 README 对您有所帮助！
