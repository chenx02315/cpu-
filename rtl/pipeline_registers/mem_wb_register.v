`include "defines.v"

module mem_wb_register (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall_i,
    input  wire        flush_i,
    
    // MEM stage inputs
    input  wire [31:0] pc_plus_4_mem_i,
    input  wire [31:0] mem_read_data_mem_i,
    input  wire [31:0] ex_result_mem_i,
    input  wire [4:0]  rd_addr_mem_i,
    input  wire        reg_write_mem_i,
    input  wire [1:0]  mem_to_reg_mem_i,
    
    // WB stage outputs
    output reg  [31:0] pc_plus_4_wb_o,
    output reg  [31:0] mem_read_data_wb_o,
    output reg  [31:0] ex_result_wb_o,
    output reg  [4:0]  rd_addr_wb_o,
    output reg         reg_write_wb_o,
    output reg  [1:0]  mem_to_reg_wb_o
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_plus_4_wb_o <= 32'h00000004;
            mem_read_data_wb_o <= 32'h00000000;
            ex_result_wb_o <= 32'h00000000;
            rd_addr_wb_o <= 5'b00000;
            reg_write_wb_o <= 1'b0;
            mem_to_reg_wb_o <= `MEM_TO_REG_ALU;
        end
        else if (flush_i) begin
            pc_plus_4_wb_o <= 32'h00000004;
            mem_read_data_wb_o <= 32'h00000000;
            ex_result_wb_o <= 32'h00000000;
            rd_addr_wb_o <= 5'b00000;
            reg_write_wb_o <= 1'b0;
            mem_to_reg_wb_o <= `MEM_TO_REG_ALU;
        end
        else if (!stall_i) begin
            pc_plus_4_wb_o <= pc_plus_4_mem_i;
            mem_read_data_wb_o <= mem_read_data_mem_i;
            ex_result_wb_o <= ex_result_mem_i;
            rd_addr_wb_o <= rd_addr_mem_i;
            reg_write_wb_o <= reg_write_mem_i;
            mem_to_reg_wb_o <= mem_to_reg_mem_i;
        end
        // stall时保持当前值不变
    end

endmodule
