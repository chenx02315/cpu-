`timescale 1ns/1ps
`include "defines.v"

module sub_instruction_test;

    // 时钟和复位
    reg clk;
    reg rst_n;
    
    // CPU接口
    wire [31:0] pc_if;
    wire [31:0] instruction_if;
    
    // 时钟生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // 复位生成
    initial begin
        rst_n = 0;
        #50;
        rst_n = 1;
        $display("=== SUB指令专项测试开始 ===");
    end
    
    // 实例化CPU
    cpu_top u_cpu_top (
        .clk(clk),
        .rst_n(rst_n),
        .pc_if(pc_if),
        .instruction_if(instruction_if)
    );
    
    // 监控特定指令执行
    always @(posedge clk) begin
        if (rst_n) begin
            // 监控SUB指令 (PC=0x118, 指令=40838233)
            if (pc_if == 32'h118 && instruction_if == 32'h40838233) begin
                $display("\n=== SUB指令执行监控 ===");
                $display("PC: 0x%08x", pc_if);
                $display("指令: 0x%08x", instruction_if);
                $display("操作数 x7: 0x%08x", u_cpu_top.u_register_file.registers[7]);
                $display("操作数 x8: 0x%08x", u_cpu_top.u_register_file.registers[8]);
                
                // 等待指令执行完成
                repeat(3) @(posedge clk);
                
                $display("结果 x4: 0x%08x", u_cpu_top.u_register_file.registers[4]);
                $display("期望结果: 0x5980edb5");
                
                // 手工验证
                reg [31:0] manual_calc;
                manual_calc = u_cpu_top.u_register_file.registers[7] - u_cpu_top.u_register_file.registers[8];
                $display("手工计算: 0x%08x - 0x%08x = 0x%08x", 
                        u_cpu_top.u_register_file.registers[7],
                        u_cpu_top.u_register_file.registers[8],
                        manual_calc);
                
                if (u_cpu_top.u_register_file.registers[4] == 32'h5980edb5) begin
                    $display("✓ SUB指令执行正确!");
                end else begin
                    $display("✗ SUB指令执行错误!");
                    
                    // 详细调试信息
                    $display("ALU控制信号: %d", u_cpu_top.u_ex_stage.alu_control_ex);
                    $display("ALU操作数A: 0x%08x", u_cpu_top.u_ex_stage.alu_operand_a);
                    $display("ALU操作数B: 0x%08x", u_cpu_top.u_ex_stage.alu_operand_b);
                    $display("ALU结果: 0x%08x", u_cpu_top.u_ex_stage.alu_result_ex);
                end
                
                $display("=== SUB指令测试结束 ===\n");
                #100;
                $finish;
            end
        end
    end
    
    // 超时保护
    initial begin
        #10000;
        $display("测试超时!");
        $finish;
    end

endmodule
