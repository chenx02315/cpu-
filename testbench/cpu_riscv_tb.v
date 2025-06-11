`timescale 1ns/1ps
`include "defines.v"

module cpu_riscv_tb;

    // 时钟和复位信号
    reg clk;
    reg rst_n;
    
    // CPU调试接口
    wire [31:0] pc_if;
    wire [31:0] instruction_if;
    
    // 时钟生成 - 100MHz (10ns周期)
    parameter CLK_PERIOD = 10;
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // 复位生成
    initial begin
        rst_n = 0;
        #(CLK_PERIOD * 10);  // 复位10个周期
        rst_n = 1;
        $display("========================================");
        $display("RISC-V CPU测试开始 - 时间: %0t", $time);
        $display("时钟周期: %0dns", CLK_PERIOD);
        $display("========================================");
    end
    
    // 测试控制参数
    parameter MAX_CYCLES = 1000;      // 增加最大周期数
    parameter TEST_END_PC = 32'h400;  // 修改：提高测试结束PC值，让它能执行更多指令
    parameter PROGRESS_INTERVAL = 50; // 进度报告间隔

    // 实例化CPU
    cpu_top u_cpu_top (
        .clk(clk),
        .rst_n(rst_n),
        .pc_if(pc_if),
        .instruction_if(instruction_if)
    );
    
    // 测试阶段标志
    reg [31:0] test_stage = 0;
    reg [31:0] cycle_count = 0;
    
    // 指令计数器
    reg [31:0] instruction_count = 0;
    
    // 扩展运行控制变量
    reg extended_run = 0;
    reg [7:0] extended_cycles = 0;
    reg [31:0] pc_previous = 0;
    reg [7:0] pc_stall_count = 0;
    
    // 周期计数
    always @(posedge clk) begin
        if (rst_n) begin
            cycle_count <= cycle_count + 1;
            if (pc_if != 32'h0 || cycle_count > 0) begin
                instruction_count <= instruction_count + 1;
            end
        end
    end
    
    // 检查点定义 - 确保修正指令都能执行
    parameter CHECKPOINT_1 = 32'h0000007c;  // LUI指令完成后
    parameter CHECKPOINT_2 = 32'h000000ac;  // ADDI指令完成后 
    parameter CHECKPOINT_3 = 32'h00000150;  // 算术逻辑指令完成后
    parameter TEST_END = 32'h000001a0;      // 最终测试结束（地址0x1a0，确保修正指令执行完毕）
    
    // 主监控逻辑 - 简化为只有一个监控逻辑
    always @(posedge clk) begin
        if (rst_n) begin
            // 进度报告
            if (cycle_count % PROGRESS_INTERVAL == 0 && cycle_count > 0) begin
                $display("[进度] 周期: %d, PC: 0x%08x, 指令: 0x%08x", 
                        cycle_count, pc_if, instruction_if);
            end
            
            // 监控关键检查点
            case (pc_if)
                CHECKPOINT_1: begin
                    if (test_stage == 0) begin
                        test_stage <= 1;
                        $display("\n=== 检查点1: LUI指令测试完成 (PC=0x%08x) ===", pc_if);
                        dump_registers("LUI指令完成后");
                        check_lui_results();
                    end
                end
                
                CHECKPOINT_2: begin
                    if (test_stage == 1) begin
                        test_stage <= 2;
                        $display("\n=== 检查点2: ADDI指令测试完成 (PC=0x%08x) ===", pc_if);
                        dump_registers("ADDI指令完成后");
                        check_addi_results();
                    end
                end
                
                CHECKPOINT_3: begin
                    if (test_stage == 2) begin
                        test_stage <= 3;
                        $display("\n=== 检查点3: 第一批算术逻辑指令完成 (PC=0x%08x) ===", pc_if);
                        dump_registers("第一批算术逻辑指令完成后");
                    end
                end
                
                TEST_END: begin
                    if (test_stage >= 1) begin
                        test_stage <= 4;
                        $display("\n=== 测试完成 (PC=0x%08x) ===", pc_if);
                        dump_registers("最终状态");
                        final_validation();
                        test_summary();
                        #(CLK_PERIOD * 10);
                        $finish;
                    end
                end
            endcase
            
            // 停止条件检查
            if (cycle_count >= MAX_CYCLES) begin
                $display("⚠ 达到最大周期数限制 (%d), 强制停止", MAX_CYCLES);
                test_summary();
                $finish;
            end else if (pc_if >= TEST_END_PC) begin
                $display("=== 测试完成 (PC=0x%08x) ===", pc_if);
                test_summary();
                
                // 继续执行一段时间以观察后续指令
                if (!extended_run) begin
                    $display("继续执行后续指令...");
                    extended_run <= 1;
                    extended_cycles <= 0;
                end else begin
                    extended_cycles <= extended_cycles + 1;
                    if (extended_cycles >= 100) begin  // 再执行100个周期
                        $display("扩展执行完成，停止仿真");
                        $finish;
                    end
                end
            end
            
            // 检测无限循环 - 如果PC连续多个周期不变
            if (pc_if == pc_previous) begin
                pc_stall_count <= pc_stall_count + 1;
                if (pc_stall_count >= 20) begin
                    $display("⚠ 检测到PC停滞 (PC=0x%08x), 可能进入无限循环", pc_if);
                    test_summary();
                    $finish;
                end
            end else begin
                pc_stall_count <= 0;
                pc_previous <= pc_if;
            end
            
            // 每20个周期显示进度（避免重复）
            if (cycle_count % 20 == 0 && cycle_count > 0 && cycle_count % PROGRESS_INTERVAL != 0) begin
                $display("[进度] 周期: %0d, PC: 0x%08x, 指令: 0x%08x", 
                        cycle_count, pc_if, instruction_if);
            end
            
            // 自动结束条件 - 延长最大周期数
            if (cycle_count > 300) begin
                $display("\n=== 达到最大周期数，测试结束 ===");
                dump_registers("超时结束状态");
                test_summary();
                $finish;
            end
        end
    end

    // LUI指令结果检查
    task check_lui_results;
        begin
            $display("检查LUI指令执行结果:");
            $display("  x1应为0x74567000, 实际: 0x%08x %s", 
                    u_cpu_top.u_register_file.registers[1],
                    (u_cpu_top.u_register_file.registers[1] == 32'h74567000) ? "✓" : "✗");
            $display("  x2应为0x29869000, 实际: 0x%08x %s", 
                    u_cpu_top.u_register_file.registers[2],
                    (u_cpu_top.u_register_file.registers[2] == 32'h29869000) ? "✓" : "✗");
            $display("  x3应为0xf0c51000, 实际: 0x%08x %s", 
                    u_cpu_top.u_register_file.registers[3],
                    (u_cpu_top.u_register_file.registers[3] == 32'hf0c51000) ? "✓" : "✗");
        end
    endtask
    
    // ADDI指令结果检查
    task check_addi_results;
        begin
            $display("检查ADDI指令执行结果:");
            $display("  x1应为0x745673c6, 实际: 0x%08x %s", 
                    u_cpu_top.u_register_file.registers[1],
                    (u_cpu_top.u_register_file.registers[1] == 32'h745673c6) ? "✓" : "✗");
            $display("  x2应为0x29868873, 实际: 0x%08x %s", 
                    u_cpu_top.u_register_file.registers[2],
                    (u_cpu_top.u_register_file.registers[2] == 32'h29868873) ? "✓" : "✗");
        end
    endtask
    
    // 寄存器状态转储任务 - 修复：显示所有32个寄存器
    task dump_registers;
        input [255:0] stage_name;
        begin
            $display("=== %s 寄存器状态 ===", stage_name);
            $display("x00=0x%08x x01=0x%08x x02=0x%08x x03=0x%08x", 
                    32'h0, u_cpu_top.u_register_file.registers[1],
                    u_cpu_top.u_register_file.registers[2], u_cpu_top.u_register_file.registers[3]);
            $display("x04=0x%08x x05=0x%08x x06=0x%08x x07=0x%08x", 
                    u_cpu_top.u_register_file.registers[4], u_cpu_top.u_register_file.registers[5],
                    u_cpu_top.u_register_file.registers[6], u_cpu_top.u_register_file.registers[7]);
            $display("x08=0x%08x x09=0x%08x x10=0x%08x x11=0x%08x", 
                    u_cpu_top.u_register_file.registers[8], u_cpu_top.u_register_file.registers[9],
                    u_cpu_top.u_register_file.registers[10], u_cpu_top.u_register_file.registers[11]);
            $display("x12=0x%08x x13=0x%08x x14=0x%08x x15=0x%08x", 
                    u_cpu_top.u_register_file.registers[12], u_cpu_top.u_register_file.registers[13],
                    u_cpu_top.u_register_file.registers[14], u_cpu_top.u_register_file.registers[15]);
            // 添加剩余的寄存器显示
            $display("x16=0x%08x x17=0x%08x x18=0x%08x x19=0x%08x", 
                    u_cpu_top.u_register_file.registers[16], u_cpu_top.u_register_file.registers[17],
                    u_cpu_top.u_register_file.registers[18], u_cpu_top.u_register_file.registers[19]);
            $display("x20=0x%08x x21=0x%08x x22=0x%08x x23=0x%08x", 
                    u_cpu_top.u_register_file.registers[20], u_cpu_top.u_register_file.registers[21],
                    u_cpu_top.u_register_file.registers[22], u_cpu_top.u_register_file.registers[23]);
            $display("x24=0x%08x x25=0x%08x x26=0x%08x x27=0x%08x", 
                    u_cpu_top.u_register_file.registers[24], u_cpu_top.u_register_file.registers[25],
                    u_cpu_top.u_register_file.registers[26], u_cpu_top.u_register_file.registers[27]);
            $display("x28=0x%08x x29=0x%08x x30=0x%08x x31=0x%08x", 
                    u_cpu_top.u_register_file.registers[28], u_cpu_top.u_register_file.registers[29],
                    u_cpu_top.u_register_file.registers[30], u_cpu_top.u_register_file.registers[31]);
            $display("");
        end
    endtask
    
    // 测试总结任务
    task test_summary;
        begin
            $display("========================================");
            $display("测试总结");
            $display("========================================");
            $display("总周期数: %0d", cycle_count);
            $display("指令执行数: %0d", instruction_count);
            if (instruction_count > 0) begin
                $display("平均CPI: %.2f", real'(cycle_count) / real'(instruction_count));
            end
            $display("测试阶段完成: %0d/4", test_stage);
            
            // 关键寄存器验证
            $display("\n关键寄存器验证:");
            $display("x1: 0x%08x", u_cpu_top.u_register_file.registers[1]);
            $display("x2: 0x%08x", u_cpu_top.u_register_file.registers[2]);
            $display("x3: 0x%08x", u_cpu_top.u_register_file.registers[3]);
            
            if (test_stage >= 3) begin
                $display("✓ 基础测试已完成");
            end else begin
                $display("✗ 测试未完全完成，停在阶段 %0d", test_stage);
            end
            $display("========================================");
        end
    endtask
    
    // 最终验证任务
    task final_validation;
        reg [31:0] expected_values [0:31];
        integer i, errors;
        begin
            // 期望的寄存器值（基于标准答案）
            expected_values[0]  = 32'h00000000;
            expected_values[1]  = 32'h9ddcfc39;
            expected_values[2]  = 32'h7a09a5eb;
            expected_values[3]  = 32'hec66e522;
            expected_values[4]  = 32'h5980edb5;
            expected_values[5]  = 32'h80000122;
            expected_values[6]  = 32'h7ffffabd;
            expected_values[7]  = 32'h401e1042;
            expected_values[8]  = 32'h7fffffff;
            expected_values[9]  = 32'h6eefda65;
            expected_values[10] = 32'h31a9e800;
            expected_values[11] = 32'h00000003;
            expected_values[12] = 32'hfc1eecab;
            expected_values[13] = 32'h00000000;
            expected_values[14] = 32'h00000001;
            expected_values[15] = 32'h00000000;
            expected_values[16] = 32'h00000001;
            expected_values[17] = 32'hb500d4a3;
            expected_values[18] = 32'hffffffb7;
            expected_values[19] = 32'hdba3160f;
            expected_values[20] = 32'h00000000;
            expected_values[21] = 32'h00000001;
            expected_values[22] = 32'h00000000;
            expected_values[23] = 32'h00000001;
            expected_values[24] = 32'hd8d40000;
            expected_values[25] = 32'h000001e8;
            expected_values[26] = 32'hffd3b4d7;
            expected_values[27] = 32'h424dd1f4;
            expected_values[28] = 32'h00000100;
            expected_values[29] = 32'h000000fc;
            expected_values[30] = 32'h14aae560;
            expected_values[31] = 32'hffffffff;
            
            $display("\n=== 最终验证结果 ===");
            errors = 0;
            
            for (i = 0; i <= 31; i = i + 1) begin
                if (i == 0) begin
                    // x0始终为0
                    if (32'h0 != expected_values[i]) begin
                        $display("✗ x%02d: 期望=0x%08x, 实际=0x%08x", i, expected_values[i], 32'h0);
                        errors = errors + 1;
                    end else begin
                        $display("✓ x%02d: 0x%08x", i, 32'h0);
                    end
                end else begin
                    if (u_cpu_top.u_register_file.registers[i] != expected_values[i]) begin
                        $display("✗ x%02d: 期望=0x%08x, 实际=0x%08x", i, expected_values[i], u_cpu_top.u_register_file.registers[i]);
                        errors = errors + 1;
                    end else begin
                        $display("✓ x%02d: 0x%08x", i, u_cpu_top.u_register_file.registers[i]);
                    end
                end
            end
            
            $display("\n验证统计:");
            $display("总寄存器数: 32");
            $display("匹配寄存器: %0d", 32 - errors);
            $display("错误寄存器: %0d", errors);
            
            if (errors == 0) begin
                $display("🎉 所有寄存器值验证通过！");
            end else begin
                $display("⚠ 有 %0d 个寄存器值不匹配", errors);
            end
        end
    endtask
    
    // 错误检测
    always @(posedge clk) begin
        if (rst_n) begin
            // 检测PC超出范围
            if (pc_if >= 32'h1000) begin
                $display("错误: PC超出指令存储器范围 0x%08x", pc_if);
                test_summary();
                $finish;
            end
            
            // 检测PC未对齐
            if (pc_if[1:0] != 2'b00) begin
                $display("错误: PC地址未4字节对齐 0x%08x", pc_if);
                test_summary();
                $finish;
            end
        end
    end
    
    // 波形文件生成
    initial begin
        // VCS波形输出
        if (!$test$plusargs("nofsdb")) begin
            $fsdbDumpfile("cpu_riscv_test.fsdb");
            $fsdbDumpvars(0, cpu_riscv_tb);
        end
        
        // 也生成VCD格式以备用
        $dumpfile("cpu_riscv_test.vcd");
        $dumpvars(0, cpu_riscv_tb);
        
        $display("波形记录已启动:");
        if (!$test$plusargs("nofsdb")) begin
            $display("  FSDB: cpu_riscv_test.fsdb (用于Verdi)");
        end
        $display("  VCD:  cpu_riscv_test.vcd (用于GTKWave)");
    end
    
    // 指令跟踪 (可选，详细模式)
    always @(posedge clk) begin
        if (rst_n && $test$plusargs("trace_instr")) begin
            $display("[%0t] PC=0x%08x INSTR=0x%08x", $time, pc_if, instruction_if);
        end
    end

endmodule
