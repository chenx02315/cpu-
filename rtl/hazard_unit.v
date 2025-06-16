`include "defines.v"

module hazard_unit (
    // Inputs from ID stage
    input wire [4:0] id_rs1_addr_i,
    input wire [4:0] id_rs2_addr_i,
    input wire       id_mem_read_i,     // ID阶段是否为Load指令
    input wire       id_use_rs1_i,      // 新增：ID阶段指令是否使用rs1
    input wire       id_use_rs2_i,      // 新增：ID阶段指令是否使用rs2

    // Inputs from EX stage (actually from ID/EX register)
    input wire [4:0] ex_rd_addr_i,
    input wire       ex_reg_write_i,
    input wire       ex_mem_read_i,     // EX阶段是否为Load指令 (用于EX->ID的数据冒险)
    input wire       ex_is_nop_i,       // 新增：EX阶段指令是否为NOP

    // Inputs from MEM stage (actually from EX/MEM register)
    input wire [4:0] mem_rd_addr_i,
    input wire       mem_reg_write_i,
    input wire       mem_is_nop_i,      // 新增：MEM阶段指令是否为NOP
    // input wire    mem_mem_read_i, // MEM阶段是否为Load指令 (通常不直接用于前推决策，而是WB结果)

    // Inputs from WB stage (actually from MEM/WB register)
    input wire [4:0] wb_rd_addr_i,      // WB阶段的目标寄存器地址
    input wire       wb_reg_write_i,    // WB阶段是否有寄存器写操作

    // Inputs for branch/jump hazard control
    input wire       branch_jump_request_mem_i, // MEM阶段发出的分支/跳转请求
    input wire [1:0] pc_sel_decision_mem_i,   // MEM阶段决定的PC选择信号

    // Outputs for pipeline control
    output reg       pc_stall_o,
    output reg       if_id_stall_o,
    output reg       if_id_flush_o,
    output reg       id_ex_stall_o,
    output reg       id_ex_flush_o,

    // Outputs for forwarding
    output reg [1:0] forward_a_select_o,
    output reg [1:0] forward_b_select_o,

    // Output for final PC selection
    output reg [1:0] pc_sel_final_o
);

    // Internal logic for data hazards and forwarding
    always @(*) begin
        // Default assignments
        forward_a_select_o = `FORWARD_NONE; // Changed from FORWARD_NO
        forward_b_select_o = `FORWARD_NONE; // Changed from FORWARD_NO
        pc_stall_o = 1'b0;
        if_id_stall_o = 1'b0;
        id_ex_stall_o = 1'b0; // Usually for load-use hazard
        id_ex_flush_o = 1'b0; // Usually for taken branches
        if_id_flush_o = 1'b0; // Usually for taken branches, flushes IF

        // Data Hazard Detection and Forwarding Logic

        // EX/MEM stage to EX stage forwarding (ALU result to next instruction's ALU input)
        // If EX/MEM stage is writing to a register (ex_reg_write_i)
        // and its destination register (ex_rd_addr_i) is not x0
        // and it matches one of ID stage's source registers (id_rs1_addr_i or id_rs2_addr_i)
        if (ex_reg_write_i && (ex_rd_addr_i != `REG_ZERO) && !ex_is_nop_i) begin // 检查EX级是否为NOP
            if (id_use_rs1_i && (ex_rd_addr_i == id_rs1_addr_i)) begin // 检查ID级是否用rs1
                forward_a_select_o = `FORWARD_EX_MEM;
            end
            if (id_use_rs2_i && (ex_rd_addr_i == id_rs2_addr_i)) begin // 检查ID级是否用rs2
                forward_b_select_o = `FORWARD_EX_MEM;
            end
        end

        // MEM/WB stage to EX stage forwarding (Load result or older ALU result)
        // If MEM/WB stage is writing to a register (mem_reg_write_i)
        // and its destination register (mem_rd_addr_i) is not x0
        // and it matches one of ID stage's source registers
        // AND that register is not already being forwarded from EX/MEM (EX/MEM has higher priority)
        if (mem_reg_write_i && (mem_rd_addr_i != `REG_ZERO) && !mem_is_nop_i) begin // 检查MEM级是否为NOP
            if (id_use_rs1_i && (mem_rd_addr_i == id_rs1_addr_i)) begin // 检查ID级是否用rs1
                // Only forward from MEM/WB if not already covered by EX/MEM forwarding
                if (forward_a_select_o == `FORWARD_NONE) begin // Changed from FORWARD_NO
                    forward_a_select_o = `FORWARD_MEM_WB;
                end
            end
            if (id_use_rs2_i && (mem_rd_addr_i == id_rs2_addr_i)) begin // 检查ID级是否用rs2
                // Only forward from MEM/WB if not already covered by EX/MEM forwarding
                if (forward_b_select_o == `FORWARD_NONE) begin // Changed from FORWARD_NO
                    forward_b_select_o = `FORWARD_MEM_WB;
                end
            end
        end
        
        // Load-Use Hazard Detection (EX stage is a LOAD, and ID stage uses its result)
        // If the instruction in EX stage (from ID/EX reg) is a LOAD (ex_mem_read_i)
        // and its destination register (ex_rd_addr_i) matches either rs1 or rs2 of the ID stage instruction
        // then stall PC, IF/ID, and insert a NOP (bubble) into ID/EX by stalling ID/EX but not IF/ID.
        // More accurately, stall PC and IF/ID, and let ID/EX stall propagate.
        if (ex_mem_read_i && ex_reg_write_i && (ex_rd_addr_i != `REG_ZERO) && !ex_is_nop_i &&
            ( (id_use_rs1_i && (ex_rd_addr_i == id_rs1_addr_i)) || 
              (id_use_rs2_i && (ex_rd_addr_i == id_rs2_addr_i)) )
          ) begin
            pc_stall_o      = 1'b1;       // Stall PC
            if_id_stall_o   = 1'b1;       // Stall IF/ID register
            id_ex_stall_o   = 1'b1;       // Stall ID/EX register (effectively inserts bubble after ID)
                                          // This also means the hazard unit itself will see the same ID stage instruction next cycle
                                          // unless flushed.
            // To insert a bubble, we need to ensure ID/EX gets a NOP.
            // One way is to stall ID/EX and let EX continue with what it has (which will be the load).
            // The critical part is that the ID stage instruction (the one using the load result)
            // must not proceed to EX until the load data is available (typically after MEM stage).
            // So, PC and IF/ID must stall. ID stage effectively re-evaluates.
            // The forwarding logic will handle providing the data once it's ready from MEM/WB.
            // The stall here is to wait for the data to be available for forwarding.
            // A simpler way for load-use: stall PC, IF/ID, and ID/EX.
            // This freezes the front-end of the pipeline for one cycle.
            // The load instruction proceeds to MEM. Next cycle, its result can be forwarded from MEM/WB.
            
            // Corrected Load-Use Stall:
            // Stall PC, IF/ID. This keeps the dependent instruction in ID.
            // The load instruction in EX will proceed to MEM.
            // Next cycle, the dependent instruction (still in ID) will see the load's rd in MEM stage,
            // and forwarding from MEM/WB will occur.
            // No, this is not quite right. The dependent instruction *must not enter EX*.
            // So, if ID has a dependency on a load in EX:
            // - PC must stall (pc_stall_o = 1)
            // - IF/ID must stall (if_id_stall_o = 1)
            // - ID/EX must be flushed or get a NOP (id_ex_flush_o = 1, or specific NOP insertion logic)
            //   A common approach is to stall the earlier stages and flush the instruction in ID
            //   so it becomes a NOP in ID/EX.
            // Let's use the common stall pattern:
            pc_stall_o      = 1'b1;
            if_id_stall_o   = 1'b1;
            id_ex_stall_o   = 1'b1; // This will make the current ID instruction re-evaluate next cycle
                                    // against the load now in MEM.
            // Crucially, the forwarding logic above should still operate.
            // If we stall ID/EX, the current ID instruction doesn't go to EX.
            // The load in EX goes to MEM.
            // Next cycle, ID instruction (still same) sees load's rd in MEM. Forwarding from MEM/WB happens.
            // This seems like a 1-cycle stall.
        end


        // Control Hazard Detection (Branch taken in MEM stage)
        // If a branch/jump request is made from MEM stage
        if (branch_jump_request_mem_i) begin
            // Flush instructions in IF and ID stages
            // The instruction in EX stage (which was fetched after the branch)
            // also needs to be flushed. This is typically handled by flushing ID/EX.
            if_id_flush_o = 1'b1; // Flush instruction in IF/ID register (becomes NOP)
            id_ex_flush_o = 1'b1; // Flush instruction in ID/EX register (becomes NOP)
                                  // PC will be updated by pc_logic based on pc_sel_final_o
        end

        // Final PC selection logic
        // Default is PC+4. If a branch/jump is taken in MEM, override.
        pc_sel_final_o = `PC_SEL_PC_PLUS_4; // Default
        if (branch_jump_request_mem_i) begin
            pc_sel_final_o = pc_sel_decision_mem_i; // Use decision from MEM stage
        end

    end

    // Debug: Display hazard unit state when relevant
    // ... (optional debug display) ...

endmodule