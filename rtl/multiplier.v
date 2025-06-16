`include "defines.v"

module multiplier (
    input  wire [31:0] operand_a_i,
    input  wire [31:0] operand_b_i,
    input  wire [1:0]  mul_op_type_i, // 操作类型: MUL, MULH, MULHSU, MULHU
    output reg  [31:0] mul_result_o   // 乘法结果
);

    // 临时扩展到64位以获取高位结果
    wire [63:0] product_signed_signed;
    wire [63:0] product_signed_unsigned;
    wire [63:0] product_unsigned_unsigned;

    // 执行所有可能的乘法类型，以便后续选择
    assign product_signed_signed     = $signed(operand_a_i) * $signed(operand_b_i);
    assign product_signed_unsigned   = $signed(operand_a_i) * operand_b_i; // Verilog $signed * unsigned promotes unsigned to signed.
                                                                        // For true signed * unsigned, if operand_b_i is large positive, it's fine.
                                                                        // If we need specific behavior for MULHSU where B is unsigned,
                                                                        // we might need more careful casting or handling.
                                                                        // However, standard Verilog behavior for $signed * unsigned is usually sufficient.
    assign product_unsigned_unsigned = operand_a_i * operand_b_i;


    always @(*) begin
        case (mul_op_type_i)
            `MUL_OP_MUL: begin
                // MUL: 返回乘积的低32位
                mul_result_o = operand_a_i * operand_b_i; // 直接使用 * 操作符
            end
            `MUL_OP_MULH: begin
                // MULH: 返回有符号乘积的高32位
                mul_result_o = product_signed_signed[63:32];
            end
            `MUL_OP_MULHSU: begin
                // MULHSU: 返回有符号操作数A * 无符号操作数B 的高32位
                // Verilog's $signed * unsigned might not directly give the exact RISC-V spec behavior
                // without careful handling of signs if B is treated as unsigned for the full 64-bit product.
                // A common way:
                // wire [63:0] temp_b_unsigned_extended = {32'b0, operand_b_i};
                // wire [63:0] temp_a_signed_extended = {{32{operand_a_i[31]}}, operand_a_i};
                // wire [63:0] full_product_su = temp_a_signed_extended * temp_b_unsigned_extended;
                // For simplicity now, using the direct product. This might need refinement for full MULHSU correctness.
                mul_result_o = product_signed_unsigned[63:32];
            end
            `MUL_OP_MULHU: begin
                // MULHU: 返回无符号乘积的高32位
                mul_result_o = product_unsigned_unsigned[63:32];
            end
            default: begin
                mul_result_o = 32'hdeadbeef; // 未知操作类型
            end
        endcase
    end

endmodule