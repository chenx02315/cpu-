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
        case (alu_op)
            `ALU_ADD: begin
                alu_result = operand_a + operand_b;
            end
            
            `ALU_SUB: begin
                alu_result = operand_a - operand_b;
                // 只对特定的SUB操作进行调试（关键的SUB指令）
                if (operand_a == 32'h401e1042 && operand_b == 32'h7fffffff) begin
                    $display("========================================");
                    $display("[ALU_CRITICAL] 关键SUB指令执行!");
                    $display("操作数A: 0x%08x", operand_a);
                    $display("操作数B: 0x%08x", operand_b);
                    $display("计算结果: 0x%08x", operand_a - operand_b);
                    $display("期望结果: 0x5980edb5");
                    $display("========================================");
                end
            end
            
            `ALU_AND:  alu_result = operand_a & operand_b;
            `ALU_OR:   alu_result = operand_a | operand_b;
            `ALU_XOR:  alu_result = operand_a ^ operand_b;
            
            `ALU_SLL: begin
                alu_result = operand_a << operand_b[4:0];
            end
            
            `ALU_SRL: begin
                alu_result = operand_a >> operand_b[4:0];
            end
            
            `ALU_SRA: begin
                alu_result = $signed(operand_a) >>> operand_b[4:0];
            end
            
            `ALU_SLT: begin
                alu_result = ($signed(operand_a) < $signed(operand_b)) ? 32'h1 : 32'h0;
            end
            
            `ALU_SLTU: begin
                alu_result = (operand_a < operand_b) ? 32'h1 : 32'h0;
            end
            
            default: begin
                alu_result = 32'h0;
                $display("[ALU_DEBUG] 未知ALU操作: alu_op=%d", alu_op);
            end
        endcase
    end

endmodule