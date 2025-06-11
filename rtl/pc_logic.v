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
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_if_o <= 32'h00000000;
            $display("[PC] 复位: PC = 0x00000000");
        end
        else if (!stall_if_i) begin  // 只有在不停顿时才更新PC
            case (pc_sel_i)
                `PC_SEL_PLUS4: begin
                    pc_if_o <= pc_plus_4_if_o;
                    $display("[PC] 正常递增: PC = 0x%08x -> 0x%08x", pc_if_o, pc_plus_4_if_o);
                end
                `PC_SEL_BRANCH: begin
                    pc_if_o <= branch_jump_target_addr_i;
                    $display("[PC] 分支跳转: PC = 0x%08x -> 0x%08x", pc_if_o, branch_jump_target_addr_i);
                end
                `PC_SEL_JALR: begin
                    pc_if_o <= jalr_target_addr_i;
                    $display("[PC] JALR跳转: PC = 0x%08x -> 0x%08x", pc_if_o, jalr_target_addr_i);
                end
                default: begin
                    pc_if_o <= pc_plus_4_if_o;
                    $display("[PC] 默认递增: PC = 0x%08x -> 0x%08x", pc_if_o, pc_plus_4_if_o);
                end
            endcase
        end
        else begin
            $display("[PC] 停顿: PC保持 = 0x%08x", pc_if_o);
        end
    end

endmodule
