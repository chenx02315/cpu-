`include "defines.v"

module control_unit (
    input  wire [6:0] opcode_i,
    input  wire [2:0] funct3_i,
    input  wire [6:0] funct7_i,
    
    output reg  [3:0] alu_op_o,
    output reg        alu_src_o,        // 0: reg2_data, 1: immediate
    output reg        mem_read_o,
    output reg        mem_write_o,
    output reg        branch_o,
    output reg        reg_write_o,
    output reg [1:0]  mem_to_reg_o      // 00: ALU, 01: Memory, 10: PC+4
);

    always @(*) begin
        // Default values
        alu_op_o = `ALU_ADD;
        alu_src_o = 1'b0;
        mem_read_o = 1'b0;
        mem_write_o = 1'b0;
        branch_o = 1'b0;
        reg_write_o = 1'b0;
        mem_to_reg_o = `MEM_TO_REG_ALU;
        
        case (opcode_i)
            `OPCODE_LUI: begin
                alu_op_o = `ALU_ADD;
                alu_src_o = 1'b1;
                reg_write_o = 1'b1;
                mem_to_reg_o = `MEM_TO_REG_ALU;
                branch_o = 1'b0;
            end
            
            `OPCODE_AUIPC: begin
                alu_op_o = `ALU_ADD;
                alu_src_o = 1'b1;
                reg_write_o = 1'b1;
                mem_to_reg_o = `MEM_TO_REG_ALU;
                branch_o = 1'b0;
            end
            
            `OPCODE_JAL: begin
                alu_op_o = `ALU_ADD;
                alu_src_o = 1'b1;
                reg_write_o = 1'b1;
                mem_to_reg_o = `MEM_TO_REG_PC4;
                branch_o = 1'b0;
            end
            
            `OPCODE_JALR: begin
                alu_op_o = `ALU_ADD;
                alu_src_o = 1'b1;
                reg_write_o = 1'b1;
                mem_to_reg_o = `MEM_TO_REG_PC4;
                branch_o = 1'b0;
            end
            
            `OPCODE_BRANCH: begin
                case (funct3_i)
                    `FUNCT3_BEQ, `FUNCT3_BNE: begin
                        alu_op_o = `ALU_SUB;
                    end
                    `FUNCT3_BLT, `FUNCT3_BGE: begin
                        alu_op_o = `ALU_SLT;
                    end
                    `FUNCT3_BLTU, `FUNCT3_BGEU: begin
                        alu_op_o = `ALU_SLTU;
                    end
                    default: alu_op_o = `ALU_SUB;
                endcase
                alu_src_o = 1'b0;
                branch_o = 1'b1;
            end
            
            `OPCODE_LOAD: begin
                alu_op_o = `ALU_ADD;
                alu_src_o = 1'b1;
                mem_read_o = 1'b1;
                reg_write_o = 1'b1;
                mem_to_reg_o = `MEM_TO_REG_MEM;
                branch_o = 1'b0;
            end
            
            `OPCODE_STORE: begin
                alu_op_o = `ALU_ADD;
                alu_src_o = 1'b1;
                mem_write_o = 1'b1;
                branch_o = 1'b0;
            end
            
            `OPCODE_IMM: begin
                case (funct3_i)
                    `FUNCT3_ADDI: alu_op_o = `ALU_ADD;
                    `FUNCT3_SLTI: alu_op_o = `ALU_SLT;
                    `FUNCT3_SLTIU: alu_op_o = `ALU_SLTU;
                    `FUNCT3_XORI: alu_op_o = `ALU_XOR;
                    `FUNCT3_ORI: alu_op_o = `ALU_OR;
                    `FUNCT3_ANDI: alu_op_o = `ALU_AND;
                    `FUNCT3_SLLI: alu_op_o = `ALU_SLL;
                    `FUNCT3_SRLI: begin
                        if (funct7_i == `FUNCT7_SRA)
                            alu_op_o = `ALU_SRA;
                        else
                            alu_op_o = `ALU_SRL;
                    end
                    default: alu_op_o = `ALU_ADD;
                endcase
                alu_src_o = 1'b1;
                reg_write_o = 1'b1;
                mem_to_reg_o = `MEM_TO_REG_ALU;
                branch_o = 1'b0;
            end
            
            `OPCODE_ARITH: begin
                case (funct3_i)
                    `FUNCT3_ADD: begin
                        if (funct7_i == `FUNCT7_SUB)
                            alu_op_o = `ALU_SUB;
                        else if (funct7_i == `FUNCT7_MUL)
                            alu_op_o = `ALU_MUL;
                        else
                            alu_op_o = `ALU_ADD;
                    end
                    `FUNCT3_SLL: alu_op_o = `ALU_SLL;
                    `FUNCT3_SLT: alu_op_o = `ALU_SLT;
                    `FUNCT3_SLTU: alu_op_o = `ALU_SLTU;
                    `FUNCT3_XOR: alu_op_o = `ALU_XOR;
                    `FUNCT3_SRL: begin
                        if (funct7_i == `FUNCT7_SRA)
                            alu_op_o = `ALU_SRA;
                        else
                            alu_op_o = `ALU_SRL;
                    end
                    `FUNCT3_OR: alu_op_o = `ALU_OR;
                    `FUNCT3_AND: alu_op_o = `ALU_AND;
                    `FUNCT3_MULH: begin
                        // 修复: 正确处理MULH指令
                        if (funct7_i == `FUNCT7_MUL)
                            alu_op_o = `ALU_MULH;
                        else
                            alu_op_o = `ALU_ADD;  // 默认操作
                    end
                    `FUNCT3_MULHSU: begin
                        // 修复: 正确处理MULHSU指令
                        if (funct7_i == `FUNCT7_MUL)
                            alu_op_o = `ALU_MULHSU;
                        else
                            alu_op_o = `ALU_ADD;  // 默认操作
                    end
                    `FUNCT3_MULHU: begin
                        // 修复: 正确处理MULHU指令
                        if (funct7_i == `FUNCT7_MUL)
                            alu_op_o = `ALU_MULHU;
                        else
                            alu_op_o = `ALU_ADD;  // 默认操作
                    end
                    default: alu_op_o = `ALU_ADD;
                endcase
                alu_src_o = 1'b0;
                reg_write_o = 1'b1;
                mem_to_reg_o = `MEM_TO_REG_ALU;
                branch_o = 1'b0;
            end
            
            default: begin
                alu_op_o = `ALU_ADD;
                alu_src_o = 1'b0;
                mem_read_o = 1'b0;
                mem_write_o = 1'b0;
                branch_o = 1'b0;
                reg_write_o = 1'b0;
                mem_to_reg_o = `MEM_TO_REG_ALU;
            end
        endcase
    end

endmodule
