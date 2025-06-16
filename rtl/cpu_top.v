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
    
    // 新增调试逻辑：监控 lw 指令的控制信号传递
    // 当 lw 指令 (PC=0x198 或 PC=0x19c) 在 ID 阶段的输出 (即 ID/EX 寄存器的输入)
    always @(*) begin
        if (pc_id == 32'h00000198 || pc_id == 32'h0000019c) begin
            $display("[CPU_TOP_ID_OUT_LW] PC_ID=0x%h, Instr=0x%h", pc_id, instruction_id);
            $display("    ID_Out->IDEX_In: opcode=0x%x, rd=%d, mem_read=%b, reg_write=%b, mem_to_reg=%b, alu_op=0x%x, alu_src=%b",
                     opcode_id, rd_addr_id, mem_read_id, reg_write_id, mem_to_reg_id, alu_op_id, alu_src_id);
        end
    end

    // 当 lw 指令 (PC=0x198 或 PC=0x19c) 在 ID/EX 寄存器的输出 (即 EX 阶段的输入)
    always @(*) begin
        if (pc_ex_from_reg == 32'h00000198 || pc_ex_from_reg == 32'h0000019c) begin
            $display("[CPU_TOP_IDEX_OUT_LW] PC_EX=0x%h", pc_ex_from_reg);
            $display("    IDEX_Out->EX_In: opcode=0x%x, rd=%d, mem_read=%b, reg_write=%b, mem_to_reg=%b, alu_op=0x%x, alu_src=%b",
                     opcode_id_ex, rd_addr_id_ex, mem_read_id_ex, reg_write_id_ex, mem_to_reg_id_ex, alu_op_id_ex, alu_src_id_ex);
        end
    end

    // 当 lw 指令 (PC=0x198 或 PC=0x19c) 在 EX/MEM 寄存器的输出 (即 MEM 阶段的输入)
    always @(*) begin
        if (pc_ex_mem_reg == 32'h00000198 || pc_ex_mem_reg == 32'h0000019c) begin
            $display("[CPU_TOP_EXMEM_OUT_LW] PC_MEM=0x%h", pc_ex_mem_reg);
            $display("    EXMEM_Out->MEM_In: opcode=0x%x, rd=%d, mem_read=%b, reg_write=%b, mem_to_reg=%b",
                     opcode_ex_mem_reg, rd_addr_ex_mem_reg, mem_read_ex_mem_reg, reg_write_ex_mem_reg, mem_to_reg_ex_mem_reg);
        end
    end

    // 当 lw 指令 (rd=30 或 rd=29) 在 MEM/WB 寄存器的输出 (即 WB 阶段的输入)
    // 注意：这里我们用 rd_addr 和期望的 mem_to_reg 值来识别 lw 指令，因为 PC 可能不直接传递到此点
    always @(*) begin
        // 检查是否可能是我们关心的 lw 指令准备写回
        if ((rd_addr_mem_wb == 5'd30 || rd_addr_mem_wb == 5'd29)) begin
             // 并且其控制信号表明它是一个load的结果
            if (mem_to_reg_wb_reg_out == `MEM_TO_REG_MEM || reg_write_mem_wb == 1'b1) begin // 稍微放宽条件以便捕获
                $display("[CPU_TOP_MEMWB_OUT_LW] WB_In_RD=%d (PC_plus_4_MEM_WB=0x%h - indicative)", rd_addr_mem_wb, pc_plus_4_mem_wb);
                $display("    MEMWB_Out->WB_In: reg_write=%b, mem_to_reg=%b",
                         reg_write_mem_wb, mem_to_reg_wb_reg_out);
                $display("    MEMWB_Out_Data: ex_result=0x%h, mem_data=0x%h", ex_result_mem_wb, mem_read_data_mem_wb);
            end
        end
    end

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
    
    // 调试：监控 ID 阶段输出的立即数 (针对 BNE @ 0x210)
    // BUG 分析提示 (基于最新日志):

    // 根本问题1: `if_id_register.v` 输出的 `instruction_id` 可能不稳定。
    //   - 日志显示，对于 PC=0x210 处的指令 `0x14029463` (XOR 指令, opcode 0x33)，
    //     `id_stage` 输出的 `immediate_id` 从 `0x144` 变为 `0x148`。
    //   - 这种变化意味着 `immediate_id` 的第2位改变，这通常对应于B型立即数中源指令的 `instruction_id[9]` 位的改变。
    //   - 这强烈暗示 `if_id_register.v` 输出的 `instruction_id` (特别是bit 9，也可能包括其他位如操作码位 `[6:0]`) 
    //     在单个时钟周期内是不稳定的。
    //   - 解决方案: 检查 `if_id_register.v` 的逻辑，确保其输出 `instruction_id_o` 在整个时钟周期内是稳定的，
    //     除非受到有效的 `stall_i` 或 `flush_i` 控制。同时检查其输入 `instruction_if_i` 是否稳定。

    // 根本问题2: `id_stage.v` 内部操作码解码错误，可能由不稳定的 `instruction_id` 引发或加剧。
    //   - Testbench日志 `[ID] PC=0x00000210, 指令=0x14029463, opcode=0x63, rd=x 8` 表明：
    //     当 `id_stage` 的输入 `instruction_i` (即此处的 `instruction_id`) 为 `0x14029463` (实际是XOR, opcode 0x33) 时，
    //     `id_stage` 的输出 `opcode_ex_o` (即此处的 `opcode_id`) 却错误地变成了 `0x63` (OPCODE_BRANCH)。
    //   - 如果 `instruction_id[6:0]` (操作码位) 不稳定，`id_stage` 可能锁存了一个错误的操作码。
    //   - 解决方案: 在确保 `instruction_id` 稳定后，检查 `id_stage.v` 中 `opcode_ex_o` 的赋值逻辑。
    //     它应该直接且正确地来源于稳定的 `instruction_i[6:0]`。

    // 根本问题3: `id_stage.v` 输出的 `immediate_id` 不正确。
    //   - 即使 `id_stage` 错误地将操作码识别为 `0x63` (BRANCH)，如果其内部 `immediate_generator` 模块
    //     (如 `immediate_generator.v`) 被正确地提供了指令 `0x14029463` 和操作码 `0x63`，
    //     生成的B型立即数应为 `0x290`。
    //   - 然而，日志中 `immediate_id` 为 `0x144/0x148`。这表明 `id_stage` 内部传递给其
    //     `immediate_generator` 的指令位可能受到了 `instruction_id` 不稳定性的影响，或者 `id_stage`
    //     有其自己错误的立即数生成逻辑，或者其连接到 `immediate_generator` 的方式有问题。
    //   - 解决方案: 在确保 `instruction_id` 稳定且操作码解码正确后，检查 `id_stage.v` 如何生成/传递 `immediate_ex_o`。

    always @(*) begin
        if (pc_id == 32'h00000210 && opcode_id == `OPCODE_BRANCH) begin // This condition is met due to id_stage error
            $display("[CPU_TOP_ID_OUT_BNE_0x210] PC_ID=0x%h, Instr_ID_Input=0x%h, Opcode_ID_Output=0x%x, Imm_ID_Output=0x%h (Test expects imm 0x14A; if 0x14029463 were BNE, imm would be 0x290)",
                     pc_id, instruction_id, opcode_id, immediate_id);
        end
    end

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

    // 调试：监控 ID/EX 寄存器输出的立即数 (针对 BNE @ 0x210)
    always @(*) begin
        if (pc_ex_from_reg == 32'h00000210 && opcode_id_ex == `OPCODE_BRANCH) begin
            $display("[CPU_TOP_IDEX_OUT_BNE_0x210] PC_EX_FROM_REG=0x%h, IMM_ID_EX=0x%h (Expected 0x14A), OPCODE=0x%x",
                     pc_ex_from_reg, immediate_id_ex, opcode_id_ex);
        end
    end
    
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

    // 调试：监控 EX 阶段输出的立即数 (即 EX/MEM 寄存器输入，针对 BNE @ 0x210)
    always @(*) begin
        // pc_ex_mem 是 EX 阶段的 PC 输出, opcode_ex_mem 是 EX 阶段的 opcode 输出
        if (pc_ex_mem == 32'h00000210 && opcode_ex_mem == `OPCODE_BRANCH) begin
            $display("[CPU_TOP_EX_OUT_BNE_0x210] PC_EX_MEM=0x%h, IMM_EX_MEM=0x%h (Expected 0x14A), OPCODE=0x%x",
                     pc_ex_mem, immediate_ex_mem, opcode_ex_mem);
        end
    end
    
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
        .opcode_mem_o(opcode_ex_mem_reg), // 修正：连接到 wire opcode_ex_mem_reg
        .mem_read_mem_o(mem_read_ex_mem_reg),
        .mem_write_mem_o(mem_write_ex_mem_reg),
        .branch_ctrl_mem_o(branch_ctrl_ex_mem_reg),
        .reg_write_mem_o(reg_write_ex_mem_reg),
        .mem_to_reg_mem_o(mem_to_reg_ex_mem_reg)
    );
    
    // 新增调试：监控特定BNE指令在MEM阶段的输入 (EX/MEM 寄存器输出)
    always @(*) begin
        if (pc_ex_mem_reg == 32'h00000210 && opcode_ex_mem_reg == `OPCODE_BRANCH) begin // BNE指令在0x210
            $display("[CPU_TOP_MEM_INPUT_BNE_0x210] PC_EX_MEM_REG=0x%h, IMM_EX_MEM_REG=0x%h (Expected 0x14A), OPCODE=0x%x",
                     pc_ex_mem_reg, immediate_ex_mem_reg, opcode_ex_mem_reg);
            $display("    MEM Stage will calculate target as: 0x%h + 0x%h = 0x%h",
                     pc_ex_mem_reg, immediate_ex_mem_reg, pc_ex_mem_reg + immediate_ex_mem_reg);
        end
    end

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