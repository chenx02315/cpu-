`include "defines.v"

module hazard_unit (
    // ID阶段信号
    input  wire [4:0]  id_rs1_addr_i,
    input  wire [4:0]  id_rs2_addr_i,
    input  wire        id_mem_read_i,
    
    // EX阶段信号
    input  wire [4:0]  ex_rd_addr_i,
    input  wire        ex_reg_write_i,
    input  wire        ex_mem_read_i,
    
    // MEM阶段信号
    input  wire [4:0]  mem_rd_addr_i,
    input  wire        mem_reg_write_i,
    input  wire        branch_jump_request_mem_i,
    input  wire [1:0]  pc_sel_decision_mem_i,
    
    // WB阶段信号
    input  wire [4:0]  wb_rd_addr_i,
    input  wire        wb_reg_write_i,
    
    // 输出控制信号
    output wire        pc_stall_o,
    output wire        if_id_stall_o,
    output wire        if_id_flush_o,
    output wire        id_ex_stall_o,
    output wire        id_ex_flush_o,
    output wire [1:0]  forward_a_select_o,
    output wire [1:0]  forward_b_select_o,
    output wire [1:0]  pc_sel_final_o
);

    // Load-Use冒险检测
    wire load_use_hazard;
    assign load_use_hazard = ex_mem_read_i && 
                           ((ex_rd_addr_i == id_rs1_addr_i && id_rs1_addr_i != 5'b0) ||
                            (ex_rd_addr_i == id_rs2_addr_i && id_rs2_addr_i != 5'b0));
    
    // 前推逻辑 - 简化版本
    wire forward_a_from_mem = mem_reg_write_i && (mem_rd_addr_i != 5'b0) && 
                             (mem_rd_addr_i == id_rs1_addr_i);
    wire forward_a_from_wb = wb_reg_write_i && (wb_rd_addr_i != 5'b0) && 
                            (wb_rd_addr_i == id_rs1_addr_i) && !forward_a_from_mem;
    
    wire forward_b_from_mem = mem_reg_write_i && (mem_rd_addr_i != 5'b0) && 
                             (mem_rd_addr_i == id_rs2_addr_i);
    wire forward_b_from_wb = wb_reg_write_i && (wb_rd_addr_i != 5'b0) && 
                            (wb_rd_addr_i == id_rs2_addr_i) && !forward_b_from_mem;
    
    // 前推选择信号
    assign forward_a_select_o = forward_a_from_mem ? 2'b01 :
                               forward_a_from_wb ? 2'b10 : 2'b00;
    assign forward_b_select_o = forward_b_from_mem ? 2'b01 :
                               forward_b_from_wb ? 2'b10 : 2'b00;
    
    // 停顿和刷新信号
    assign pc_stall_o = load_use_hazard;
    assign if_id_stall_o = load_use_hazard;
    assign if_id_flush_o = branch_jump_request_mem_i;
    assign id_ex_stall_o = 1'b0;
    assign id_ex_flush_o = load_use_hazard || branch_jump_request_mem_i;
    
    // PC选择最终决策
    assign pc_sel_final_o = branch_jump_request_mem_i ? pc_sel_decision_mem_i : `PC_SEL_PC_PLUS_4;

endmodule