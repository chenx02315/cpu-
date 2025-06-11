`include "defines.v"

module multiplier (
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire [3:0]  alu_op,        // 修复：使用alu_op作为输入端口
    output reg  [31:0] mul_result
);

    // 64位乘法结果
    wire signed [63:0] signed_mul_result = $signed(operand_a) * $signed(operand_b);
    wire [63:0] unsigned_mul_result = operand_a * operand_b;
    wire signed [63:0] mixed_mul_result = $signed(operand_a) * operand_b;

    always @(*) begin
        case (alu_op)
            `ALU_MUL: begin
                // MUL - 32位乘法的低32位
                mul_result = unsigned_mul_result[31:0];
            end
            
            `ALU_MULH: begin
                // MULH - 有符号乘法的高32位
                mul_result = signed_mul_result[63:32];
            end
            
            `ALU_MULHSU: begin
                // MULHSU - 有符号*无符号乘法的高32位
                mul_result = mixed_mul_result[63:32];
            end
            
            `ALU_MULHU: begin
                // MULHU - 无符号乘法的高32位
                mul_result = unsigned_mul_result[63:32];
            end
            
            default: begin
                mul_result = 32'h00000000;
            end
        endcase
    end

endmodule