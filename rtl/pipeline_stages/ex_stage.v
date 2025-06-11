`include "defines.v"

module ex_stage (
    input  wire [31:0] pc_ex_i,
    input  wire [31:0] pc_plus_4_ex_i,
    input  wire [31:0] operand_a_ex_i,
    input  wire [31:0] operand_b_src_ex_i,
    input  wire [31:0] immediate_ex_i,
    input  wire [4:0]  rd_addr_ex_i,
    input  wire [2:0]  funct3_ex_i,
    input  wire [6:0]  funct7_ex_i,
    input  wire [6:0]  opcode_ex_i,
    input  wire [3:0]  alu_op_ex_i,
    input  wire        alu_src_ex_i,
    input  wire        mem_read_ex_i,
    input  wire        mem_write_ex_i,
    input  wire        branch_ctrl_ex_i,
    input  wire        reg_write_ex_i,
    input  wire [1:0]  mem_to_reg_ex_i,
    input  wire [31:0] forward_data_a_i,
    input  wire [31:0] forward_data_b_i,
    input  wire [1:0]  forward_a_select_i,
    input  wire [1:0]  forward_b_select_i,
    
    output wire [31:0] pc_for_mem_o,
    output wire [31:0] pc_plus_4_mem_o,
    output wire [31:0] ex_result_mem_o,
    output wire        zero_flag_mem_o,
    output wire [31:0] reg2_data_mem_o,
    output wire [31:0] immediate_mem_o,
    output wire [4:0]  rd_addr_mem_o,
    output wire [2:0]  funct3_mem_o,
    output wire [6:0]  opcode_mem_o,
    output wire        mem_read_mem_o,
    output wire        mem_write_mem_o,
    output wire        branch_ctrl_mem_o,
    output wire        reg_write_mem_o,
    output wire [1:0]  mem_to_reg_mem_o
);

    // 前推后的操作数
    wire [31:0] operand_a_forwarded;
    wire [31:0] operand_b_forwarded;
    
    // 前推选择逻辑
    assign operand_a_forwarded = (forward_a_select_i == 2'b01) ? forward_data_a_i :
                                (forward_a_select_i == 2'b10) ? forward_data_b_i :
                                operand_a_ex_i;
                                
    assign operand_b_forwarded = (forward_b_select_i == 2'b01) ? forward_data_a_i :
                                (forward_b_select_i == 2'b10) ? forward_data_b_i :
                                operand_b_src_ex_i;
    
    // ALU第二个操作数选择
    wire [31:0] alu_operand_b = alu_src_ex_i ? immediate_ex_i : operand_b_forwarded;
    
    // ALU结果
    wire [31:0] alu_result;
    wire        alu_zero_flag;
    
    // 乘法器结果
    wire [31:0] mul_result;
    
    // 结果选择（ALU或乘法器）
    wire [31:0] final_result;
    
    // 实例化ALU
    alu u_alu (
        .operand_a(operand_a_forwarded),
        .operand_b(alu_operand_b),
        .alu_op(alu_op_ex_i),
        .alu_result(alu_result),
        .zero_flag(alu_zero_flag)
    );
    
    // 实例化乘法器 - 修复：使用正确的端口名称
    multiplier u_multiplier (
        .operand_a(operand_a_forwarded),
        .operand_b(operand_b_forwarded),
        .alu_op(alu_op_ex_i),           // 修复：使用alu_op端口
        .mul_result(mul_result)         // 修复：只保留存在的端口
    );
    
    // 实例化ALU/乘法器结果选择器
    ex_alu_mul_mux u_ex_alu_mul_mux (
        .alu_op(alu_op_ex_i),
        .alu_result(alu_result),
        .mul_result(mul_result),
        .final_result(final_result)
    );
    
    // 输出信号
    assign pc_for_mem_o = pc_ex_i;
    assign pc_plus_4_mem_o = pc_plus_4_ex_i;
    assign ex_result_mem_o = final_result;
    assign zero_flag_mem_o = alu_zero_flag;
    assign reg2_data_mem_o = operand_b_forwarded;
    assign immediate_mem_o = immediate_ex_i;
    assign rd_addr_mem_o = rd_addr_ex_i;
    assign funct3_mem_o = funct3_ex_i;
    assign opcode_mem_o = opcode_ex_i;
    assign mem_read_mem_o = mem_read_ex_i;
    assign mem_write_mem_o = mem_write_ex_i;
    assign branch_ctrl_mem_o = branch_ctrl_ex_i;
    assign reg_write_mem_o = reg_write_ex_i;
    assign mem_to_reg_mem_o = mem_to_reg_ex_i;

endmodule
