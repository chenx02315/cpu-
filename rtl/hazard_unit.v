`include "defines.v"

module hazard_unit (
    input  wire [4:0]  id_rs1_addr_i,
    input  wire [4:0]  id_rs2_addr_i,
    input  wire        id_mem_read_i,
    input  wire [4:0]  ex_rs1_addr_i,        
    input  wire [4:0]  ex_rs2_addr_i,        
    input  wire [4:0]  ex_rd_addr_i,
    input  wire        ex_reg_write_i,
    input  wire        ex_mem_read_i,
    input  wire [4:0]  mem_rd_addr_i,
    input  wire        mem_reg_write_i,
    input  wire        branch_jump_request_mem_i,
    input  wire [1:0]  pc_sel_decision_mem_i,
    input  wire [4:0]  wb_rd_addr_i,
    input  wire        wb_reg_write_i,
    
    output wire        pc_stall_o,
    output wire        if_id_stall_o,
    output wire        if_id_flush_o,
    output wire        id_ex_stall_o,
    output wire        id_ex_flush_o,
    output wire [1:0]  forward_a_select_o,
    output wire [1:0]  forward_b_select_o,
    output wire [1:0]  pc_sel_final_o
);

    // Load-use hazard检测
    wire load_use_hazard = ex_mem_read_i && ex_rd_addr_i != 0 &&
                          ((ex_rd_addr_i == id_rs1_addr_i && id_rs1_addr_i != 0) ||
                           (ex_rd_addr_i == id_rs2_addr_i && id_rs2_addr_i != 0));
    
    // 控制冒险检测
    wire control_hazard = branch_jump_request_mem_i;
    
    // 流水线控制
    assign pc_stall_o = load_use_hazard;
    assign if_id_stall_o = load_use_hazard;
    assign if_id_flush_o = control_hazard;
    assign id_ex_stall_o = 1'b0;
    assign id_ex_flush_o = load_use_hazard || control_hazard;
    
    // 修复: 数据前推逻辑 - 优先级修正
    // EX-MEM前推 (优先级最高)
    wire forward_a_from_mem = (mem_reg_write_i && mem_rd_addr_i != 0 && 
                              mem_rd_addr_i == ex_rs1_addr_i);
    
    // MEM-WB前推 (优先级较低，且不与EX-MEM冲突)
    wire forward_a_from_wb = (wb_reg_write_i && wb_rd_addr_i != 0 && 
                             wb_rd_addr_i == ex_rs1_addr_i && !forward_a_from_mem);
    
    wire forward_b_from_mem = (mem_reg_write_i && mem_rd_addr_i != 0 && 
                              mem_rd_addr_i == ex_rs2_addr_i);
                              
    wire forward_b_from_wb = (wb_reg_write_i && wb_rd_addr_i != 0 && 
                             wb_rd_addr_i == ex_rs2_addr_i && !forward_b_from_mem);
    
    // 修复: 前推选择信号 - 使用正确的编码
    assign forward_a_select_o = forward_a_from_mem ? 2'b10 :    // 从EX/MEM前推
                               forward_a_from_wb ? 2'b01 :      // 从MEM/WB前推
                               2'b00;                           // 不前推
                               
    assign forward_b_select_o = forward_b_from_mem ? 2'b10 :    // 从EX/MEM前推
                               forward_b_from_wb ? 2'b01 :      // 从MEM/WB前推
                               2'b00;                           // 不前推
    
    // PC选择最终决定
    assign pc_sel_final_o = control_hazard ? pc_sel_decision_mem_i : 2'b00;

endmodule