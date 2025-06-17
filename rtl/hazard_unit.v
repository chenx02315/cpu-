`include "defines.v"

module hazard_unit (
    input  wire [4:0]  id_rs1_addr_i,
    input  wire [4:0]  id_rs2_addr_i,
    input  wire        id_mem_read_i,
    input  wire        id_use_rs1_i,
    input  wire        id_use_rs2_i,
    
    input  wire [4:0]  ex_rd_addr_i,
    input  wire        ex_reg_write_i,
    input  wire        ex_mem_read_i,
    input  wire        ex_is_nop_i,
    
    input  wire [4:0]  mem_rd_addr_i,
    input  wire        mem_reg_write_i,
    input  wire        mem_is_nop_i,
    
    input  wire        branch_jump_request_mem_i,
    input  wire [1:0]  pc_sel_decision_mem_i,
    
    input  wire [4:0]  wb_rd_addr_i,
    input  wire        wb_reg_write_i,
    
    // Outputs
    output wire        pc_stall_o,
    output wire        if_id_stall_o,
    output wire        if_id_flush_o,
    output wire        id_ex_stall_o,
    output wire        id_ex_flush_o,
    output wire [1:0]  forward_a_select_o,
    output wire [1:0]  forward_b_select_o,
    output wire [1:0]  pc_sel_final_o
);

    // 修复：确保定义了所有前向宏
    // 优先级：EX > MEM > WB > None
    assign forward_a_select_o = 
        (ex_reg_write_i && ex_rd_addr_i != 0 && 
         ex_rd_addr_i == id_rs1_addr_i && id_use_rs1_i) ? `FORWARD_EX_MEM :
        (mem_reg_write_i && mem_rd_addr_i != 0 && 
         mem_rd_addr_i == id_rs1_addr_i && id_use_rs1_i) ? `FORWARD_MEM_WB :
        (wb_reg_write_i && wb_rd_addr_i != 0 && 
         wb_rd_addr_i == id_rs1_addr_i && id_use_rs1_i) ? `FORWARD_MEM_WB : // 使用现有宏
        `FORWARD_NONE;
    
    assign forward_b_select_o = 
        (ex_reg_write_i && ex_rd_addr_i != 0 && 
         ex_rd_addr_i == id_rs2_addr_i && id_use_rs2_i) ? `FORWARD_EX_MEM :
        (mem_reg_write_i && mem_rd_addr_i != 0 && 
         mem_rd_addr_i == id_rs2_addr_i && id_use_rs2_i) ? `FORWARD_MEM_WB :
        (wb_reg_write_i && wb_rd_addr_i != 0 && 
         wb_rd_addr_i == id_rs2_addr_i && id_use_rs2_i) ? `FORWARD_MEM_WB : // 使用现有宏
        `FORWARD_NONE;
    
    // 分支冲刷信号（增强）
    assign if_id_flush_o = branch_jump_request_mem_i || 
                          (pc_sel_decision_mem_i != `PC_SEL_PC_PLUS_4);
    assign id_ex_flush_o = branch_jump_request_mem_i || 
                          (pc_sel_decision_mem_i != `PC_SEL_PC_PLUS_4);
    
    // 加载使用冒险检测
    wire load_use_hazard = ex_mem_read_i && 
                          ((id_use_rs1_i && ex_rd_addr_i == id_rs1_addr_i) ||
                           (id_use_rs2_i && ex_rd_addr_i == id_rs2_addr_i));
    
    // 暂停控制
    assign pc_stall_o = load_use_hazard || branch_jump_request_mem_i;
    assign if_id_stall_o = load_use_hazard;
    assign id_ex_stall_o = load_use_hazard;
    
    // PC选择
    assign pc_sel_final_o = pc_sel_decision_mem_i;

endmodule