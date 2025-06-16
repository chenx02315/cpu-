`timescale 1ns/1ps
`include "defines.v"

module instruction_memory (
    input  wire [31:0] addr_i,   // 指令地址 (字节地址)
    output reg  [31:0] instr_o   // 读取的指令
);

    // 指令存储器大小: 4KB (1024条32位指令)
    parameter INSTR_MEM_WORDS = 1024;
    
    // 更改为字存储器数组
    reg [31:0] instr_mem_words [0:INSTR_MEM_WORDS-1];

    // Task to load instructions from a hex file
    task load_hex_from_file;
        integer i;
        reg hex_loaded;
        integer file_descriptor;
        begin
            hex_loaded = 1'b0;
            $display("尝试从hex文件加载测试用例...");
            
            file_descriptor = $fopen("test/riscv_case/riscv.hex", "r");
            if (file_descriptor != 0) begin
                $readmemh("test/riscv_case/riscv.hex", instr_mem_words); // 加载到字数组
                hex_loaded = 1'b1;
                $display("✓ 从test目录加载hex文件成功");
                $fclose(file_descriptor);
            end else begin
                // $display("⚠ 无法从test目录找到hex文件，尝试上一级目录...");
                file_descriptor = $fopen("../test/riscv_case/riscv.hex", "r");
                if (file_descriptor != 0) begin
                    $readmemh("../test/riscv_case/riscv.hex", instr_mem_words); // 加载到字数组
                    hex_loaded = 1'b1;
                    $display("✓ 从上级test目录加载hex文件成功");
                    $fclose(file_descriptor);
                end else begin
                    $display("⚠ 无法找到hex文件 (尝试了 test/ 和 ../test/)。指令存储器将保持初始化的零值。");
                end
            end

            if (!hex_loaded) begin
                // 如果需要，可以在这里填充 NOP 指令到 instr_mem_words
                // for (i = 0; i < INSTR_MEM_WORDS; i = i + 1) begin
                //     instr_mem_words[i] = `NOP_INSTRUCTION;
                // end
                // $display("由于无法加载hex文件，指令存储器已用NOP填充。");
                 $display("由于无法加载hex文件，指令存储器将使用初始化的零值。");
            end
        end
    endtask
    
    // 初始化指令存储器
    integer k;
    initial begin
        for (k = 0; k < INSTR_MEM_WORDS; k = k + 1) begin
            instr_mem_words[k] = 32'h00000000; // 初始化字数组
        end
        $display("指令存储器初始化完成 (全0)，大小: %0d 字 (%0d 字节)", INSTR_MEM_WORDS, INSTR_MEM_WORDS*4);
        load_hex_from_file; 
    end

    // Read operation (combinational)
    wire [31:0] byte_addr = addr_i;
    // 计算字地址: 对于1024个字 (4KB)，字地址范围是0-1023。
    // word_addr = byte_addr / 4。使用位截取 byte_addr[11:2] 得到10位字地址。
    wire [$clog2(INSTR_MEM_WORDS)-1:0] word_addr = byte_addr[$clog2(INSTR_MEM_WORDS*4)-1 : 2];


    always @(*) begin
        // 新增调试：检查特定地址的读取情况
        if (addr_i == 32'h00000198 || addr_i == 32'h0000019c) begin
            // 确保地址对齐且在界内才访问数组
            if (byte_addr[1:0] == 2'b00 && word_addr < INSTR_MEM_WORDS) begin
                $display("[INSTR_MEM_DEBUG_LW_FETCH] Fetch Addr=0x%h (Word Addr=0x%h). Word read from instr_mem_words[0x%h]: 0x%h",
                         addr_i, word_addr, word_addr, instr_mem_words[word_addr]);
            end else begin
                // 编译器在此处报告错误，暂时注释掉此行以进行诊断
                // $display("[INSTR_MEM_DEBUG_LW_FETCH] Fetch Addr=0x%h (Word Addr=0x%h). Address out of bounds or misaligned for debug print.", addr_i, word_addr);
            end
        end

        if (byte_addr[1:0] != 2'b00) begin // 地址未对齐
            instr_o = `NOP_INSTRUCTION; 
            // Optional: $display("%t: [INSTR_MEM_WARN] Misaligned instruction fetch attempt at address 0x%h", $time, byte_addr);
        end else if (word_addr >= INSTR_MEM_WORDS) begin // 地址越界
            instr_o = `NOP_INSTRUCTION;
            // Optional: $display("%t: [INSTR_MEM_WARN] Out-of-bounds instruction fetch attempt at address 0x%h (word_addr %0d)", $time, byte_addr, word_addr);
        end else begin
            instr_o = instr_mem_words[word_addr];
        end
    end

endmodule
