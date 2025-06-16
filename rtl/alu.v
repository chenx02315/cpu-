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
        // if (alu_op != 4'b0000 || (operand_a != 32'h0 && operand_b != 32'h0)) begin // Reduced verbosity
        //     $display("[ALU_DEBUG] op=%d, A=0x%08x, B=0x%08x", alu_op, operand_a, operand_b);
        // end
        
        case (alu_op)
            `ALU_ADD: begin
                alu_result = operand_a + operand_b;
            end
            
            `ALU_SUB: begin
                alu_result = operand_a - operand_b;
                // $display("[ALU_SUB] A=0x%08x - B=0x%08x = 0x%08x", 
                //         operand_a, operand_b, operand_a - operand_b);
            end
            
            `ALU_AND: alu_result = operand_a & operand_b;
            `ALU_OR:  alu_result = operand_a | operand_b;
            `ALU_XOR: alu_result = operand_a ^ operand_b;
            
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
            
            // 为乘法操作码添加处理：这些结果会被MUX忽略，但避免了ALU_ERROR
            // ALU本身不执行乘法，乘法器单独处理
            `ALU_MUL, `ALU_MULH, `ALU_MULHSU, `ALU_MULHU: begin
                alu_result = operand_a; // 或者 32'h0; 主要目的是避免 "未知操作码"
                                        // 这个alu_result会被ex_alu_mul_mux忽略
            end
            
            default: begin
                alu_result = 32'hdeadbeef; // 使用一个更明显的错误值
                $display("[ALU_ERROR] 未知或未明确处理的操作码: %b (dec %0d) @ %0t", alu_op, alu_op, $time);
            end
        endcase
    end

endmodule