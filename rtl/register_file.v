`timescale 1ns/1ps
`include "defines.v"

module register_file (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [4:0]  rs1_addr_i,
    input  wire [4:0]  rs2_addr_i,
    input  wire        reg_write_i,
    input  wire [4:0]  rd_addr_i,
    input  wire [31:0] write_data_i,
    output wire [31:0] rs1_data_o,
    output wire [31:0] rs2_data_o
);

    // 32个32位寄存器
    reg [31:0] registers [0:31];
    
    // 读操作 - 异步读取
    assign rs1_data_o = (rs1_addr_i == 5'b00000) ? 32'h00000000 : registers[rs1_addr_i];
    assign rs2_data_o = (rs2_addr_i == 5'b00000) ? 32'h00000000 : registers[rs2_addr_i];
    
    // 写操作 - 同步写入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            integer i;
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'h00000000;
            end
            $display("寄存器文件初始化完成");
        end
        else if (reg_write_i) begin
            if (rd_addr_i == 5'b00000) begin
                // x0寄存器始终为0，忽略写入
            end
            else begin
                registers[rd_addr_i] <= write_data_i;
                $display("[REG] 写入 x%0d = 0x%08x", rd_addr_i, write_data_i);
            end
        end
    end

endmodule