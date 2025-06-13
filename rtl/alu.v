`include "defines.v"

module alu (
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire [3:0]  alu_op,
    output reg  [31:0] alu_result,
    output wire        zero_flag
);

    // Zero flag generation
    assign zero_flag = (alu_result == 32'b0);

    // ALU operations
    always @(*) begin
        // 强制显示所有ALU操作
        if (alu_op != 4'b0000 || (operand_a != 32'h0 && operand_b != 32'h0)) begin
            $display("[ALU_DEBUG] op=%d, A=0x%08x, B=0x%08x", alu_op, operand_a, operand_b);
        end
        
        case (alu_op)
            4'b0000: begin  // ALU_ADD
                alu_result = operand_a + operand_b;
            end
            
            4'b0001: begin  // ALU_SUB - 强制使用数值
                alu_result = operand_a - operand_b;
                $display("[ALU_SUB] A=0x%08x - B=0x%08x = 0x%08x", 
                        operand_a, operand_b, operand_a - operand_b);
                
                // 特别监控关键操作数
                if ((operand_a == 32'h401e1042 && operand_b == 32'h7fffffff) ||
                    (operand_a == 32'hc41f1efb && operand_b == 32'h7fffffff)) begin
                    $display("*** 发现关键SUB操作! 手工计算验证: ***");
                    $display("    期望: 0x401e1042 - 0x7fffffff = 0xc01e1043");
                    $display("    实际ALU输出: 0x%08x", operand_a - operand_b);
                end
            end
            
            4'b0010: alu_result = operand_a & operand_b;  // ALU_AND
            4'b0011: alu_result = operand_a | operand_b;  // ALU_OR
            4'b0100: alu_result = operand_a ^ operand_b;  // ALU_XOR
            
            4'b0101: begin  // ALU_SLL
                alu_result = operand_a << operand_b[4:0];
            end
            
            4'b0110: begin  // ALU_SRL
                alu_result = operand_a >> operand_b[4:0];
            end
            
            4'b0111: begin  // ALU_SRA
                alu_result = $signed(operand_a) >>> operand_b[4:0];
            end
            
            4'b1000: begin  // ALU_SLT
                alu_result = ($signed(operand_a) < $signed(operand_b)) ? 32'h1 : 32'h0;
            end
            
            4'b1001: begin  // ALU_SLTU
                alu_result = (operand_a < operand_b) ? 32'h1 : 32'h0;
            end
            
            default: begin
                alu_result = 32'h0;
                $display("[ALU_ERROR] 未知操作码: %d", alu_op);
            end
        endcase
    end

endmodule