`include "defines.v"

module if_id_register (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall_i,     // 添加缺失的接口
    input  wire        flush_i,     // 添加缺失的接口
    
    // IF stage inputs
    input  wire [31:0] pc_if_i,
    input  wire [31:0] pc_plus_4_if_i,
    input  wire [31:0] instruction_if_i,
    
    // ID stage outputs
    output reg  [31:0] pc_id_o,
    output reg  [31:0] pc_plus_4_id_o,
    output reg  [31:0] instruction_id_o
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_id_o <= 32'h00000000;
            pc_plus_4_id_o <= 32'h00000004;
            instruction_id_o <= `NOP_INSTRUCTION;
        end
        else if (flush_i) begin
            // 冲刷时插入NOP指令
            pc_id_o <= 32'h00000000;
            pc_plus_4_id_o <= 32'h00000004;
            instruction_id_o <= `NOP_INSTRUCTION;
        end
        else if (!stall_i) begin
            // 正常流水线推进
            pc_id_o <= pc_if_i;
            pc_plus_4_id_o <= pc_plus_4_if_i;
            instruction_id_o <= instruction_if_i;
        end
        // stall时保持当前值不变
    end

endmodule