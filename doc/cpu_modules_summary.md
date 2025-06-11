# RISC-V CPU 设计模块汇总

本文档汇总了RISC-V CPU设计中的所有模块，包括各个流水线阶段、控制单元和支持模块。

## 目录
1. [顶层模块](#顶层模块)
2. [流水线阶段模块](#流水线阶段模块)
3. [流水线寄存器模块](#流水线寄存器模块)
4. [功能单元模块](#功能单元模块)
5. [控制单元和辅助模块](#控制单元和辅助模块)
6. [存储器模块](#存储器模块)

## 顶层模块
### cpu_top
CPU的顶层模块，连接所有子模块并处理它们之间的交互。
```verilog
module cpu_top (
    input wire clk,
    input wire rst_n
);
```
主要功能：
- 实例化并连接所有CPU子模块
- 处理流水线各阶段间的数据传递
- 协调流水线冒险处理

## 流水线阶段模块
### if_stage (取指阶段)
从指令存储器获取指令。
```verilog
module if_stage (
    input  wire [31:0] pc_i,
    input  wire [31:0] pc_plus_4_i,
    
    output wire [31:0] instr_addr_o,
    input  wire [31:0] instruction_i,
    
    output wire [31:0] pc_if_id_o,
    output wire [31:0] pc_plus_4_if_id_o,
    output wire [31:0] instruction_if_id_o
);
```

### id_stage (指令解码阶段)
解码指令并生成控制信号。
```verilog
module id_stage (
    input  wire [31:0] pc_i,
    input  wire [31:0] pc_plus_4_i,
    input  wire [31:0] instruction_i,

    output wire [4:0]  rs1_addr_rf_o,
    output wire [4:0]  rs2_addr_rf_o,
    input  wire [31:0] rs1_data_i,
    input  wire [31:0] rs2_data_i,
    
    // 输出到ID/EX寄存器
    output wire [31:0] pc_ex_o,
    output wire [31:0] pc_plus_4_ex_o,
    output wire [31:0] operand_a_ex_o,
    output wire [31:0] operand_b_ex_o,
    output wire [31:0] reg2_data_ex_o,
    output wire [4:0]  rs1_addr_ex_o,
    output wire [4:0]  rs2_addr_ex_o,
    output wire [4:0]  rd_addr_ex_o,
    output wire [2:0]  funct3_ex_o,
    output wire [6:0]  funct7_ex_o,
    output wire [6:0]  opcode_ex_o,
    output wire [31:0] immediate_ex_o,

    // 控制信号
    output wire [1:0]  mem_to_reg_ex_o,
    output wire        reg_write_ex_o,
    output wire        branch_ex_o,
    output wire        mem_write_ex_o,
    output wire        mem_read_ex_o,
    output wire        alu_src_ex_o,
    output wire [3:0]  alu_op_ex_o
);
```

### ex_stage (执行阶段)
执行ALU操作和地址计算。
```verilog
module ex_stage (
    // 来自ID/EX寄存器的输入
    input  wire [31:0] pc_ex_i,
    input  wire [31:0] pc_plus_4_ex_i,
    input  wire [31:0] operand_a_ex_i,
    input  wire [31:0] operand_b_src_ex_i,
    input  wire [31:0] immediate_ex_i,
    input  wire [4:0]  rd_addr_ex_i,
    input  wire [2:0]  funct3_ex_i,
    input  wire [6:0]  funct7_ex_i,
    input  wire [6:0]  opcode_ex_i,
    // 控制信号
    input  wire [3:0]  alu_op_ex_i,
    input  wire        alu_src_ex_i,
    input  wire        mem_read_ex_i,
    input  wire        mem_write_ex_i,
    input  wire        branch_ctrl_ex_i,
    input  wire        reg_write_ex_i,

    // 输出到EX/MEM寄存器
    output wire [31:0] pc_for_mem_o,
    output wire [31:0] pc_plus_4_mem_o,
    output wire [31:0] ex_result_mem_o,
    output wire        zero_flag_mem_o,
    output wire [31:0] reg2_data_mem_o,
    output wire [31:0] immediate_mem_o,
    output wire [4:0]  rd_addr_mem_o,
    output wire [2:0]  funct3_mem_o,
    output wire [6:0]  opcode_mem_o,
    // 控制信号输出
    output wire        mem_read_mem_o,
    output wire        mem_write_mem_o,
    output wire        branch_ctrl_mem_o,
    output wire        reg_write_mem_o
);
```

### mem_stage (内存访问阶段)
处理内存访问和分支决策。
```verilog
module mem_stage (
    // 来自EX/MEM寄存器的输入
    input  wire [31:0] pc_ex_mem_i,
    input  wire [31:0] pc_plus_4_mem_i,
    input  wire [31:0] ex_result_mem_i,
    input  wire        zero_flag_mem_i,
    input  wire [31:0] reg2_data_mem_i,
    input  wire [31:0] immediate_ex_mem_i,
    input  wire [4:0]  rd_addr_mem_i,
    input  wire [2:0]  funct3_mem_i,
    input  wire [6:0]  opcode_ex_mem_i,
    // 控制信号
    input  wire        mem_read_mem_i,
    input  wire        mem_write_mem_i,
    input  wire        branch_ctrl_mem_i,
    input  wire        reg_write_mem_i,
    input  wire [1:0]  mem_to_reg_mem_i,

    // 数据存储器接口
    input  wire [31:0] data_mem_read_data_i,

    // 输出到MEM/WB寄存器
    output wire [1:0]  mem_to_reg_wb_o,

    // 输出到PC逻辑/冒险单元
    output wire        branch_jump_request_o,
    output wire [1:0]  pc_sel_decision_o,
    output wire [31:0] branch_jump_target_addr_o,
    output wire [31:0] jalr_target_addr_o
);
```

### wb_stage (写回阶段)
将结果写回寄存器堆。
```verilog
module wb_stage (
    // 来自MEM/WB寄存器的输入
    input  wire [31:0] pc_plus_4_wb_i,
    input  wire [31:0] mem_read_data_wb_i,
    input  wire [31:0] ex_result_wb_i,
    input  wire [4:0]  rd_addr_wb_i,
    // 控制信号
    input  wire        reg_write_wb_i,
    input  wire [1:0]  mem_to_reg_wb_i,
    
    // 输出到寄存器文件
    output wire        reg_write_o,
    output wire [4:0]  rd_addr_o,
    output wire [31:0] write_data_o
);
```

## 流水线寄存器模块
### if_id_register
存储IF和ID阶段之间的数据。
```verilog
module if_id_register (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall_i,
    input  wire        flush_i,

    input  wire [31:0] pc_if_i,
    input  wire [31:0] pc_plus_4_if_i,
    input  wire [31:0] instruction_if_i,

    output reg  [31:0] pc_id_o,
    output reg  [31:0] pc_plus_4_id_o,
    output reg  [31:0] instruction_id_o
);
```

### id_ex_register
存储ID和EX阶段之间的数据。
```verilog
module id_ex_register (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall_i,
    input  wire        flush_i,

    // 来自ID阶段的输入
    input  wire [31:0] pc_id_i,
    input  wire [31:0] pc_plus_4_id_i,
    input  wire [31:0] operand_a_id_i,
    input  wire [31:0] operand_b_id_i,
    input  wire [31:0] reg2_data_id_i,
    input  wire [31:0] immediate_id_i,
    input  wire [4:0]  rs1_addr_id_i,
    input  wire [4:0]  rs2_addr_id_i,
    input  wire [4:0]  rd_addr_id_i,
    input  wire [2:0]  funct3_id_i,
    input  wire [6:0]  funct7_id_i,
    input  wire [6:0]  opcode_id_i,
    // 控制信号
    input  wire [3:0]  alu_op_id_i,
    input  wire        alu_src_id_i,
    input  wire        mem_read_id_i,
    input  wire        mem_write_id_i,
    input  wire        branch_id_i,
    input  wire        reg_write_id_i,
    input  wire [1:0]  mem_to_reg_id_i,

    // 输出到EX阶段
    output reg  [31:0] pc_ex_o,
    output reg  [31:0] pc_plus_4_ex_o,
    output reg  [31:0] operand_a_ex_o,
    output reg  [31:0] operand_b_ex_o,
    output reg  [31:0] reg2_data_ex_o,
    output reg  [31:0] immediate_ex_o,
    output reg  [4:0]  rs1_addr_ex_o,
    output reg  [4:0]  rs2_addr_ex_o,
    output reg  [4:0]  rd_addr_ex_o,
    output reg  [2:0]  funct3_ex_o,
    output reg  [6:0]  funct7_ex_o,
    output reg  [6:0]  opcode_ex_o,
    // 控制信号
    output reg  [3:0]  alu_op_ex_o,
    output reg         alu_src_ex_o,
    output reg         mem_read_ex_o,
    output reg         mem_write_ex_o,
    output reg         branch_ex_o,
    output reg         reg_write_ex_o,
    output reg  [1:0]  mem_to_reg_ex_o
);
```

### ex_mem_register
存储EX和MEM阶段之间的数据。
```verilog
module ex_mem_register (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall_i,
    input  wire        flush_i,

    // 来自EX阶段的输入
    input  wire [31:0] pc_ex_i,
    input  wire [31:0] pc_plus_4_ex_i,
    input  wire [31:0] ex_result_ex_i,
    input  wire        zero_flag_ex_i,
    input  wire [31:0] reg2_data_ex_i,
    input  wire [31:0] immediate_ex_i,
    input  wire [4:0]  rd_addr_ex_i,
    input  wire [2:0]  funct3_ex_i,
    input  wire [6:0]  opcode_ex_i,
    // 控制信号
    input  wire        mem_read_ex_i,
    input  wire        mem_write_ex_i,
    input  wire        branch_ctrl_ex_i,
    input  wire        reg_write_ex_i,
    input  wire [1:0]  mem_to_reg_ex_i,

    // 输出到MEM阶段
    output reg  [31:0] pc_ex_mem_o,
    output reg  [31:0] pc_plus_4_mem_o,
    output reg  [31:0] ex_result_mem_o,
    output reg         zero_flag_mem_o,
    output reg  [31:0] reg2_data_mem_o,
    output reg  [31:0] immediate_ex_mem_o,
    output reg  [4:0]  rd_addr_mem_o,
    output reg  [2:0]  funct3_mem_o,
    output reg  [6:0]  opcode_ex_mem_o,
    // 控制信号
    output reg         mem_read_mem_o,
    output reg         mem_write_mem_o,
    output reg         branch_ctrl_mem_o,
    output reg         reg_write_mem_o,
    output reg  [1:0]  mem_to_reg_mem_o
);
```

### mem_wb_register
存储MEM和WB阶段之间的数据。
```verilog
module mem_wb_register (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall_i,
    input  wire        flush_i,

    // 来自MEM阶段的输入
    input  wire [31:0] pc_plus_4_mem_i,
    input  wire [31:0] mem_read_data_mem_i,
    input  wire [31:0] ex_result_mem_i,
    input  wire [4:0]  rd_addr_mem_i,
    // 控制信号
    input  wire        reg_write_mem_i,
    input  wire [1:0]  mem_to_reg_mem_i,

    // 输出到WB阶段
    output reg  [31:0] pc_plus_4_wb_o,
    output reg  [31:0] mem_read_data_wb_o,
    output reg  [31:0] ex_result_wb_o,
    output reg  [4:0]  rd_addr_wb_o,
    // 控制信号
    output reg         reg_write_wb_o,
    output reg  [1:0]  mem_to_reg_wb_o
);
```

## 功能单元模块
### alu
算术逻辑单元，执行各种计算操作。
```verilog
module alu (
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire [3:0]  alu_control,

    output reg  [31:0] alu_result,
    output wire        zero_flag
);
```

### multiplier
乘法器，支持多种乘法操作。
```verilog
module multiplier (
    input  wire [31:0] multiplicand_i,
    input  wire [31:0] multiplier_i,
    input  wire [1:0]  multiply_op_i,
    
    output reg  [31:0] product_o
);
```

### register_file
寄存器堆，存储CPU的通用寄存器。
```verilog
module register_file (
    input  wire        clk,
    input  wire        rst_n,
    
    input  wire [4:0]  rs1_addr_i,
    input  wire [4:0]  rs2_addr_i,
    output wire [31:0] rs1_data_o,
    output wire [31:0] rs2_data_o,
    
    input  wire        reg_write_i,
    input  wire [4:0]  rd_addr_i,
    input  wire [31:0] write_data_i
);
```

## 控制单元和辅助模块
### control_unit
生成控制信号的控制单元。
```verilog
module control_unit (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    
    output reg [3:0] ALUOp,
    output reg       ALUSrc,
    output reg       MemRead,
    output reg       MemWrite,
    output reg       Branch,
    output reg       RegWrite,
    output reg [1:0] MemToReg
);
```

### immediate_generator
生成各种指令格式的立即数。
```verilog
module immediate_generator (
    input  wire [31:0] instruction_i,
    output reg  [31:0] immediate_o
);
```

### hazard_unit
处理数据冒险、控制冒险和结构冒险。
```verilog
module hazard_unit (
    input  wire [4:0]  id_rs1_addr_i,
    input  wire [4:0]  id_rs2_addr_i,
    input  wire        id_mem_read_i,
    
    input  wire [4:0]  ex_rd_addr_i,
    input  wire        ex_reg_write_i,
    input  wire        ex_mem_read_i,
    
    input  wire [4:0]  mem_rd_addr_i,
    input  wire        mem_reg_write_i,
    input  wire        branch_jump_request_mem_i,
    input  wire [1:0]  pc_sel_decision_mem_i,
    
    output reg         pc_stall_o,
    output reg         if_id_stall_o,
    output reg         if_id_flush_o,
    output reg         id_ex_stall_o,
    output reg         id_ex_flush_o,
    output reg  [1:0]  forward_a_select_o,
    output reg  [1:0]  forward_b_select_o,
    output wire [1:0]  pc_sel_final_o
);
```

### pc_logic
处理程序计数器(PC)的更新和跳转。
```verilog
module pc_logic (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall_if_i,
    input  wire        flush_if_i,
    input  wire [1:0]  pc_sel_i,
    input  wire [31:0] branch_jump_target_addr_i,
    input  wire [31:0] jalr_target_addr_i,
    
    output reg  [31:0] pc_if_o,
    output wire [31:0] pc_plus_4_if_o
);
```

## 存储器模块
### data_memory
数据存储器，存储CPU操作的数据。
```verilog
module data_memory (
    input  wire        clk,
    input  wire        rst_n,
    
    input  wire [31:0] addr_i,
    input  wire [31:0] write_data_i,
    input  wire        read_en_i,
    input  wire        write_en_i,
    input  wire [2:0]  funct3_i,
    
    output reg  [31:0] read_data_o
);
```

### instruction_memory
指令存储器，存储程序指令。
```verilog
module instruction_memory (
    input  wire [31:0] addr_i,
    output reg  [31:0] instr_o
);
```
