`timescale 1ns/1ps

module test_instruction_debug;

    // 指令存储器模拟
    reg [31:0] imem [0:1023];
    integer i;
    
    initial begin
        $display("=== 指令存储器布局调试 ===");
        
        // 初始化为NOP
        for (i = 0; i < 1024; i = i + 1) begin
            imem[i] = 32'h00000013; // NOP
        end
        
        // 按照原程序布局指令
        // ... (省略前面的LUI/ADDI指令)
        
        // 关键的修正指令区域
        imem[95] = 32'h1e800c93;  // addi x25,x0,488
        imem[96] = 32'h10000e13;  // addi x28,x0,256
        imem[97] = 32'h0fc00e93;  // addi x29,x0,252
        imem[98] = 32'h14aaef37;  // lui x30, 0x14aae
        imem[99] = 32'h560f0f13;  // addi x30,x30,1376
        imem[100] = 32'hfffff93; // addi x31,x31,-1
        
        $display("修正指令布局验证:");
        $display("地址0x%03x (imem[%0d]): 0x%08x - addi x25,x0,488", 95*4, 95, imem[95]);
        $display("地址0x%03x (imem[%0d]): 0x%08x - addi x28,x0,256", 96*4, 96, imem[96]);
        $display("地址0x%03x (imem[%0d]): 0x%08x - addi x29,x0,252", 97*4, 97, imem[97]);
        $display("地址0x%03x (imem[%0d]): 0x%08x - lui x30,0x14aae", 98*4, 98, imem[98]);
        $display("地址0x%03x (imem[%0d]): 0x%08x - addi x30,x30,1376", 99*4, 99, imem[99]);
        $display("地址0x%03x (imem[%0d]): 0x%08x - addi x31,x31,-1", 100*4, 100, imem[100]);
        
        // 验证测试结束地址
        $display("\n测试结束地址0x1a0对应imem[%0d]", 32'h1a0/4);
        $display("修正指令是否在测试结束前: %s", (100*4 < 32'h1a0) ? "是" : "否");
        
        $finish;
    end

endmodule
