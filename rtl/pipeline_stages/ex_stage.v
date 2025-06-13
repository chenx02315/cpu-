`include "defines.v"

module ex_stage (
    input  wire        clk,
    input  wire        rst_n,
    
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

    // 修复：确保前推逻辑是纯组合逻辑，没有时序竞争
    wire [31:0] operand_a_forwarded;
    wire [31:0] operand_b_forwarded;
    
    // 前推选择逻辑 - 修复：使用更明确的条件判断
    assign operand_a_forwarded = (forward_a_select_i == `FORWARD_EX_MEM) ? forward_data_a_i :
                                (forward_a_select_i == `FORWARD_MEM_WB) ? forward_data_b_i :
                                operand_a_ex_i;
                                
    assign operand_b_forwarded = (forward_b_select_i == `FORWARD_EX_MEM) ? forward_data_a_i :
                                (forward_b_select_i == `FORWARD_MEM_WB) ? forward_data_b_i :
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
    
    // 超级详细的调试：监控前推信号的每一个时刻
    always @(*) begin
        if (pc_ex_i == 32'h118 && opcode_ex_i == 7'h33) begin
            $display("========================================");
            $display("[EX_SUPER_DEBUG] SUB指令超详细分析:");
            $display("时刻监控 - 输入信号:");
            $display("  PC: 0x%08x", pc_ex_i);
            $display("  原始操作数: A=0x%08x, B=0x%08x", operand_a_ex_i, operand_b_src_ex_i);
            $display("  前推数据输入: data_a=0x%08x, data_b=0x%08x", 
                    forward_data_a_i, forward_data_b_i);
            $display("  前推选择输入: forward_a=%b(%d), forward_b=%b(%d)", 
                    forward_a_select_i, forward_a_select_i,
                    forward_b_select_i, forward_b_select_i);
            
            $display("时刻监控 - 前推逻辑计算:");
            $display("  前推A条件检查:");
            $display("    forward_a == FORWARD_EX_MEM (%b): %b", 
                    `FORWARD_EX_MEM, (forward_a_select_i == `FORWARD_EX_MEM));
            $display("    forward_a == FORWARD_MEM_WB (%b): %b", 
                    `FORWARD_MEM_WB, (forward_a_select_i == `FORWARD_MEM_WB));
            
            $display("  前推B条件检查:");
            $display("    forward_b == FORWARD_EX_MEM (%b): %b", 
                    `FORWARD_EX_MEM, (forward_b_select_i == `FORWARD_EX_MEM));
            $display("    forward_b == FORWARD_MEM_WB (%b): %b", 
                    `FORWARD_MEM_WB, (forward_b_select_i == `FORWARD_MEM_WB));
            
            $display("时刻监控 - 前推结果:");
            $display("  前推后操作数: A=0x%08x, B=0x%08x", 
                    operand_a_forwarded, operand_b_forwarded);
            $display("  最终ALU操作数: A=0x%08x, B=0x%08x", 
                    operand_a_forwarded, alu_operand_b);
            $display("  ALU控制: %d, ALU源选择: %d", alu_op_ex_i, alu_src_ex_i);
            
            // 特别检查错误的操作数来源
            if (operand_a_forwarded != 32'hc41f1efb || alu_operand_b != 32'h6a9e3146) begin
                $display("*** 错误检测：操作数不匹配期望值！***");
                $display("    期望: A=0xc41f1efb, B=0x6a9e3146");
                $display("    实际: A=0x%08x, B=0x%08x", operand_a_forwarded, alu_operand_b);
                
                // 检查是否是前推选择的问题
                if (forward_a_select_i != 2'b00) begin
                    $display("    forward_a_select_i=%b 不是00，前推A被激活", forward_a_select_i);
                end
                if (forward_b_select_i != 2'b00) begin
                    $display("    forward_b_select_i=%b 不是00，前推B被激活", forward_b_select_i);
                end
            end else begin
                $display("✓ 操作数正确！");
            end
            $display("========================================");
        end
    end
    
    // 实例化ALU
    alu u_alu (
        .operand_a(operand_a_forwarded),
        .operand_b(alu_operand_b),
        .alu_op(alu_op_ex_i),
        .alu_result(alu_result),
        .zero_flag(alu_zero_flag)
    );
    
    // 实例化乘法器
    multiplier u_multiplier (
        .operand_a(operand_a_forwarded),
        .operand_b(operand_b_forwarded),
        .alu_op(alu_op_ex_i),
        .mul_result(mul_result)
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
