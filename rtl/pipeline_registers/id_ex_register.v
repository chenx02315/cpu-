`include "defines.v"

module id_ex_register (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall_i,
    input  wire        flush_i,
    
    // ID stage inputs
    input  wire [31:0] pc_id_i,
    input  wire [31:0] pc_plus_4_id_i,
    input  wire [31:0] operand_a_id_i,
    input  wire [31:0] operand_b_id_i,
    input  wire [31:0] reg2_data_id_i,
    input  wire [31:0] immediate_id_i,
    input  wire [4:0]  rs1_addr_id_i,
    input  wire [4:0]  rs2_addr_id_i,
    input  wire [4:0]  rd_addr_id_i,
    input  wire [2:0]  funct3_id_i,
    input  wire [6:0]  funct7_id_i,
    input  wire [6:0]  opcode_id_i,
    input  wire [3:0]  alu_op_id_i,
    input  wire        alu_src_id_i,
    input  wire        mem_read_id_i,
    input  wire        mem_write_id_i,
    input  wire        branch_id_i,
    input  wire        reg_write_id_i,
    input  wire [1:0]  mem_to_reg_id_i,
    input  wire [1:0]  forward_a_select_id_i, // New input
    input  wire [1:0]  forward_b_select_id_i, // New input
    
    // EX stage outputs
    output reg  [31:0] pc_ex_o,
    output reg  [31:0] pc_plus_4_ex_o,
    output reg  [31:0] operand_a_ex_o,
    output reg  [31:0] operand_b_ex_o,
    output reg  [31:0] reg2_data_ex_o,
    output reg  [31:0] immediate_ex_o,
    output reg  [4:0]  rs1_addr_ex_o,
    output reg  [4:0]  rs2_addr_ex_o,
    output reg  [4:0]  rd_addr_ex_o,
    output reg  [2:0]  funct3_ex_o,
    output reg  [6:0]  funct7_ex_o,
    output reg  [6:0]  opcode_ex_o,
    output reg  [3:0]  alu_op_ex_o,
    output reg         alu_src_ex_o,
    output reg         mem_read_ex_o,
    output reg         mem_write_ex_o,
    output reg         branch_ex_o,
    output reg         reg_write_ex_o,
    output reg  [1:0]  mem_to_reg_ex_o,
    output reg  [1:0]  forward_a_select_ex_o, // New output
    output reg  [1:0]  forward_b_select_ex_o  // New output
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_ex_o <= 32'h00000000;
            pc_plus_4_ex_o <= 32'h00000004;
            operand_a_ex_o <= 32'h00000000;
            operand_b_ex_o <= 32'h00000000;
            reg2_data_ex_o <= 32'h00000000;
            immediate_ex_o <= 32'h00000000;
            rs1_addr_ex_o <= 5'b00000;
            rs2_addr_ex_o <= 5'b00000;
            rd_addr_ex_o <= 5'b00000;
            funct3_ex_o <= 3'b000;
            funct7_ex_o <= 7'b0000000;
            opcode_ex_o <= `OPCODE_IMM;
            alu_op_ex_o <= `ALU_ADD;
            alu_src_ex_o <= 1'b0;
            mem_read_ex_o <= 1'b0;
            mem_write_ex_o <= 1'b0;
            branch_ex_o <= 1'b0;
            reg_write_ex_o <= 1'b0;
            mem_to_reg_ex_o <= `MEM_TO_REG_ALU;
            forward_a_select_ex_o <= `FORWARD_NONE; // Reset to NOP/None
            forward_b_select_ex_o <= `FORWARD_NONE; // Reset to NOP/None
        end
        else if (flush_i) begin
            pc_ex_o <= 32'h00000000;
            pc_plus_4_ex_o <= 32'h00000004;
            operand_a_ex_o <= 32'h00000000;
            operand_b_ex_o <= 32'h00000000;
            reg2_data_ex_o <= 32'h00000000;
            immediate_ex_o <= 32'h00000000;
            rs1_addr_ex_o <= 5'b00000;
            rs2_addr_ex_o <= 5'b00000;
            rd_addr_ex_o <= 5'b00000;
            funct3_ex_o <= 3'b000;
            funct7_ex_o <= 7'b0000000;
            opcode_ex_o <= `OPCODE_IMM;
            alu_op_ex_o <= `ALU_ADD;
            alu_src_ex_o <= 1'b0;
            mem_read_ex_o <= 1'b0;
            mem_write_ex_o <= 1'b0;
            branch_ex_o <= 1'b0;
            reg_write_ex_o <= 1'b0;
            mem_to_reg_ex_o <= `MEM_TO_REG_ALU;
            forward_a_select_ex_o <= `FORWARD_NONE;
            forward_b_select_ex_o <= `FORWARD_NONE;
        end
        else if (!stall_i) begin
            pc_ex_o <= pc_id_i;
            pc_plus_4_ex_o <= pc_plus_4_id_i;
            operand_a_ex_o <= operand_a_id_i;
            operand_b_ex_o <= operand_b_id_i;
            reg2_data_ex_o <= reg2_data_id_i;
            immediate_ex_o <= immediate_id_i;
            rs1_addr_ex_o <= rs1_addr_id_i;
            rs2_addr_ex_o <= rs2_addr_id_i;
            rd_addr_ex_o <= rd_addr_id_i;
            funct3_ex_o <= funct3_id_i;
            funct7_ex_o <= funct7_id_i;
            opcode_ex_o <= opcode_id_i;
            alu_op_ex_o <= alu_op_id_i;
            alu_src_ex_o <= alu_src_id_i;
            mem_read_ex_o <= mem_read_id_i;
            mem_write_ex_o <= mem_write_id_i;
            branch_ex_o <= branch_id_i;
            reg_write_ex_o <= reg_write_id_i;
            mem_to_reg_ex_o <= mem_to_reg_id_i;
            forward_a_select_ex_o <= forward_a_select_id_i; // Register forwarding signal
            forward_b_select_ex_o <= forward_b_select_id_i; // Register forwarding signal
        end
        // stall时保持当前值不变
    end

endmodule