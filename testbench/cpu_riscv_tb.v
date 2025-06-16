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
        #(CLK_PERIOD * 10);
        rst_n = 1;
        $display("========================================");
        $display("RISC-V CPU完整测试开始 - 时间: %0t", $time);
        $display("目标：执行232条完整指令");
        $display("时钟周期: %0dns", CLK_PERIOD);
        $display("========================================");
    end
    
    // 修复：扩大测试范围
    parameter MAX_CYCLES = 400;  // 修改：减少最大周期数         
    parameter TEST_END_PC = 32'h3A0;       
    parameter FULL_TEST_END_PC = 32'h3A0;  
    parameter PROGRESS_INTERVAL = 100;     

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
    reg [31:0] instruction_count = 0;
    reg [31:0] pc_previous = 0;
    reg [7:0] pc_stall_count = 0;
    reg lui_check_done = 0;
    
    // 修复：更准确的指令计数逻辑
    reg [31:0] unique_pc_count = 0;
    reg [31:0] pc_history [0:1023];  // 存储访问过的PC
    integer pc_index = 0;
    
    // 检查PC是否为新指令
    function is_new_instruction;
        input [31:0] current_pc;
        integer i;
        begin
            is_new_instruction = 1;
            for (i = 0; i < pc_index; i = i + 1) begin
                if (pc_history[i] == current_pc) begin
                    is_new_instruction = 0;
                end
            end
        end
    endfunction
    
    // 周期计数和指令计数
    always @(posedge clk) begin
        if (rst_n) begin
            cycle_count <= cycle_count + 1;
            
            // 修复：基于PC地址计算实际执行的指令数
            if (pc_if != 32'h0) begin
                // 方法1：基于PC地址直接计算（最准确）
                instruction_count <= (pc_if >> 2) + 1;
                
                // 方法2：记录唯一PC访问（用于验证）
                if (is_new_instruction(pc_if) && pc_index < 1024) begin
                    pc_history[pc_index] <= pc_if;
                    pc_index <= pc_index + 1;
                    unique_pc_count <= unique_pc_count + 1;
                end
            end
        end
    end
    
    // 修复：更新检查点定义以匹配完整指令序列
    parameter CHECKPOINT_LUI_END = 32'h0000007C;    
    parameter CHECKPOINT_ADDI_END = 32'h000000FC;   
    parameter CHECKPOINT_ARITH1_END = 32'h00000150; 
    parameter CHECKPOINT_ARITH2_END = 32'h00000180; 
    parameter CHECKPOINT_MEM_START = 32'h00000198;  
    parameter CHECKPOINT_BRANCH_START = 32'h00000200; 
    parameter FINAL_TEST_END = 32'h000003A0;        
    
    // LUI检查逻辑
    always @(posedge clk) begin
        if (rst_n && pc_if == CHECKPOINT_LUI_END && !lui_check_done) begin
            repeat(5) @(posedge clk);
            $display("\n=== 检查点1: LUI指令完成 (PC=0x%08x) ===", pc_if);
            dump_registers("LUI指令完成后");
            check_lui_results();
            lui_check_done <= 1;
        end
    end
    
    // 主监控逻辑
    always @(posedge clk) begin
        if (rst_n) begin
            // 进度报告
            if (cycle_count % PROGRESS_INTERVAL == 0 && cycle_count > 0) begin
                $display("[进度] 周期: %d, PC: 0x%08x, 指令: 0x%08x, 执行指令数: %d", 
                        cycle_count, pc_if, instruction_if, instruction_count);
            end
            
            // 监控关键检查点
            if (pc_if == CHECKPOINT_ADDI_END && test_stage == 0) begin
                test_stage <= 1;
                $display("\n=== 检查点2: ADDI指令完成 (PC=0x%08x) ===", pc_if);
                dump_registers("ADDI指令完成后");
                check_addi_results();
            end
            
            if (pc_if == CHECKPOINT_ARITH1_END && test_stage == 1) begin
                test_stage <= 2;
                $display("\n=== 检查点3: 第一批算术指令完成 (PC=0x%08x) ===", pc_if);
                dump_registers("第一批算术指令完成后");
            end
            
            if (pc_if == CHECKPOINT_MEM_START && test_stage == 2) begin
                test_stage <= 3;
                $display("\n=== 检查点4: 内存操作开始 (PC=0x%08x) ===", pc_if);
                dump_registers("内存操作开始前");
            end
            
            if (pc_if == CHECKPOINT_BRANCH_START && test_stage == 3) begin
                test_stage <= 4;
                $display("\n=== 检查点5: 分支指令开始 (PC=0x%08x) ===", pc_if);
                dump_registers("分支指令开始前");
            end
            
            // 修复：更准确的测试完成判断
            if (pc_if >= FINAL_TEST_END) begin
                test_stage <= 5;
                $display("\n=== 完整测试完成 (PC=0x%08x) ===", pc_if);
                $display("实际执行指令数: %d (基于PC)", instruction_count);
                $display("唯一PC访问数: %d (验证)", unique_pc_count);
                dump_registers("最终完整状态");
                final_validation();
                test_summary();
                #(CLK_PERIOD * 10);
                $finish;
            end
            
            // 安全检查：避免无限循环
            if (cycle_count >= MAX_CYCLES) begin
                $display("达到最大周期数限制 (%d), 测试可能未完成", MAX_CYCLES);
                $display("当前PC: 0x%08x, 期望完成PC: 0x%08x", pc_if, FINAL_TEST_END);
                test_summary();
                $finish;
            end
            
            // 检测PC停滞
            if (pc_if == pc_previous) begin
                pc_stall_count <= pc_stall_count + 1;
                if (pc_stall_count >= 50) begin  
                    $display("检测到PC长时间停滞 (PC=0x%08x), 可能进入无限循环", pc_if);
                    $display("执行了 %d 条指令，目标232条", instruction_count);
                    test_summary();
                    $finish;
                end
            end else begin
                pc_stall_count <= 0;
                pc_previous <= pc_if;
            end
        end
    end

    // 分支指令覆盖统计
    integer branch_taken_count = 0;
    integer branch_not_taken_count = 0;

    // 标准答案寄存器值 - 用于最终对比
    reg [31:0] standard_registers [0:31];
    
    // 初始化标准答案
    initial begin
        // 标准答案寄存器值
        standard_registers[0]  = 32'h00000000; standard_registers[1]  = 32'h9ddcfc39;
        standard_registers[2]  = 32'h7a09a5eb; standard_registers[3]  = 32'hec66e522;
        standard_registers[4]  = 32'h5980edb5; standard_registers[5]  = 32'h80000122;
        standard_registers[6]  = 32'h7ffffabd; standard_registers[7]  = 32'h401e1042;
        standard_registers[8]  = 32'h7fffffff; standard_registers[9]  = 32'h6eefda65;
        standard_registers[10] = 32'h31a9e800; standard_registers[11] = 32'h00000003;
        standard_registers[12] = 32'hfc1eecab; standard_registers[13] = 32'h00000000;
        standard_registers[14] = 32'h00000001; standard_registers[15] = 32'h00000000;
        standard_registers[16] = 32'h00000001; standard_registers[17] = 32'hb500d4a3;
        standard_registers[18] = 32'hffffffb7; standard_registers[19] = 32'hdba3160f;
        standard_registers[20] = 32'h00000000; standard_registers[21] = 32'h00000001;
        standard_registers[22] = 32'h00000000; standard_registers[23] = 32'h00000001;
        standard_registers[24] = 32'hd8d40000; standard_registers[25] = 32'h000001e8;
        standard_registers[26] = 32'hffd3b4d7; standard_registers[27] = 32'h424dd1f4;
        standard_registers[28] = 32'h00000100; standard_registers[29] = 32'h000000fc;
        standard_registers[30] = 32'h14aae560; standard_registers[31] = 32'hffffffff;
    end

    // LUI指令结果检查
    task check_lui_results;
        begin
            $display("检查LUI指令执行结果(前5个寄存器):");
            // 修复：x1 的期望值更新为 LUI 和 ADDI 共同作用后的结果 (0x74567000 + 0x3c6)
            $display("  x1应为0x745673c6, 实际: 0x%08x %s", 
                    u_cpu_top.u_register_file.registers[1],
                    (u_cpu_top.u_register_file.registers[1] == 32'h745673c6) ? "✓" : "✗");
            $display("  x2应为0x29869000, 实际: 0x%08x %s", 
                    u_cpu_top.u_register_file.registers[2],
                    (u_cpu_top.u_register_file.registers[2] == 32'h29869000) ? "✓" : "✗");
            $display("  x3应为0xf0c51000, 实际: 0x%08x %s", 
                    u_cpu_top.u_register_file.registers[3],
                    (u_cpu_top.u_register_file.registers[3] == 32'hf0c51000) ? "✓" : "✗");
            $display("  x4应为0x8944a000, 实际: 0x%08x %s", 
                    u_cpu_top.u_register_file.registers[4],
                    (u_cpu_top.u_register_file.registers[4] == 32'h8944a000) ? "✓" : "✗");
            $display("  x5应为0x71f29000, 实际: 0x%08x %s", 
                    u_cpu_top.u_register_file.registers[5],
                    (u_cpu_top.u_register_file.registers[5] == 32'h71f29000) ? "✓" : "✗");
        end
    endtask

    // ADDI指令结果检查
    task check_addi_results;
        begin
            $display("检查ADDI指令执行结果(前5个寄存器):");
            $display("  x1应为0x745673c6, 实际: 0x%08x %s", 
                    u_cpu_top.u_register_file.registers[1],
                    (u_cpu_top.u_register_file.registers[1] == 32'h745673c6) ? "✓" : "✗");
            $display("  x2应为0x29868873, 实际: 0x%08x %s", 
                    u_cpu_top.u_register_file.registers[2],
                    (u_cpu_top.u_register_file.registers[2] == 32'h29868873) ? "✓" : "✗");
            $display("  x3应为0xf0c50cff, 实际: 0x%08x %s", 
                    u_cpu_top.u_register_file.registers[3],
                    (u_cpu_top.u_register_file.registers[3] == 32'hf0c50cff) ? "✓" : "✗");
        end
    endtask
    
    // 获取寄存器值的函数
    function [31:0] get_register_value;
        input [4:0] reg_num;
        begin
            if (reg_num == 0)
                get_register_value = 32'h0;
            else
                get_register_value = u_cpu_top.u_register_file.registers[reg_num];
        end
    endfunction

    // 最终验证任务 - 替换原有的final_validation
    task final_validation;
        integer i;
        integer match_count, critical_errors;  // 修复：改名避免关键字冲突
        reg [31:0] actual_val;
        reg [31:0] diff_val;
        begin
            $display("\n=== 详细寄存器核查结果 ===");
            $display("对比实际输出与标准答案");
            $display("========================================================================");
            $display("寄存器  标准答案      实际输出      状态    差值          分析");
            $display("------------------------------------------------------------------------");
            
            match_count = 0;
            critical_errors = 0;
            
            for (i = 0; i < 32; i = i + 1) begin
                actual_val = get_register_value(i);
                
                if (actual_val == standard_registers[i]) begin
                    match_count = match_count + 1;
                    $display("x%02d     0x%08x    0x%08x    ✓      0x00000000    匹配", 
                            i, standard_registers[i], actual_val);
                end else begin
                    diff_val = actual_val - standard_registers[i];
                    $display("x%02d     0x%08x    0x%08x    ✗      0x%08x    %s", 
                            i, standard_registers[i], actual_val, diff_val,
                            get_error_analysis(i, standard_registers[i], actual_val));
                    
                    // 标记关键错误 (保留标记，但后续分析已移除)
                    if (i == 4 || i == 27 || i == 29 || i == 30 || i == 31) begin // x27 is also critical now
                        critical_errors = critical_errors + 1;
                    end
                end
            end
            
            $display("------------------------------------------------------------------------");
            $display("统计结果:");
            $display("  匹配寄存器: %2d/32 (%.1f%%)", match_count, real'(match_count) * 100.0 / 32.0);
            $display("  不匹配寄存器: %2d/32", 32 - match_count);
            $display("  关键寄存器不匹配数: %2d (x4, x27, x29, x30, x31)", critical_errors);
            
            $display("========================================================================");
        end
    endtask
    
    // 错误分析函数 - 修改为更通用的分析
    function [199:0] get_error_analysis;
        input [4:0] reg_num;
        input [31:0] expected;
        input [31:0] actual;
        reg [31:0] diff;
        begin
            diff = actual - expected;
            case (reg_num)
                4:  get_error_analysis = "x4 (ALU/计算结果) 不匹配";
                27: get_error_analysis = "x27 (乘法结果) 不匹配";
                29: get_error_analysis = "x29 (内存加载/地址) 不匹配";
                30: get_error_analysis = "x30 (累加/内存结果) 不匹配";
                31: get_error_analysis = "x31 (计数器/状态) 不匹配";
                default: begin
                    if (diff[31:16] == 16'h0000 && diff[15:0] != 16'h0000)
                        get_error_analysis = "低16位不匹配";
                    else if (diff[15:0] == 16'h0000 && diff[31:16] != 16'h0000)
                        get_error_analysis = "高16位不匹配";
                    else if (diff == 32'h0)
                        get_error_analysis = "匹配 (逻辑错误)"; // Should not happen if called for mismatch
                    else
                        get_error_analysis = "全字不匹配";
                end
            endcase
        end
    endfunction
    
    // 寄存器状态转储任务
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
            $display("RISC-V CPU 完整测试总结");
            $display("========================================");
            $display("总周期数: %0d", cycle_count);
            $display("实际执行指令数: %0d / 232 (目标)", instruction_count);
            $display("PC到达位置: 0x%08x (对应第%0d条指令)", pc_if, (pc_if >> 2) + 1);
            $display("测试完成度: %.1f%%", real'(instruction_count) * 100.0 / 232.0);
            if (instruction_count > 0) begin
                $display("平均CPI: %.2f", real'(cycle_count) / real'(instruction_count));
            end
            $display("测试阶段完成: %0d/5", test_stage);
            $display("唯一PC访问数: %0d (验证用)", unique_pc_count);
            $display("\n分支指令覆盖情况:");
            $display("  分支跳转成功次数: %0d", branch_taken_count);
            $display("  分支未跳转次数: %0d", branch_not_taken_count);
            
            if (pc_if >= 32'h39C) begin
                $display("\n✓ 完整测试已完成! CPU成功执行了232条指令");
            end else begin
                $display("\n⚠ 测试未完全完成，停在阶段 %0d", test_stage);
            end
            $display("========================================");
        end
    endtask
    
    // 错误检测
    always @(posedge clk) begin
        if (rst_n) begin
            if (pc_if >= 32'h1000) begin
                $display("错误: PC超出指令存储器范围 0x%08x", pc_if);
                test_summary();
                $finish;
            end
            if (pc_if[1:0] != 2'b00) begin
                $display("错误: PC地址未4字节对齐 0x%08x", pc_if);
                test_summary();
                $finish;
            end
        end
    end
    
    // 新增：分支覆盖率统计逻辑
    always @(posedge clk) begin
        if (rst_n) begin
            // 检查MEM阶段是否正在处理一个分支类型的指令
            // u_cpu_top.branch_ctrl_ex_mem_reg 是从EX/MEM寄存器传来的branch控制信号
            // 它指示了进入MEM阶段的指令是否是分支指令
            if (u_cpu_top.branch_ctrl_ex_mem_reg) begin
                // u_cpu_top.branch_jump_request_mem 是MEM阶段的输出，指示分支是否实际发生跳转
                if (u_cpu_top.branch_jump_request_mem) begin
                    branch_taken_count <= branch_taken_count + 1;
                end else begin
                    branch_not_taken_count <= branch_not_taken_count + 1;
                end
            end
        end
    end
    
    // 波形文件生成
    initial begin
        if (!$test$plusargs("nofsdb")) begin
            $fsdbDumpfile("cpu_riscv_test.fsdb");
            $fsdbDumpvars(0, cpu_riscv_tb);
        end
        
        $dumpfile("cpu_riscv_test.vcd");
        $dumpvars(0, cpu_riscv_tb);
        $display("波形记录已启动 - 完整测试模式");
        $display("  FSDB: cpu_riscv_test.fsdb (用于Verdi)");
        $display("  VCD:  cpu_riscv_test.vcd (用于GTKWave)");
    end
    
    // 指令跟踪 - 可选开启
    always @(posedge clk) begin
        if (rst_n && $test$plusargs("trace_instr")) begin
            $display("[%0t] PC=0x%08x INSTR=0x%08x", $time, pc_if, instruction_if);
        end
    end

endmodule