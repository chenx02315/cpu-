`include "defines.v"

module alu (
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire [3:0]  alu_op,
    output reg  [31:0] alu_result,
    output wire        zero_flag
);

    // 中间计算结果 - 使用更精确的类型转换
    wire signed [31:0] signed_a = $signed(operand_a);
    wire signed [31:0] signed_b = $signed(operand_b);
    wire [4:0] shift_amount = operand_b[4:0];  // 移位量始终为低5位
    
    // Zero flag generation - 基于ALU结果
    assign zero_flag = (alu_result == 32'b0);

    // ALU operations
    always @(*) begin
        case (alu_op)
            `ALU_ADD: begin
                // 32位加法，自动截断溢出
                alu_result = operand_a + operand_b;
            end
            
            `ALU_SUB: begin
                // 32位减法，自动截断溢出
                alu_result = operand_a - operand_b;
            end
            
            `ALU_AND:  alu_result = operand_a & operand_b;
            `ALU_OR:   alu_result = operand_a | operand_b;
            `ALU_XOR:  alu_result = operand_a ^ operand_b;
            
            `ALU_SLL: begin
                // 逻辑左移，只使用低5位
                alu_result = operand_a << shift_amount;
            end
            
            `ALU_SRL: begin
                // 修复: 逻辑右移，确保正确处理大移位量
                if (shift_amount == 5'd0) begin
                    alu_result = operand_a;
                end else begin
                    alu_result = operand_a >> shift_amount;
                end
            end
            
            `ALU_SRA: begin
                // 修复: 算术右移，正确保持符号位
                if (shift_amount == 5'd0) begin
                    alu_result = operand_a;
                end else begin
                    alu_result = $unsigned(signed_a >>> shift_amount);
                end
            end
            
            `ALU_SLT: begin
                // 有符号比较: a < b 时结果为1
                alu_result = (signed_a < signed_b) ? 32'h00000001 : 32'h00000000;
            end
            
            `ALU_SLTU: begin
                // 无符号比较: a < b 时结果为1
                alu_result = (operand_a < operand_b) ? 32'h00000001 : 32'h00000000;
            end
            
            // 乘法操作码传递给ALU但不执行，实际由乘法器处理
            `ALU_MUL, `ALU_MULH, `ALU_MULHSU, `ALU_MULHU: begin
                alu_result = 32'h00000000;  // ALU不处理乘法，返回0
            end
            
            default: begin
                alu_result = 32'h00000000;
            end
        endcase
    end

endmodule