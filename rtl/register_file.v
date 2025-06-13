`timescale 1ns/1ps
`include "defines.v"

module register_file (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        reg_write_i,
    input  wire [4:0]  rs1_addr_i,      // 修复：匹配CPU顶层端口名
    input  wire [4:0]  rs2_addr_i,      // 修复：匹配CPU顶层端口名
    input  wire [4:0]  rd_addr_i,       // 修复：匹配CPU顶层端口名
    input  wire [31:0] write_data_i,
    output wire [31:0] rs1_data_o,      // 修复：匹配CPU顶层端口名
    output wire [31:0] rs2_data_o       // 修复：匹配CPU顶层端口名
);

    // 32个32位寄存器
    reg [31:0] registers [1:31];
    integer i;
    
    // 初始化寄存器
    initial begin
        for (i = 1; i < 32; i = i + 1) begin
            registers[i] = 32'h0;
        end
        $display("寄存器文件初始化完成");
    end
    
    // 异步读取，确保x0恒为0
    assign rs1_data_o = (rs1_addr_i == 5'b0) ? 32'h0 : registers[rs1_addr_i];
    assign rs2_data_o = (rs2_addr_i == 5'b0) ? 32'h0 : registers[rs2_addr_i];
    
    // 监控关键寄存器读取
    always @(*) begin
        if (rs1_addr_i == 5'd7 && rs2_addr_i == 5'd8) begin
            $display("[REG_READ] 关键SUB指令读取: x7=0x%08x, x8=0x%08x", 
                    rs1_data_o, rs2_data_o);
        end
    end
    
    // 同步写入，x0不可写
    always @(posedge clk) begin
        if (rst_n && reg_write_i && rd_addr_i != 5'b0) begin
            registers[rd_addr_i] <= write_data_i;
            $display("[REG] 写入 x%0d = 0x%08x", rd_addr_i, write_data_i);
        end
    end

endmodule