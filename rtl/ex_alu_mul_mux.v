`include "defines.v"

module ex_alu_mul_mux (
    input wire [3:0]  alu_op,         // ALU operation type from control unit
    input wire [31:0] alu_result,     // Result from ALU
    input wire [31:0] mul_result,     // Result from Multiplier
    output reg [31:0] final_result    // Selected result for EX stage output
);

    always @(*) begin
        // Check if the ALU operation is one of the multiplication types
        if (alu_op == `ALU_MUL    || 
            alu_op == `ALU_MULH   || 
            alu_op == `ALU_MULHSU || 
            alu_op == `ALU_MULHU) begin
            final_result = mul_result; // Select multiplier result
        end else begin
            final_result = alu_result;  // Select ALU result
        end
    end

endmodule
