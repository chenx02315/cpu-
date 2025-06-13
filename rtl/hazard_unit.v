`include "defines.v"

module hazard_unit (
    // 输入端口 - 完全匹配CPU顶层模块
    input  wire [4:0]  id_rs1_addr_i,               // ID阶段rs1地址
    input  wire [4:0]  id_rs2_addr_i,               // ID阶段rs2地址
    input  wire        id_mem_read_i,               // ID阶段内存读信号
    input  wire [4:0]  ex_rd_addr_i,                // EX阶段rd地址
    input  wire        ex_reg_write_i,              // EX阶段寄存器写信号
    input  wire        ex_mem_read_i,               // EX阶段内存读信号
    input  wire [4:0]  mem_rd_addr_i,               // MEM阶段rd地址
    input  wire        mem_reg_write_i,             // MEM阶段寄存器写信号
    input  wire [4:0]  wb_rd_addr_i,                // WB阶段rd地址
    input  wire        wb_reg_write_i,              // WB阶段寄存器写信号
    input  wire        branch_jump_request_mem_i,   // MEM阶段分支/跳转请求
    input  wire [1:0]  pc_sel_decision_mem_i,       // MEM阶段PC选择决策
    
    // 输出端口 - 完全匹配CPU顶层模块
    output wire        pc_stall_o,                  // PC停顿
    output wire        if_id_stall_o,               // IF/ID停顿
    output wire        if_id_flush_o,               // IF/ID清除
    output wire        id_ex_stall_o,               // ID/EX停顿
    output wire        id_ex_flush_o,               // ID/EX清除
    output wire [1:0]  forward_a_select_o,          // 前推A选择
    output wire [1:0]  forward_b_select_o,          // 前推B选择
    output wire [1:0]  pc_sel_final_o               // 最终PC选择
);

    // 前推逻辑 - 这是关键！
    wire forward_a_ex = (ex_reg_write_i && (ex_rd_addr_i != 5'b0) && (ex_rd_addr_i == id_rs1_addr_i));
    wire forward_b_ex = (ex_reg_write_i && (ex_rd_addr_i != 5'b0) && (ex_rd_addr_i == id_rs2_addr_i));
    
    wire forward_a_mem = (mem_reg_write_i && (mem_rd_addr_i != 5'b0) && (mem_rd_addr_i == id_rs1_addr_i) && !forward_a_ex);
    wire forward_b_mem = (mem_reg_write_i && (mem_rd_addr_i != 5'b0) && (mem_rd_addr_i == id_rs2_addr_i) && !forward_b_ex);
    
    // 前推选择信号
    assign forward_a_select_o = forward_a_ex ? `FORWARD_EX_MEM : 
                               forward_a_mem ? `FORWARD_MEM_WB : 
                               `FORWARD_NO;
                               
    assign forward_b_select_o = forward_b_ex ? `FORWARD_EX_MEM : 
                               forward_b_mem ? `FORWARD_MEM_WB : 
                               `FORWARD_NO;
    
    // Load-Use数据冒险检测
    wire load_use_hazard = ex_mem_read_i && 
                          ((ex_rd_addr_i == id_rs1_addr_i) || (ex_rd_addr_i == id_rs2_addr_i)) &&
                          (ex_rd_addr_i != 5'b0);
    
    // 控制信号输出
    assign pc_stall_o = load_use_hazard;
    assign if_id_stall_o = load_use_hazard;
    assign if_id_flush_o = branch_jump_request_mem_i;
    assign id_ex_stall_o = 1'b0;  // 暂时不使用
    assign id_ex_flush_o = branch_jump_request_mem_i || load_use_hazard;
    assign pc_sel_final_o = pc_sel_decision_mem_i;
    
    // 关键调试：监控SUB指令的前推
    always @(*) begin
        if (id_rs1_addr_i == 5'd7 && id_rs2_addr_i == 5'd8) begin
            $display("========================================");
            $display("[HAZARD_CRITICAL] SUB指令前推分析:");
            $display("  指令: SUB x4, x7, x8");
            $display("  rs1(x7)=%d, rs2(x8)=%d", id_rs1_addr_i, id_rs2_addr_i);
            $display("  EX阶段: rd=%d, reg_write=%b", ex_rd_addr_i, ex_reg_write_i);
            $display("  MEM阶段: rd=%d, reg_write=%b", mem_rd_addr_i, mem_reg_write_i);
            $display("  前推结果: forward_a=%d, forward_b=%d", forward_a_select_o, forward_b_select_o);
            $display("  前推详细检查:");
            $display("    forward_a_ex=%b (rd_ex=%d == rs1=%d)", forward_a_ex, ex_rd_addr_i, id_rs1_addr_i);
            $display("    forward_b_ex=%b (rd_ex=%d == rs2=%d)", forward_b_ex, ex_rd_addr_i, id_rs2_addr_i);
            $display("    forward_a_mem=%b (rd_mem=%d == rs1=%d)", forward_a_mem, mem_rd_addr_i, id_rs1_addr_i);
            $display("    forward_b_mem=%b (rd_mem=%d == rs2=%d)", forward_b_mem, mem_rd_addr_i, id_rs2_addr_i);
            
            // 特别关注：如果前推了错误的值
            if (forward_b_select_o != `FORWARD_NO) begin
                $display("  *** 警告：x8正在被前推！检查前推来源 ***");
                if (forward_b_ex) begin
                    $display("      x8前推来源：EX阶段 rd=%d", ex_rd_addr_i);
                end
                if (forward_b_mem) begin
                    $display("      x8前推来源：MEM阶段 rd=%d", mem_rd_addr_i);
                end
            end else begin
                $display("  ✓ x8使用寄存器文件原始值，无前推");
            end
            $display("========================================");
        end
    end

endmodule