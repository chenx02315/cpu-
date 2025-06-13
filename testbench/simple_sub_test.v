`timescale 1ns/1ps
`include "defines.v"

module simple_sub_test;

    // ALU信号
    reg  [31:0] operand_a;
    reg  [31:0] operand_b;
    reg  [3:0]  alu_op;
    wire [31:0] alu_result;
    wire        zero_flag;
    
    // 实例化ALU
    alu u_alu (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .alu_op(alu_op),
        .alu_result(alu_result),
        .zero_flag(zero_flag)
    );
    
    initial begin
        $display("=== ALU SUB指令单独测试 ===");
        
        // 测试1：标准期望的SUB操作
        operand_a = 32'h401e1042;
        operand_b = 32'h7fffffff;
        alu_op = `ALU_SUB;
        #10;
        $display("测试1: 0x%08x - 0x%08x = 0x%08x", operand_a, operand_b, alu_result);
        $display("期望: 0x5980edb5, 实际: 0x%08x, %s", alu_result, 
                (alu_result == 32'h5980edb5) ? "✓正确" : "✗错误");
        
        // 测试2：CPU实际使用的操作数
        operand_a = 32'hc41f1efb;
        operand_b = 32'hec66e522;
        alu_op = `ALU_SUB;
        #10;
        $display("测试2: 0x%08x - 0x%08x = 0x%08x", operand_a, operand_b, alu_result);
        $display("CPU输出: 0xd7b839d9, 实际: 0x%08x, %s", alu_result,
                (alu_result == 32'hd7b839d9) ? "✓匹配" : "✗不匹配");
        
        // 测试3：手工验证
        $display("\n=== 手工计算验证 ===");
        $display("0x401e1042 - 0x7fffffff:");
        $display("  401e1042");
        $display("- 7fffffff");
        $display("----------");
        $display("  c01e1043 (实际二进制运算结果)");
        $display("但期望值是 0x5980edb5，说明可能使用了不同的操作数");
        
        // 测试4：反推正确的操作数
        $display("\n=== 反推分析 ===");
        // 如果结果是0x5980edb5，rs2是0x7fffffff，rs1应该是多少？
        operand_a = 32'h5980edb5 + 32'h7fffffff;  // 加法反推
        operand_b = 32'h7fffffff;
        alu_op = `ALU_SUB;
        #10;
        $display("反推: 0x%08x - 0x%08x = 0x%08x", operand_a, operand_b, alu_result);
        $display("如果rs1=0x%08x, rs2=0x7fffffff, 结果=0x%08x", operand_a, alu_result);
        
        $finish;
    end

endmodule
