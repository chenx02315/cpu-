`include "defines.v"

module ex_alu_mul_mux (
    input  wire [3:0]  alu_op,
    input  wire [31:0] alu_result,
    input  wire [31:0] mul_result,
    output reg  [31:0] final_result
);

    always @(*) begin
        case (alu_op)
            `ALU_MUL,
            `ALU_MULH,
            `ALU_MULHSU,
            `ALU_MULHU: begin
                // 乘法操作，选择乘法器结果
                final_result = mul_result;
            end
            default: begin
                // 其他操作，选择ALU结果
                final_result = alu_result;
            end
        endcase
    end

endmodule
