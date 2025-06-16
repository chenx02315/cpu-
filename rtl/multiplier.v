`include "defines.v"

module multiplier (
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire [3:0]  alu_op,
    output reg  [31:0] mul_result
);

    // 64位乘法结果
    wire signed [63:0] signed_mul_result = $signed(operand_a) * $signed(operand_b);
    wire [63:0] unsigned_mul_result = operand_a * operand_b;
    wire signed [63:0] mixed_mul_result = $signed(operand_a) * operand_b;

    always @(*) begin
        // 无条件调试信息，确认模块的 always 块是否执行
        $display("[MULTIPLIER_ENTRY] timestamp: %0t, alu_op_in = %b (%d), op_a = %h, op_b = %h", $time, alu_op, alu_op, operand_a, operand_b);
        
        // 添加调试信息
        $display("[MULTIPLIER_DEBUG] timestamp: %0t, alu_op_in = %b (%d), op_a = %h, op_b = %h", $time, alu_op, alu_op, operand_a, operand_b);
        case (alu_op)
            `ALU_MUL: begin
                mul_result = unsigned_mul_result[31:0];
                $display("[MULTIPLIER_DEBUG] Matched ALU_MUL. unsigned_mul_result[31:0] = %h. Output mul_result = %h", unsigned_mul_result[31:0], mul_result);
            end
            
            `ALU_MULH: begin
                mul_result = signed_mul_result[63:32];
                $display("[MULTIPLIER_DEBUG] Matched ALU_MULH. signed_mul_result[63:32] = %h. Output mul_result = %h", signed_mul_result[63:32], mul_result);
            end
            
            `ALU_MULHSU: begin
                mul_result = mixed_mul_result[63:32];
                $display("[MULTIPLIER_DEBUG] Matched ALU_MULHSU. mixed_mul_result[63:32] = %h. Output mul_result = %h", mixed_mul_result[63:32], mul_result);
            end
            
            `ALU_MULHU: begin
                mul_result = unsigned_mul_result[63:32];
                $display("[MULTIPLIER_DEBUG] Matched ALU_MULHU. unsigned_mul_result[63:32] = %h. Output mul_result = %h", unsigned_mul_result[63:32], mul_result);
            end
            
            default: begin
                mul_result = 32'h00000000; // 保持默认输出0，以便观察是否是default分支导致x27为0
                $display("[MULTIPLIER_DEBUG] Hit DEFAULT case. alu_op = %b (%d). Output mul_result = %h", alu_op, alu_op, mul_result);
            end
        endcase
    end

endmodule