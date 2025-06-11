`timescale 1ns/1ps
`include "defines.v"

module mem_stage (
    input  wire [31:0] pc_ex_mem_i,
    input  wire [31:0] pc_plus_4_mem_i,
    input  wire [31:0] ex_result_mem_i,
    input  wire        zero_flag_mem_i,
    input  wire [31:0] reg2_data_mem_i,
    input  wire [31:0] immediate_ex_mem_i,
    input  wire [4:0]  rd_addr_mem_i,
    input  wire [2:0]  funct3_mem_i,
    input  wire [6:0]  opcode_mem_i,        // 添加opcode输入
    input  wire        mem_read_mem_i,
    input  wire        mem_write_mem_i,
    input  wire        branch_ctrl_mem_i,
    input  wire        reg_write_mem_i,
    input  wire [1:0]  mem_to_reg_mem_i,
    input  wire [31:0] data_mem_read_data_i,
    
    output wire [1:0]  mem_to_reg_wb_o,
    output wire        branch_jump_request_o,
    output wire [1:0]  pc_sel_decision_o,
    output wire [31:0] branch_jump_target_addr_o,
    output wire [31:0] jalr_target_addr_o
);

    // 分支/跳转判断逻辑
    wire branch_taken;
    wire is_jal, is_jalr;
    
    // 指令类型检测
    assign is_jal = (opcode_mem_i == `OPCODE_JAL);
    assign is_jalr = (opcode_mem_i == `OPCODE_JALR);
    
    // 分支条件判断
    reg branch_condition_met;
    always @(*) begin
        if (!branch_ctrl_mem_i) begin
            branch_condition_met = 1'b0;
        end else begin
            case (funct3_mem_i)
                `FUNCT3_BEQ:  branch_condition_met = zero_flag_mem_i;        // beq: 相等时跳转
                `FUNCT3_BNE:  branch_condition_met = !zero_flag_mem_i;       // bne: 不等时跳转
                `FUNCT3_BLT:  branch_condition_met = !zero_flag_mem_i;       // blt: 小于时跳转
                `FUNCT3_BGE:  branch_condition_met = zero_flag_mem_i;        // bge: 大于等于时跳转
                `FUNCT3_BLTU: branch_condition_met = !zero_flag_mem_i;       // bltu: 无符号小于时跳转
                `FUNCT3_BGEU: branch_condition_met = zero_flag_mem_i;        // bgeu: 无符号大于等于时跳转
                default:      branch_condition_met = 1'b0;
            endcase
        end
    end
    
    assign branch_taken = branch_ctrl_mem_i && branch_condition_met;
    
    // 分支/跳转请求
    assign branch_jump_request_o = branch_taken || is_jal || is_jalr;
    
    // PC选择信号
    assign pc_sel_decision_o = is_jalr ? `PC_SEL_JALR :
                              (branch_taken || is_jal) ? `PC_SEL_BRANCH :
                              `PC_SEL_PLUS4;
    
    // 分支/跳转目标地址计算
    assign branch_jump_target_addr_o = pc_ex_mem_i + immediate_ex_mem_i;
    
    // JALR目标地址计算
    assign jalr_target_addr_o = (ex_result_mem_i & ~32'h1);  // JALR: (rs1 + imm) & ~1
    
    // 写回阶段的mem_to_reg信号
    assign mem_to_reg_wb_o = mem_to_reg_mem_i;
    
    // 调试输出
    always @(*) begin
        if (branch_jump_request_o) begin
            $display("[MEM] 分支/跳转请求: PC=0x%08x, 目标=0x%08x, 类型=%s", 
                    pc_ex_mem_i, 
                    is_jalr ? jalr_target_addr_o : branch_jump_target_addr_o,
                    is_jal ? "JAL" : is_jalr ? "JALR" : "BRANCH");
        end
    end

endmodule
