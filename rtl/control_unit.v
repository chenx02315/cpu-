`include "defines.v"

module control_unit (
    input  wire [6:0] opcode_i,
    input  wire [2:0] funct3_i,
    input  wire [6:0] funct7_i,
    
    output reg  [3:0] alu_op_o,
    output reg        alu_src_o,
    output reg        mem_read_o,
    output reg        mem_write_o,
    output reg        branch_o,
    output reg        reg_write_o,
    output reg [1:0]  mem_to_reg_o
);

    always @(*) begin
        // 默认值
        alu_op_o = `ALU_ADD;
        alu_src_o = 1'b0;
        mem_read_o = 1'b0;
        mem_write_o = 1'b0;
        branch_o = 1'b0;
        reg_write_o = 1'b0;
        mem_to_reg_o = 2'b00;
        
        case (opcode_i)
            `OPCODE_LUI: begin
                alu_op_o = `ALU_ADD;
                alu_src_o = 1'b1;
                reg_write_o = 1'b1;
                mem_to_reg_o = `MEM_TO_REG_ALU;
            end
            
            `OPCODE_AUIPC: begin
                alu_op_o = `ALU_ADD;
                alu_src_o = 1'b1;
                reg_write_o = 1'b1;
                mem_to_reg_o = `MEM_TO_REG_ALU;
            end
            
            `OPCODE_JAL: begin
                alu_op_o = `ALU_ADD;
                alu_src_o = 1'b1;
                reg_write_o = 1'b1;
                mem_to_reg_o = `MEM_TO_REG_PC4;
            end
            
            `OPCODE_JALR: begin
                alu_op_o = `ALU_ADD;
                alu_src_o = 1'b1;
                reg_write_o = 1'b1;
                mem_to_reg_o = `MEM_TO_REG_PC4;
            end
            
            `OPCODE_BRANCH: begin
                case (funct3_i)
                    `FUNCT3_BEQ, `FUNCT3_BNE: alu_op_o = `ALU_SUB;
                    `FUNCT3_BLT, `FUNCT3_BGE: alu_op_o = `ALU_SLT;
                    `FUNCT3_BLTU, `FUNCT3_BGEU: alu_op_o = `ALU_SLTU;
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
            end
            
            `OPCODE_STORE: begin
                alu_op_o = `ALU_ADD;
                alu_src_o = 1'b1;
                mem_write_o = 1'b1;
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
            end
            
            `OPCODE_ARITH: begin
                alu_src_o = 1'b0;       // R-type instructions use two registers
                reg_write_o = 1'b1;     // R-type instructions (mostly) write to a register
                mem_to_reg_o = `MEM_TO_REG_ALU;

                if (funct7_i == `FUNCT7_MUL) begin // M Extension instructions
                    case (funct3_i)
                        `FUNCT3_ADD:  alu_op_o = `ALU_MUL;    // MUL (funct3 for MUL is 000)
                        `FUNCT3_SLL:  alu_op_o = `ALU_MULH;   // MULH (funct3 for MULH is 001)
                        `FUNCT3_SLT:  alu_op_o = `ALU_MULHSU; // MULHSU (funct3 for MULHSU is 010)
                        `FUNCT3_SLTU: alu_op_o = `ALU_MULHU; // MULHU (funct3 for MULHU is 011)
                        default:      alu_op_o = `ALU_ADD; // Should be illegal instruction
                    endcase
                end else begin // Base ISA R-type instructions
                    case (funct3_i)
                        `FUNCT3_ADD: begin // ADD or SUB
                            if (funct7_i == `FUNCT7_SUB)
                                alu_op_o = `ALU_SUB;
                            else // Assumes FUNCT7_ADD or other (e.g. from non-standard use)
                                alu_op_o = `ALU_ADD; 
                        end
                        `FUNCT3_SLL: alu_op_o = `ALU_SLL;
                        `FUNCT3_SLT: alu_op_o = `ALU_SLT;
                        `FUNCT3_SLTU: alu_op_o = `ALU_SLTU;
                        `FUNCT3_XOR: alu_op_o = `ALU_XOR;
                        `FUNCT3_SRL: begin // SRL or SRA
                            if (funct7_i == `FUNCT7_SRA)
                                alu_op_o = `ALU_SRA;
                            else
                                alu_op_o = `ALU_SRL;
                        end
                        `FUNCT3_OR:  alu_op_o = `ALU_OR;
                        `FUNCT3_AND: alu_op_o = `ALU_AND;
                        default: alu_op_o = `ALU_ADD; // Should be illegal instruction
                    endcase
                end
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