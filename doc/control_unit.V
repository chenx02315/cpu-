// control_unit.v (控制单元)
`include "defines.v"

module control_unit (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7, // 仅某些R型和I型移位指令需要

    // ------ 给 EX 阶段的控制信号 ------
    output reg [3:0] ALUOp,    // 示例: 4位定义ALU/乘法操作
                                // 0000: ADD, 0001: SUB, ..., 1000: MUL, 1001: MULH 等
    output reg       ALUSrc,   // 0: ALU B操作数来自寄存器Reg2Data, 1: 来自立即数Imm

    // ------ 给 MEM 阶段的控制信号 ------
    output reg       MemRead,  // Load指令使能内存读
    output reg       MemWrite, // Store指令使能内存写
    output reg       Branch,   // 是否是分支指令 (BEQ, BNE 等)?

    // ------ 给 WB 阶段的控制信号 ------
    output reg       RegWrite, // 使能写回寄存器堆
    output reg [1:0] MemToReg  // 00: ALU结果写回, 01: 内存数据写回, 10: PC+4 写回

    // 你可能还需要更多信号, 例如用于Jumps, LUI, AUIPC的特殊处理
);

always @(*) begin
    // 设置控制信号的默认值 (通常是全关闭或安全状态)
    ALUOp    = `ALU_OP_ADD; // 或者某个 NOP/默认操作
    ALUSrc   = 1'b0;
    MemRead  = 1'b0;
    MemWrite = 1'b0;
    Branch   = 1'b0;
    RegWrite = 1'b0;
    MemToReg = `WB_DATA_FROM_ALU_RESULT; // Default to ALU result

    case (opcode)
        7'b0110011: begin // R-type (ALU 和 M扩展)
            RegWrite = 1'b1; MemToReg = `WB_DATA_FROM_ALU_RESULT; ALUSrc = 1'b0; // R-type 通常如此
            if (funct7 == 7'b0000001) begin // M扩展 (乘法)
                case (funct3)
                    3'b000: ALUOp = `MUL_OP_MUL;   // mul
                    3'b001: ALUOp = `MUL_OP_MULH;  // mulh
                    3'b010: ALUOp = `MUL_OP_MULHSU; // mulhsu
                    3'b011: ALUOp = `MUL_OP_MULHU; // mulhu
                    default: ; // 非法 M-type (或者设为非法指令标志)
                endcase
            end else begin // 标准 ALU R-type
                case (funct3)
                    3'b000: if (funct7 == 7'b0000000) ALUOp = `ALU_OP_ADD; // ADD
                            else if (funct7 == 7'b0100000) ALUOp = `ALU_OP_SUB; // SUB
                    3'b001: ALUOp = `ALU_OP_SLL;  // SLL
                    3'b010: ALUOp = `ALU_OP_SLT;  // SLT
                    3'b011: ALUOp = `ALU_OP_SLTU; // SLTU
                    3'b100: ALUOp = `ALU_OP_XOR;  // XOR
                    3'b101: if (funct7 == 7'b0000000) ALUOp = `ALU_OP_SRL; // SRL
                            else if (funct7 == 7'b0100000) ALUOp = `ALU_OP_SRA; // SRA
                    3'b110: ALUOp = `ALU_OP_OR;   // OR
                    3'b111: ALUOp = `ALU_OP_AND;  // AND
                    default: ; // 非法 R-type
                endcase
            end
        end
        7'b0010011: begin // I-type (ALU 立即数)
            RegWrite = 1'b1; MemToReg = `WB_DATA_FROM_ALU_RESULT; ALUSrc = 1'b1; // I-type ALU 通常如此
            case (funct3)
                3'b000: ALUOp = `ALU_OP_ADD;  // ADDI (ALUOp 与 ADD 相同)
                3'b010: ALUOp = `ALU_OP_SLT;  // SLTI
                3'b011: ALUOp = `ALU_OP_SLTU; // SLTIU
                3'b100: ALUOp = `ALU_OP_XOR;  // XORI
                3'b110: ALUOp = `ALU_OP_OR;   // ORI
                3'b111: ALUOp = `ALU_OP_AND;  // ANDI
                3'b001: ALUOp = `ALU_OP_SLL;  // SLLI (funct7[6:5] == 2'b00)
                3'b101: if (funct7 == 7'b0000000) ALUOp = `ALU_OP_SRL; // SRLI
                        else if (funct7 == 7'b0100000) ALUOp = `ALU_OP_SRA; // SRAI
                default: ; // 非法 I-type ALU
            endcase
        end
        7'b0000011: begin // I-type (Load)
            RegWrite = 1'b1; MemToReg = `WB_DATA_FROM_MEM_READ; ALUSrc = 1'b1; // 地址计算需要立即数
            MemRead  = 1'b1;
            ALUOp    = `ALU_OP_ADD; // ALU 用于地址计算 (基址 + 偏移)
            // funct3 决定字节/半字/字和符号扩展，这部分在MEM/WB阶段或数据存储器模块内部处理。
            // 或者你可以增加一个控制信号，例如 LoadStoreType
        end
        7'b0100011: begin // S-type (Store)
            RegWrite = 1'b0; ALUSrc = 1'b1; // 地址计算
            MemWrite = 1'b1;
            ALUOp    = `ALU_OP_ADD; // ALU 用于地址计算
            // MemToReg is don't care as RegWrite is 0
        end
        7'b1100011: begin // B-type (Branch)
            RegWrite = 1'b0; ALUSrc = 1'b0; // 操作数来自寄存器
            Branch   = 1'b1;
            // ALUOp 会是 SUB (用于 BEQ/BNE 判断Zero标志) 或 SLT/SLTU 等
            case(funct3)
                3'b000: ALUOp = `ALU_OP_SUB;  // BEQ (rs1-rs2 == 0?)
                3'b001: ALUOp = `ALU_OP_SUB;  // BNE (rs1-rs2 != 0?)
                3'b100: ALUOp = `ALU_OP_SLT;  // BLT
                3'b101: ALUOp = `ALU_OP_SLT;  // BGE (用SLT判断，逻辑反转)
                3'b110: ALUOp = `ALU_OP_SLTU; // BLTU
                3'b111: ALUOp = `ALU_OP_SLTU; // BGEU (用SLTU判断，逻辑反转)
                default: ; // 非法 Branch
            endcase
        end
        7'b0110111: begin // U-type (LUI)
            RegWrite = 1'b1; MemToReg = `WB_DATA_FROM_ALU_RESULT;
            ALUSrc   = 1'b1; // LUI 可以看作是把立即数送给ALU (ALU可能只是透传)
                             // 或者EX阶段直接处理，不通过ALU的标准操作
            ALUOp    = `ALU_OP_LUI; // 特殊的ALUOp给LUI，表示将第二个操作数（立即数）直接输出
                                  // 或者在EX级单独处理LUI，不通过ALU主路径
        end
        7'b0010111: begin // U-type (AUIPC)
            RegWrite = 1'b1; MemToReg = `WB_DATA_FROM_ALU_RESULT;
            ALUSrc   = 1'b1; // 将立即数传给ALU的一个输入
            ALUOp    = `ALU_OP_AUIPC; // 特殊的ALUOp给AUIPC (PC + 立即数)
                                    // PC的值需要从ID/EX流水线寄存器中获取
        end
        7'b1101111: begin // J-type (JAL)
            RegWrite = 1'b1; // 将 PC+4 写入 rd
            MemToReg = `WB_DATA_FROM_PC_PLUS_4; // 结果是 PC+4
            Branch = 1'b1; // Indicates a change in PC flow (unconditional jump)
            ALUSrc = 1'b0; // Not strictly needed for ALUOp if JAL is handled by PC logic directly
            ALUOp  = `ALU_OP_ADD; // Can be NOP or ADD for PC + offset if PC logic uses ALU
        end
        7'b1100111: begin // I-type (JALR)
            RegWrite = 1'b1; // 将 PC+4 写入 rd
            MemToReg = `WB_DATA_FROM_PC_PLUS_4; // 结果是 PC+4
            ALUSrc   = 1'b1; // 用于 rs1 + 立即数
            ALUOp    = `ALU_OP_ADD; // 用于目标地址计算
            Branch = 1'b1; // Indicates a change in PC flow (unconditional jump)
        end
        // FENCE, ECALL/EBREAK, CSRs 比较复杂.
        // 目前你可以将它们视为 NOP 或非法指令。
        default: begin
            // 作为非法指令处理 - 或许设置一个 'IllegalOp' 标志
            // 所有控制信号保持默认（通常是安全的“不做任何操作”状态）
        end
    endcase
end
endmodule