`timescale 1ns/1ps
`include "defines.v"

module ex_mem_register (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall_i,
    input  wire        flush_i,
    
    // EX阶段输入
    input  wire [31:0] pc_ex_i,
    input  wire [31:0] pc_plus_4_ex_i,
    input  wire [31:0] ex_result_ex_i,
    input  wire        zero_flag_ex_i,
    input  wire [31:0] reg2_data_ex_i,
    input  wire [31:0] immediate_ex_i,
    input  wire [4:0]  rd_addr_ex_i,
    input  wire [2:0]  funct3_ex_i,
    input  wire [6:0]  opcode_ex_i,        // 修复：添加opcode输入端口
    input  wire        mem_read_ex_i,
    input  wire        mem_write_ex_i,
    input  wire        branch_ctrl_ex_i,
    input  wire        reg_write_ex_i,
    input  wire [1:0]  mem_to_reg_ex_i,
    
    // MEM阶段输出
    output reg  [31:0] pc_ex_mem_o,
    output reg  [31:0] pc_plus_4_mem_o,
    output reg  [31:0] ex_result_mem_o,
    output reg         zero_flag_mem_o,
    output reg  [31:0] reg2_data_mem_o,
    output reg  [31:0] immediate_ex_mem_o,
    output reg  [4:0]  rd_addr_mem_o,
    output reg  [2:0]  funct3_mem_o,
    output reg  [6:0]  opcode_mem_o,       // 修复：添加opcode输出端口
    output reg         mem_read_mem_o,
    output reg         mem_write_mem_o,
    output reg         branch_ctrl_mem_o,
    output reg         reg_write_mem_o,
    output reg  [1:0]  mem_to_reg_mem_o
);

    always @(posedge clk) begin
        if (!rst_n) begin
            pc_ex_mem_o <= 32'h0;
            pc_plus_4_mem_o <= 32'h0;
            ex_result_mem_o <= 32'h0;
            zero_flag_mem_o <= 1'b0;
            reg2_data_mem_o <= 32'h0;
            immediate_ex_mem_o <= 32'h0;
            rd_addr_mem_o <= 5'h0;
            funct3_mem_o <= 3'h0;
            opcode_mem_o <= 7'h0;          // 修复：初始化opcode
            mem_read_mem_o <= 1'b0;
            mem_write_mem_o <= 1'b0;
            branch_ctrl_mem_o <= 1'b0;
            reg_write_mem_o <= 1'b0;
            mem_to_reg_mem_o <= 2'h0;
        end else if (flush_i) begin
            pc_ex_mem_o <= 32'h0;
            pc_plus_4_mem_o <= 32'h0;
            ex_result_mem_o <= 32'h0;
            zero_flag_mem_o <= 1'b0;
            reg2_data_mem_o <= 32'h0;
            immediate_ex_mem_o <= 32'h0;
            rd_addr_mem_o <= 5'h0;
            funct3_mem_o <= 3'h0;
            opcode_mem_o <= 7'h13;         // 修复：刷新时设为NOP
            mem_read_mem_o <= 1'b0;
            mem_write_mem_o <= 1'b0;
            branch_ctrl_mem_o <= 1'b0;
            reg_write_mem_o <= 1'b0;
            mem_to_reg_mem_o <= 2'h0;
        end else if (!stall_i) begin
            pc_ex_mem_o <= pc_ex_i;
            pc_plus_4_mem_o <= pc_plus_4_ex_i;
            ex_result_mem_o <= ex_result_ex_i;
            zero_flag_mem_o <= zero_flag_ex_i;
            reg2_data_mem_o <= reg2_data_ex_i;
            immediate_ex_mem_o <= immediate_ex_i;
            rd_addr_mem_o <= rd_addr_ex_i;
            funct3_mem_o <= funct3_ex_i;
            opcode_mem_o <= opcode_ex_i;   // 修复：传递opcode
            mem_read_mem_o <= mem_read_ex_i;
            mem_write_mem_o <= mem_write_ex_i;
            branch_ctrl_mem_o <= branch_ctrl_ex_i;
            reg_write_mem_o <= reg_write_ex_i;
            mem_to_reg_mem_o <= mem_to_reg_ex_i;
        end
    end

endmodule