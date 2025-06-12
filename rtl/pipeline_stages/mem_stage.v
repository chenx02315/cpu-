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
    input  wire [6:0]  opcode_ex_mem_i,
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

    // 分支判断逻辑
    reg branch_taken;
    
    always @(*) begin
        branch_taken = 1'b0;
        
        if (branch_ctrl_mem_i) begin
            case (funct3_mem_i)
                `FUNCT3_BEQ: begin
                    branch_taken = zero_flag_mem_i;
                end
                `FUNCT3_BNE: begin
                    branch_taken = ~zero_flag_mem_i;
                end
                `FUNCT3_BLT: begin
                    branch_taken = ex_result_mem_i[0];
                end
                `FUNCT3_BGE: begin
                    branch_taken = ~ex_result_mem_i[0];
                end
                `FUNCT3_BLTU: begin
                    branch_taken = ex_result_mem_i[0];
                end
                `FUNCT3_BGEU: begin
                    branch_taken = ~ex_result_mem_i[0];
                end
                default: branch_taken = 1'b0;
            endcase
        end
    end
    
    // 分支目标地址计算
    wire [31:0] branch_target_addr = pc_ex_mem_i + immediate_ex_mem_i;
    
    // JALR目标地址计算
    wire [31:0] jalr_target_addr = (ex_result_mem_i) & 32'hfffffffe;
    
    // PC选择决策
    reg [1:0] pc_sel_decision;
    
    always @(*) begin
        case (opcode_ex_mem_i)
            `OPCODE_JAL: begin
                pc_sel_decision = `PC_SEL_BRANCH_JUMP;
            end
            `OPCODE_JALR: begin
                pc_sel_decision = `PC_SEL_JALR;
            end
            `OPCODE_BRANCH: begin
                if (branch_taken) begin
                    pc_sel_decision = `PC_SEL_BRANCH_JUMP;
                end else begin
                    pc_sel_decision = `PC_SEL_PC_PLUS_4;
                end
            end
            default: begin
                pc_sel_decision = `PC_SEL_PC_PLUS_4;
            end
        endcase
    end
    
    // 分支/跳转请求生成
    wire branch_jump_request;
    assign branch_jump_request = (opcode_ex_mem_i == `OPCODE_JAL) ||
                                (opcode_ex_mem_i == `OPCODE_JALR) ||
                                (opcode_ex_mem_i == `OPCODE_BRANCH && branch_taken);
    
    // 输出信号赋值
    assign mem_to_reg_wb_o = mem_to_reg_mem_i;
    assign branch_jump_request_o = branch_jump_request;
    assign pc_sel_decision_o = pc_sel_decision;
    assign branch_jump_target_addr_o = branch_target_addr;
    assign jalr_target_addr_o = jalr_target_addr;
    
    // 调试输出
    always @(*) begin
        if (branch_ctrl_mem_i && branch_taken) begin
            $display("[MEM_DEBUG] 分支跳转: PC=0x%08x -> 0x%08x, 类型=%s", 
                    pc_ex_mem_i, branch_target_addr,
                    (funct3_mem_i == `FUNCT3_BEQ) ? "BEQ" :
                    (funct3_mem_i == `FUNCT3_BNE) ? "BNE" :
                    (funct3_mem_i == `FUNCT3_BLT) ? "BLT" :
                    (funct3_mem_i == `FUNCT3_BGE) ? "BGE" :
                    (funct3_mem_i == `FUNCT3_BLTU) ? "BLTU" :
                    (funct3_mem_i == `FUNCT3_BGEU) ? "BGEU" : "UNKNOWN");
        end
        
        if (opcode_ex_mem_i == `OPCODE_JAL) begin
            $display("[MEM_DEBUG] JAL跳转: PC=0x%08x -> 0x%08x", 
                    pc_ex_mem_i, branch_target_addr);
        end
        
        if (opcode_ex_mem_i == `OPCODE_JALR) begin
            $display("[MEM_DEBUG] JALR跳转: PC=0x%08x -> 0x%08x", 
                    pc_ex_mem_i, jalr_target_addr);
        end
    end

endmodule
