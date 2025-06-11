`include "defines.v"

module if_stage (
    input  wire [31:0] pc_i,
    input  wire [31:0] pc_plus_4_i,
    input  wire [31:0] instruction_i,
    
    output wire [31:0] instr_addr_o,
    output wire [31:0] pc_if_id_o,
    output wire [31:0] pc_plus_4_if_id_o,
    output wire [31:0] instruction_if_id_o
);

    // IF阶段直接传递信号
    assign instr_addr_o = pc_i;
    assign pc_if_id_o = pc_i;
    assign pc_plus_4_if_id_o = pc_plus_4_i;
    assign instruction_if_id_o = instruction_i;

endmodule
