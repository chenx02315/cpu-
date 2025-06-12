`include "defines.v"

module pc_logic (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall_if_i,
    input  wire        flush_if_i,
    input  wire [1:0]  pc_sel_i,
    input  wire [31:0] branch_jump_target_addr_i,
    input  wire [31:0] jalr_target_addr_i,
    
    output reg  [31:0] pc_if_o,
    output wire [31:0] pc_plus_4_if_o
);

    // PC+4计算
    assign pc_plus_4_if_o = pc_if_o + 32'd4;
    
    // PC更新逻辑
    always @(posedge clk) begin
        if (!rst_n) begin
            pc_if_o <= `RESET_PC;  // 复位PC为0
        end else if (!stall_if_i) begin
            case (pc_sel_i)
                `PC_SEL_PC_PLUS_4: begin
                    pc_if_o <= pc_plus_4_if_o;
                end
                `PC_SEL_BRANCH_JUMP: begin
                    pc_if_o <= branch_jump_target_addr_i;
                    $display("[PC_LOGIC] 分支/跳转: PC=0x%08x -> 0x%08x", 
                            pc_if_o, branch_jump_target_addr_i);
                end
                `PC_SEL_JALR: begin
                    pc_if_o <= jalr_target_addr_i;
                    $display("[PC_LOGIC] JALR跳转: PC=0x%08x -> 0x%08x", 
                            pc_if_o, jalr_target_addr_i);
                end
                `PC_SEL_EXCEPTION: begin
                    // 异常处理保留，暂时跳转到异常向量
                    pc_if_o <= 32'h00000004;
                end
                default: begin
                    pc_if_o <= pc_plus_4_if_o;
                end
            endcase
        end
        // stall时PC保持不变
    end
    
    // 调试输出
    always @(posedge clk) begin
        if (rst_n && !stall_if_i && pc_sel_i != `PC_SEL_PC_PLUS_4) begin
            $display("[PC_DEBUG] PC选择: %s, 新PC=0x%08x", 
                    (pc_sel_i == `PC_SEL_BRANCH_JUMP) ? "BRANCH/JUMP" :
                    (pc_sel_i == `PC_SEL_JALR) ? "JALR" :
                    (pc_sel_i == `PC_SEL_EXCEPTION) ? "EXCEPTION" : "UNKNOWN",
                    pc_if_o);
        end
    end

endmodule
