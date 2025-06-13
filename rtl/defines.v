`timescale 1ns/1ps

// RISC-V CPU 常量定义文件
`ifndef DEFINES_V
`define DEFINES_V

//=================================================
// 指令操作码定义 (RISC-V RV32I)
//=================================================
`define OPCODE_LUI      7'b0110111  // Load Upper Immediate
`define OPCODE_AUIPC    7'b0010111  // Add Upper Immediate to PC
`define OPCODE_JAL      7'b1101111  // Jump and Link
`define OPCODE_JALR     7'b1100111  // Jump and Link Register
`define OPCODE_BRANCH   7'b1100011  // Branch Instructions
`define OPCODE_LOAD     7'b0000011  // Load Instructions
`define OPCODE_STORE    7'b0100011  // Store Instructions
`define OPCODE_IMM      7'b0010011  // Immediate Arithmetic
`define OPCODE_ARITH    7'b0110011  // Register-Register Arithmetic

//=================================================
// 功能码定义 (funct3)
//=================================================

// 分支指令功能码
`define FUNCT3_BEQ      3'b000      // Branch Equal
`define FUNCT3_BNE      3'b001      // Branch Not Equal
`define FUNCT3_BLT      3'b100      // Branch Less Than
`define FUNCT3_BGE      3'b101      // Branch Greater Equal
`define FUNCT3_BLTU     3'b110      // Branch Less Than Unsigned
`define FUNCT3_BGEU     3'b111      // Branch Greater Equal Unsigned

// Load指令功能码
`define FUNCT3_LB       3'b000      // Load Byte
`define FUNCT3_LH       3'b001      // Load Halfword
`define FUNCT3_LW       3'b010      // Load Word
`define FUNCT3_LBU      3'b100      // Load Byte Unsigned
`define FUNCT3_LHU      3'b101      // Load Halfword Unsigned

// Store指令功能码
`define FUNCT3_SB       3'b000      // Store Byte
`define FUNCT3_SH       3'b001      // Store Halfword
`define FUNCT3_SW       3'b010      // Store Word

// 立即数算术指令功能码
`define FUNCT3_ADDI     3'b000      // Add Immediate
`define FUNCT3_SLTI     3'b010      // Set Less Than Immediate
`define FUNCT3_SLTIU    3'b011      // Set Less Than Immediate Unsigned
`define FUNCT3_XORI     3'b100      // XOR Immediate
`define FUNCT3_ORI      3'b110      // OR Immediate
`define FUNCT3_ANDI     3'b111      // AND Immediate
`define FUNCT3_SLLI     3'b001      // Shift Left Logical Immediate
`define FUNCT3_SRLI     3'b101      // Shift Right Logical Immediate
`define FUNCT3_SRAI     3'b101      // Shift Right Arithmetic Immediate

// 寄存器算术指令功能码
`define FUNCT3_ADD      3'b000      // Add/Subtract
`define FUNCT3_SLL      3'b001      // Shift Left Logical
`define FUNCT3_SLT      3'b010      // Set Less Than
`define FUNCT3_SLTU     3'b011      // Set Less Than Unsigned
`define FUNCT3_XOR      3'b100      // XOR
`define FUNCT3_SRL      3'b101      // Shift Right Logical/Arithmetic
`define FUNCT3_OR       3'b110      // OR
`define FUNCT3_AND      3'b111      // AND

// 乘法指令功能码 (RV32M)
`define FUNCT3_MUL      3'b000      // Multiply
`define FUNCT3_MULH     3'b001      // Multiply High
`define FUNCT3_MULHSU   3'b010      // Multiply High Signed-Unsigned
`define FUNCT3_MULHU    3'b011      // Multiply High Unsigned

//=================================================
// 功能码定义 (funct7)
//=================================================
`define FUNCT7_ADD      7'b0000000  // ADD
`define FUNCT7_SUB      7'b0100000  // SUB
`define FUNCT7_SRL      7'b0000000  // SRL
`define FUNCT7_SRA      7'b0100000  // SRA
`define FUNCT7_MUL      7'b0000001  // Multiplication extension

//=================================================
// ALU控制信号定义
//=================================================
`define ALU_ADD         4'b0000     // 加法
`define ALU_SUB         4'b0001     // 减法 - 确保SUB操作码
`define ALU_AND         4'b0010     // 按位与
`define ALU_OR          4'b0011     // 按位或
`define ALU_XOR         4'b0100     // 按位异或
`define ALU_SLL         4'b0101     // 逻辑左移
`define ALU_SRL         4'b0110     // 逻辑右移
`define ALU_SRA         4'b0111     // 算术右移
`define ALU_SLT         4'b1000     // 有符号比较
`define ALU_SLTU        4'b1001     // 无符号比较
`define ALU_MUL         4'b1100     // 乘法
`define ALU_MULH        4'b1101     // 高位乘法
`define ALU_MULHSU      4'b1110     // 有符号无符号高位乘法
`define ALU_MULHU       4'b1111     // 无符号高位乘法

//=================================================
// 乘法器操作信号定义
//=================================================
`define MUL_OP_MUL      2'b00       // MUL - 低32位
`define MUL_OP_MULH     2'b01       // MULH - 高32位有符号
`define MUL_OP_MULHSU   2'b10       // MULHSU - 高32位有符号*无符号
`define MUL_OP_MULHU    2'b11       // MULHU - 高32位无符号

//=================================================
// PC选择信号定义
//=================================================
`define PC_SEL_PC_PLUS_4      2'b00    // PC+4
`define PC_SEL_BRANCH_JUMP    2'b01    // 分支/跳转目标
`define PC_SEL_JALR           2'b10    // JALR目标
`define PC_SEL_EXCEPTION      2'b11    // 异常处理（保留）

//=================================================
// MemToReg选择信号定义
//=================================================
`define MEM_TO_REG_ALU      2'b00   // ALU结果写回
`define MEM_TO_REG_MEM      2'b01   // 内存数据写回
`define MEM_TO_REG_PC4      2'b10   // PC+4写回(JAL/JALR)

//=================================================
// 前推选择信号定义
//=================================================
`define FORWARD_NO          2'b00   // 不前推
`define FORWARD_EX_MEM      2'b01   // 从EX/MEM前推
`define FORWARD_MEM_WB      2'b10   // 从MEM/WB前推

//=================================================
// 寄存器地址定义
//=================================================
`define REG_ZERO        5'b00000    // x0 寄存器(硬编码为0)
`define REG_RA          5'b00001    // x1 返回地址寄存器
`define REG_SP          5'b00010    // x2 栈指针寄存器

//=================================================
// 存储器相关定义
//=================================================
`define DATA_MEM_SIZE   1024        // 数据存储器大小(字)
`define INSTR_MEM_SIZE  1024        // 指令存储器大小(字)

//=================================================
// 默认值定义
//=================================================
`define NOP_INSTRUCTION 32'h00000013 // NOP指令: addi x0, x0, 0
`define RESET_PC        32'h00000000 // 复位时PC值

`endif // DEFINES_V