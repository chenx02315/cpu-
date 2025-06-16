`include "defines.v"

module cpu_top (
    input wire clk,
    input wire rst_n,
    
    // 为testbench提供的调试接口
    output wire [31:0] pc_if,
    output wire [31:0] instruction_if
);

    // PC Logic signals
    wire [31:0] pc_if_internal;
    wire [31:0] pc_plus_4_if;
    wire [31:0] branch_jump_target_from_mem;
    wire [31:0] jalr_target_from_mem;
    wire [1:0]  pc_sel_final_hazard;
    
    // IF Stage signals
    wire [31:0] instr_addr_if;
    wire [31:0] instruction_if_internal;
    wire [31:0] pc_if_to_reg;
    wire [31:0] pc_plus_4_if_to_reg;
    wire [31:0] instruction_if_to_reg;
    
    // 导出调试信号
    assign pc_if = pc_if_internal;
    assign instruction_if = instruction_if_internal;
    
    // IF/ID Register signals
    wire [31:0] pc_id;
    wire [31:0] pc_plus_4_id;
    wire [31:0] instruction_id;
    
    // ID Stage signals
    wire [4:0]  rs1_addr_rf;
    wire [4:0]  rs2_addr_rf;
    wire [31:0] rs1_data_rf;
    wire [31:0] rs2_data_rf;
    wire [31:0] operand_a_id;
    wire [31:0] operand_b_id;
    wire [31:0] reg2_data_id;
    wire [31:0] immediate_id;
    wire [4:0]  rs1_addr_id;
    wire [4:0]  rs2_addr_id;
    wire [4:0]  rd_addr_id;
    wire [2:0]  funct3_id;
    wire [6:0]  funct7_id;
    wire [6:0]  opcode_id;
    wire [3:0]  alu_op_id;
    wire        alu_src_id;
    wire        mem_read_id;
    wire        mem_write_id;
    wire        branch_id;
    wire        reg_write_id;
    wire [1:0]  mem_to_reg_id;
    
    // ID/EX Register signals
    wire [31:0] pc_for_id_ex_reg;
    wire [31:0] pc_plus_4_for_id_ex_reg;
    wire [31:0] pc_ex_from_reg;
    wire [31:0] pc_plus_4_ex_from_reg;
    wire [31:0] operand_a_id_ex;
    wire [31:0] operand_b_id_ex;
    wire [31:0] reg2_data_id_ex;
    wire [31:0] immediate_id_ex;
    wire [4:0]  rs1_addr_id_ex;
    wire [4:0]  rs2_addr_id_ex;
    wire [4:0]  rd_addr_id_ex;
    wire [2:0]  funct3_id_ex;
    wire [6:0]  funct7_id_ex;
    wire [6:0]  opcode_id_ex;
    wire [3:0]  alu_op_id_ex;
    wire        alu_src_id_ex;
    wire        mem_read_id_ex;
    wire        mem_write_id_ex;
    wire        branch_id_ex;
    wire        reg_write_id_ex;
    wire [1:0]  mem_to_reg_id_ex;
    wire [1:0]  forward_a_select_ex_reg;
    wire [1:0]  forward_b_select_ex_reg;
    
    // EX Stage signals
    wire [31:0] pc_ex_mem;
    wire [31:0] pc_plus_4_ex_mem;
    wire [31:0] ex_result_ex_mem;
    wire        zero_flag_ex_mem;
    wire [31:0] reg2_data_ex_mem;
    wire [31:0] immediate_ex_mem;
    wire [4:0]  rd_addr_ex_mem;
    wire [2:0]  funct3_ex_mem;
    wire [6:0]  opcode_ex_mem;
    wire        mem_read_ex_mem;
    wire        mem_write_ex_mem;
    wire        branch_ctrl_ex_mem;
    wire        reg_write_ex_mem;
    wire [1:0]  mem_to_reg_ex_mem;
    
    // EX/MEM Register signals
    wire [31:0] pc_ex_mem_reg;
    wire [31:0] pc_plus_4_ex_mem_reg;
    wire [31:0] ex_result_ex_mem_reg;
    wire        zero_flag_ex_mem_reg;
    wire [31:0] reg2_data_ex_mem_reg;
    wire [31:0] immediate_ex_mem_reg;
    wire [4:0]  rd_addr_ex_mem_reg;
    wire [2:0]  funct3_ex_mem_reg;
    wire [6:0]  opcode_ex_mem_reg;
    wire        mem_read_ex_mem_reg;
    wire        mem_write_ex_mem_reg;
    wire        branch_ctrl_ex_mem_reg;
    wire        reg_write_ex_mem_reg;
    wire [1:0]  mem_to_reg_ex_mem_reg;
    
    // MEM Stage signals
    wire [31:0] data_mem_read_data;
    wire        branch_jump_request_mem;
    wire [1:0]  pc_sel_decision_mem;
    
    // MEM/WB Register signals
    wire [31:0] pc_plus_4_mem_wb;
    wire [31:0] mem_read_data_mem_wb;
    wire [31:0] ex_result_mem_wb;
    wire [4:0]  rd_addr_mem_wb;
    wire        reg_write_mem_wb;
    wire [1:0]  mem_to_reg_from_mem_stage; // Renamed wire from mem_stage output
    wire [1:0]  mem_to_reg_wb_reg_out;     // New wire for MEM/WB register output
    
    // WB Stage signals
    wire        reg_write_wb;
    wire [4:0]  rd_addr_wb;
    wire [31:0] write_data_wb;
    
    // Hazard Unit signals
    wire        if_id_flush_hazard;
    wire        if_id_stall_hazard;
    wire        id_ex_flush_hazard;
    wire        id_ex_stall_hazard;
    wire        pc_stall_hazard;
    wire [1:0]  forward_a_select_hazard_out; // Renamed from forward_a_select_hazard
    wire [1:0]  forward_b_select_hazard_out; // Renamed from forward_b_select_hazard
    
    // Forwarding signals for ID/EX register
    wire [1:0]  forward_a_select_to_idex;
    wire [1:0]  forward_b_select_to_idex;

    // Forwarding signals
    wire [31:0] forward_data_a;
    wire [31:0] forward_data_b;
    
    // 修复：正确的前推数据选择
    // EX/MEM阶段前推：使用EX阶段的ALU结果
    // MEM/WB阶段前推：使用WB阶段的写回数据
    assign forward_data_a = ex_result_ex_mem_reg;  // EX/MEM前推数据
    assign forward_data_b = write_data_wb;         // MEM/WB前推数据
    
    // Instantiate PC Logic
    pc_logic u_pc_logic (
        .clk(clk),
        .rst_n(rst_n),
        .stall_if_i(pc_stall_hazard),
        .flush_if_i(1'b0),
        .pc_sel_i(pc_sel_final_hazard),
        .branch_jump_target_addr_i(branch_jump_target_from_mem),
        .jalr_target_addr_i(jalr_target_from_mem),
        .pc_if_o(pc_if_internal),
        .pc_plus_4_if_o(pc_plus_4_if)
    );
    
    // Instantiate Instruction Memory
    instruction_memory u_instruction_memory (
        .addr_i(pc_if_internal),
        .instr_o(instruction_if_internal)
    );
    
    // Instantiate IF Stage
    if_stage u_if_stage (
        .pc_i(pc_if_internal),
        .pc_plus_4_i(pc_plus_4_if),
        .instruction_i(instruction_if_internal),
        .instr_addr_o(instr_addr_if),
        .pc_if_id_o(pc_if_to_reg),
        .pc_plus_4_if_id_o(pc_plus_4_if_to_reg),
        .instruction_if_id_o(instruction_if_to_reg)
    );
    
    // Instantiate IF/ID Register
    if_id_register u_if_id_reg (
        .clk(clk),
        .rst_n(rst_n),
        .stall_i(if_id_stall_hazard),
        .flush_i(if_id_flush_hazard),
        .pc_if_i(pc_if_to_reg),
        .pc_plus_4_if_i(pc_plus_4_if_to_reg),
        .instruction_if_i(instruction_if_to_reg),
        .pc_id_o(pc_id),
        .pc_plus_4_id_o(pc_plus_4_id),
        .instruction_id_o(instruction_id)
    );
    
    // Instantiate ID Stage - 修复：添加时钟和复位信号
    id_stage u_id_stage (
        .clk(clk),                              // 修复：连接时钟
        .rst_n(rst_n),                          // 修复：连接复位
        .pc_i(pc_id),
        .pc_plus_4_i(pc_plus_4_id),
        .instruction_i(instruction_id),
        .rs1_addr_rf_o(rs1_addr_rf),
        .rs2_addr_rf_o(rs2_addr_rf),
        .rs1_data_i(rs1_data_rf),
        .rs2_data_i(rs2_data_rf),
        .pc_ex_o(pc_for_id_ex_reg),
        .pc_plus_4_ex_o(pc_plus_4_for_id_ex_reg),
        .operand_a_ex_o(operand_a_id),
        .operand_b_ex_o(operand_b_id),
        .reg2_data_ex_o(reg2_data_id),
        .rs1_addr_ex_o(rs1_addr_id),
        .rs2_addr_ex_o(rs2_addr_id),
        .rd_addr_ex_o(rd_addr_id),
        .funct3_ex_o(funct3_id),
        .funct7_ex_o(funct7_id),
        .opcode_ex_o(opcode_id),
        .immediate_ex_o(immediate_id),
        .mem_to_reg_ex_o(mem_to_reg_id),
        .reg_write_ex_o(reg_write_id),
        .branch_ex_o(branch_id),
        .mem_write_ex_o(mem_write_id),
        .mem_read_ex_o(mem_read_id),
        .alu_src_ex_o(alu_src_id),
        .alu_op_ex_o(alu_op_id)
    );
    
    // Instantiate Register File
    register_file u_register_file (
        .clk(clk),
        .rst_n(rst_n),
        .rs1_addr_i(rs1_addr_rf),
        .rs2_addr_i(rs2_addr_rf),
        .rs1_data_o(rs1_data_rf),
        .rs2_data_o(rs2_data_rf),
        .reg_write_i(reg_write_wb),
        .rd_addr_i(rd_addr_wb),
        .write_data_i(write_data_wb)
    );
    
    // Instantiate ID/EX Register
    id_ex_register u_id_ex_register (
        .clk(clk),
        .rst_n(rst_n),
        .stall_i(id_ex_stall_hazard),
        .flush_i(id_ex_flush_hazard),
        .pc_id_i(pc_for_id_ex_reg),
        .pc_plus_4_id_i(pc_plus_4_for_id_ex_reg),
        .operand_a_id_i(operand_a_id),
        .operand_b_id_i(operand_b_id),
        .reg2_data_id_i(reg2_data_id),
        .immediate_id_i(immediate_id),
        .rs1_addr_id_i(rs1_addr_id),
        .rs2_addr_id_i(rs2_addr_id),
        .rd_addr_id_i(rd_addr_id),
        .funct3_id_i(funct3_id),
        .funct7_id_i(funct7_id),
        .opcode_id_i(opcode_id),
        .alu_op_id_i(alu_op_id),
        .alu_src_id_i(alu_src_id),
        .mem_read_id_i(mem_read_id),
        .mem_write_id_i(mem_write_id),
        .branch_id_i(branch_id),
        .reg_write_id_i(reg_write_id),
        .mem_to_reg_id_i(mem_to_reg_id),
        .forward_a_select_id_i(forward_a_select_to_idex), // Connect to hazard unit output
        .forward_b_select_id_i(forward_b_select_to_idex), // Connect to hazard unit output
        .pc_ex_o(pc_ex_from_reg),
        .pc_plus_4_ex_o(pc_plus_4_ex_from_reg),
        .operand_a_ex_o(operand_a_id_ex),
        .operand_b_ex_o(operand_b_id_ex),
        .reg2_data_ex_o(reg2_data_id_ex),
        .immediate_ex_o(immediate_id_ex),
        .rs1_addr_ex_o(rs1_addr_id_ex),
        .rs2_addr_ex_o(rs2_addr_id_ex),
        .rd_addr_ex_o(rd_addr_id_ex),
        .funct3_ex_o(funct3_id_ex),
        .funct7_ex_o(funct7_id_ex),
        .opcode_ex_o(opcode_id_ex),
        .alu_op_ex_o(alu_op_id_ex),
        .alu_src_ex_o(alu_src_id_ex),
        .mem_read_ex_o(mem_read_id_ex),
        .mem_write_ex_o(mem_write_id_ex),
        .branch_ex_o(branch_id_ex),
        .reg_write_ex_o(reg_write_id_ex),
        .mem_to_reg_ex_o(mem_to_reg_id_ex),
        .forward_a_select_ex_o(forward_a_select_ex_reg), // Output from ID/EX reg
        .forward_b_select_ex_o(forward_b_select_ex_reg)  // Output from ID/EX reg
    );
    
    // Define what constitutes a NOP for hazard detection purposes
    wire ex_is_effectively_nop = (opcode_id_ex == `OPCODE_IMM && rd_addr_id_ex == `REG_ZERO && rs1_addr_id_ex == `REG_ZERO && immediate_id_ex == 32'd0) || 
                                 (!reg_write_id_ex && !mem_read_id_ex && !mem_write_id_ex && !branch_id_ex);
    wire mem_is_effectively_nop = (opcode_ex_mem_reg == `OPCODE_IMM && rd_addr_ex_mem_reg == `REG_ZERO) || 
                                 (!reg_write_ex_mem_reg && !mem_read_ex_mem_reg && !mem_write_ex_mem_reg && !branch_ctrl_ex_mem_reg);

    // Instantiate Hazard Unit - 修复：添加缺少的端口连接
    hazard_unit u_hazard_unit (
        .id_rs1_addr_i(rs1_addr_rf),
        .id_rs2_addr_i(rs2_addr_rf),
        .id_mem_read_i(mem_read_id),
        .id_use_rs1_i(opcode_id != `OPCODE_LUI && opcode_id != `OPCODE_AUIPC && opcode_id != `OPCODE_JAL),
        .id_use_rs2_i(opcode_id == `OPCODE_ARITH || opcode_id == `OPCODE_BRANCH || opcode_id == `OPCODE_STORE),
        .ex_rd_addr_i(rd_addr_id_ex),
        .ex_reg_write_i(reg_write_id_ex),
        .ex_mem_read_i(mem_read_id_ex),
        .ex_is_nop_i(ex_is_effectively_nop),
        .mem_rd_addr_i(rd_addr_ex_mem_reg),
        .mem_reg_write_i(reg_write_ex_mem_reg),
        .mem_is_nop_i(mem_is_effectively_nop),
        .branch_jump_request_mem_i(branch_jump_request_mem),
        .pc_sel_decision_mem_i(pc_sel_decision_mem),
        .wb_rd_addr_i(rd_addr_mem_wb),
        .wb_reg_write_i(reg_write_mem_wb),
        .pc_stall_o(pc_stall_hazard),
        .if_id_stall_o(if_id_stall_hazard),
        .if_id_flush_o(if_id_flush_hazard),
        .id_ex_stall_o(id_ex_stall_hazard),
        .id_ex_flush_o(id_ex_flush_hazard),
        .forward_a_select_o(forward_a_select_to_idex),
        .forward_b_select_o(forward_b_select_to_idex),
        .pc_sel_final_o(pc_sel_final_hazard)
    );

    // 关键调试：监控前推信号传递 - 增强版
    always @(*) begin
        // 监控SUB指令的前推信号传递
        if (rs1_addr_rf == 5'd7 && rs2_addr_rf == 5'd8 && opcode_id == 7'h33) begin // This is for instruction in ID stage
            $display("========================================");
            $display("[CPU_TOP_ENHANCED] SUB指令 (in ID) 前推信号传递监控:");
            $display("  PC_ID: 0x%08x", pc_id);
            $display("  SUB指令: rs1(x7)=%d, rs2(x8)=%d", rs1_addr_rf, rs2_addr_rf);
            $display("  冒险单元输出 (for ID stage instr): forward_a=%d, forward_b=%d", 
                    forward_a_select_to_idex, forward_b_select_to_idex);
            $display("========================================");
        end
    end
    
    // Instantiate EX Stage (包含ALU、乘法器和前推逻辑) - 修复：添加缺少的时钟和复位信号
    ex_stage u_ex_stage (
        .clk(clk),                                   // 修复：添加时钟信号
        .rst_n(rst_n),                              // 修复：添加复位信号
        .pc_ex_i(pc_ex_from_reg),
        .pc_plus_4_ex_i(pc_plus_4_ex_from_reg),
        .operand_a_ex_i(operand_a_id_ex),
        .operand_b_src_ex_i(operand_b_id_ex),
        .immediate_ex_i(immediate_id_ex),
        .rd_addr_ex_i(rd_addr_id_ex),
        .funct3_ex_i(funct3_id_ex),
        .funct7_ex_i(funct7_id_ex),
        .opcode_ex_i(opcode_id_ex),
        .alu_op_ex_i(alu_op_id_ex),
        .alu_src_ex_i(alu_src_id_ex),
        .mem_read_ex_i(mem_read_id_ex),
        .mem_write_ex_i(mem_write_id_ex),
        .branch_ctrl_ex_i(branch_id_ex),
        .reg_write_ex_i(reg_write_id_ex),
        .mem_to_reg_ex_i(mem_to_reg_id_ex),
        .forward_data_a_i(forward_data_a),
        .forward_data_b_i(forward_data_b),
        .forward_a_select_i(forward_a_select_ex_reg), // Use registered value
        .forward_b_select_i(forward_b_select_ex_reg), // Use registered value
        .pc_for_mem_o(pc_ex_mem),
        .pc_plus_4_mem_o(pc_plus_4_ex_mem),
        .ex_result_mem_o(ex_result_ex_mem),
        .zero_flag_mem_o(zero_flag_ex_mem),
        .reg2_data_mem_o(reg2_data_ex_mem),
        .immediate_mem_o(immediate_ex_mem),
        .rd_addr_mem_o(rd_addr_ex_mem),
        .funct3_mem_o(funct3_ex_mem),
        .opcode_mem_o(opcode_ex_mem),
        .mem_read_mem_o(mem_read_ex_mem),
        .mem_write_mem_o(mem_write_ex_mem),
        .branch_ctrl_mem_o(branch_ctrl_ex_mem),
        .reg_write_mem_o(reg_write_ex_mem),
        .mem_to_reg_mem_o(mem_to_reg_ex_mem)
    );
    
    // Instantiate EX/MEM Register - 修复：使用正确的端口名称
    ex_mem_register u_ex_mem_register (
        .clk(clk),
        .rst_n(rst_n),
        .stall_i(1'b0),
        .flush_i(1'b0),
        .pc_ex_i(pc_ex_mem),
        .pc_plus_4_ex_i(pc_plus_4_ex_mem),
        .ex_result_ex_i(ex_result_ex_mem),
        .zero_flag_ex_i(zero_flag_ex_mem),
        .reg2_data_ex_i(reg2_data_ex_mem),
        .immediate_ex_i(immediate_ex_mem),
        .rd_addr_ex_i(rd_addr_ex_mem),
        .funct3_ex_i(funct3_ex_mem),
        .opcode_ex_i(opcode_ex_mem),              // 修复：使用正确的端口名
        .mem_read_ex_i(mem_read_ex_mem),
        .mem_write_ex_i(mem_write_ex_mem),
        .branch_ctrl_ex_i(branch_ctrl_ex_mem),
        .reg_write_ex_i(reg_write_ex_mem),
        .mem_to_reg_ex_i(mem_to_reg_ex_mem),
        .pc_ex_mem_o(pc_ex_mem_reg),
        .pc_plus_4_mem_o(pc_plus_4_ex_mem_reg),
        .ex_result_mem_o(ex_result_ex_mem_reg),
        .zero_flag_mem_o(zero_flag_ex_mem_reg),
        .reg2_data_mem_o(reg2_data_ex_mem_reg),
        .immediate_ex_mem_o(immediate_ex_mem_reg),
        .rd_addr_mem_o(rd_addr_ex_mem_reg),
        .funct3_mem_o(funct3_ex_mem_reg),
        .opcode_mem_o(opcode_ex_mem_reg),        // 修复：使用正确的输出端口名
        .mem_read_mem_o(mem_read_ex_mem_reg),
        .mem_write_mem_o(mem_write_ex_mem_reg),
        .branch_ctrl_mem_o(branch_ctrl_ex_mem_reg),
        .reg_write_mem_o(reg_write_ex_mem_reg),
        .mem_to_reg_mem_o(mem_to_reg_ex_mem_reg)
    );
    
    // Instantiate Data Memory
    data_memory u_data_memory (
        .clk(clk),
        .rst_n(rst_n),
        .addr_i(ex_result_ex_mem_reg),
        .write_data_i(reg2_data_ex_mem_reg),
        .read_en_i(mem_read_ex_mem_reg),
        .write_en_i(mem_write_ex_mem_reg),
        .funct3_i(funct3_ex_mem_reg),
        .read_data_o(data_mem_read_data)    // 连接读数据输出
    );
    
    // Instantiate MEM Stage - 修复：使用正确的端口名称
    mem_stage u_mem_stage (
        .pc_ex_mem_i(pc_ex_mem_reg),
        .pc_plus_4_mem_i(pc_plus_4_ex_mem_reg),
        .ex_result_mem_i(ex_result_ex_mem_reg),
        .zero_flag_mem_i(zero_flag_ex_mem_reg),
        .reg2_data_mem_i(reg2_data_ex_mem_reg),
        .immediate_ex_mem_i(immediate_ex_mem_reg),
        .rd_addr_mem_i(rd_addr_ex_mem_reg),
        .funct3_mem_i(funct3_ex_mem_reg),
        .opcode_ex_mem_i(opcode_ex_mem_reg),
        .mem_read_mem_i(mem_read_ex_mem_reg),
        .mem_write_mem_i(mem_write_ex_mem_reg),
        .branch_ctrl_mem_i(branch_ctrl_ex_mem_reg),
        .reg_write_mem_i(reg_write_ex_mem_reg),
        .mem_to_reg_mem_i(mem_to_reg_ex_mem_reg),
        .data_mem_read_data_i(data_mem_read_data),
        
        .mem_to_reg_wb_o(mem_to_reg_from_mem_stage), // Output from mem_stage to this new wire
        .branch_jump_request_o(branch_jump_request_mem),
        .pc_sel_decision_o(pc_sel_decision_mem),
        .branch_jump_target_addr_o(branch_jump_target_from_mem),
        .jalr_target_addr_o(jalr_target_from_mem)
    );
    
    // Instantiate MEM/WB Register
    mem_wb_register u_mem_wb_register (
        .clk(clk),
        .rst_n(rst_n),
        .stall_i(1'b0), 
        .flush_i(1'b0), 
        
        .pc_plus_4_mem_i(pc_plus_4_ex_mem_reg), 
        .mem_read_data_mem_i(data_mem_read_data),
        .ex_result_mem_i(ex_result_ex_mem_reg),
        .rd_addr_mem_i(rd_addr_ex_mem_reg),
        .reg_write_mem_i(reg_write_ex_mem_reg),
        .mem_to_reg_mem_i(mem_to_reg_from_mem_stage), // Input from mem_stage (via the new wire)
        
        .pc_plus_4_wb_o(pc_plus_4_mem_wb),
        .mem_read_data_wb_o(mem_read_data_mem_wb),
        .ex_result_wb_o(ex_result_mem_wb),
        .rd_addr_wb_o(rd_addr_mem_wb),
        .reg_write_wb_o(reg_write_mem_wb),
        .mem_to_reg_wb_o(mem_to_reg_wb_reg_out) // Output to the new dedicated wire
    );
    
    // Instantiate WB Stage
    wb_stage u_wb_stage (
        .pc_plus_4_wb_i(pc_plus_4_mem_wb),
        .mem_read_data_wb_i(mem_read_data_mem_wb),
        .ex_result_wb_i(ex_result_mem_wb),
        .rd_addr_wb_i(rd_addr_mem_wb),
        .reg_write_wb_i(reg_write_mem_wb),
        .mem_to_reg_wb_i(mem_to_reg_wb_reg_out), // Input from MEM/WB register's dedicated output wire
        
        .reg_write_o(reg_write_wb),
        .rd_addr_o(rd_addr_wb),
        .write_data_o(write_data_wb)
    );

endmodule