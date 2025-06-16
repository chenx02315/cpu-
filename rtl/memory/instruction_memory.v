`timescale 1ns/1ps
`include "defines.v"

module instruction_memory (
    input  wire [31:0] addr_i,
    output wire [31:0] instr_o
);

    // 指令存储器参数
    parameter IMEM_SIZE = 1024;
    parameter IMEM_ADDR_WIDTH = 10;
    
    reg [31:0] imem [0:IMEM_SIZE-1];
    
    // 地址处理 - 字节地址转换为字地址
    wire [IMEM_ADDR_WIDTH-1:0] word_addr = addr_i[IMEM_ADDR_WIDTH+1:2];
    wire addr_valid = (addr_i[IMEM_ADDR_WIDTH+1:2] < IMEM_SIZE);
    
    // 加载测试用例
    initial begin
        integer i;
        integer non_nop_count;  // 移到最开始声明
        reg hex_loaded;
        
        $display("指令存储器开始初始化...");
        hex_loaded = 1'b0;
        
        // 首先清零
        for (i = 0; i < IMEM_SIZE; i = i + 1) begin
            imem[i] = 32'h00000013; // NOP (addi x0, x0, 0)
        end
        
        // 尝试从hex文件加载
        if ($test$plusargs("load_hex")) begin
            $display("尝试从hex文件加载测试用例...");
            // 尝试多个可能的路径
            if ($fopen("test/riscv_case/riscv.hex", "r") != 0) begin
                $readmemh("test/riscv_case/riscv.hex", imem);
                hex_loaded = 1'b1;
                $display("✓ 从test目录加载hex文件成功");
            end else if ($fopen("../test/riscv_case/riscv.hex", "r") != 0) begin
                $readmemh("../test/riscv_case/riscv.hex", imem);
                hex_loaded = 1'b1;
                $display("✓ 从上级test目录加载hex文件成功");
            end else begin
                $display("⚠ 无法找到hex文件，使用内置测试指令");
            end
        end
        
        // 如果hex文件加载失败，使用与riscv.hex完全一致的测试指令序列
        if (!hex_loaded) begin
            $display("使用标准RISC-V测试指令序列 (与riscv.hex完全一致)...");
            
            // === 完整的指令序列 (来自riscv.hex) ===
            imem[  0] = 32'h745670b7;  // 第  1行 - lui x1, 0x74567
            imem[  1] = 32'h29869137;  // 第  2行 - lui x2, 0x29869
            imem[  2] = 32'hf0c511b7;  // 第  3行 - lui x3, 0xf0c51
            imem[  3] = 32'h8944a237;  // 第  4行 - lui x4, 0x8944a
            imem[  4] = 32'h71f292b7;  // 第  5行 - lui x5, 0x71f29
            imem[  5] = 32'h858ba337;  // 第  6行 - lui x6, 0x858ba
            imem[  6] = 32'hc41f23b7;  // 第  7行 - lui x7, 0xc41f2
            imem[  7] = 32'h6a9e3437;  // 第  8行 - lui x8, 0x6a9e3
            imem[  8] = 32'h800004b7;  // 第  9行 - lui x9, 0x80000
            imem[  9] = 32'h80000537;  // 第 10行 - lui x10, 0x80000
            imem[ 10] = 32'h6231b5b7;  // 第 11行 - lui x11, 0x6231b
            imem[ 11] = 32'h0cde7637;  // 第 12行 - lui x12, 0x0cde7
            imem[ 12] = 32'he0f766b7;  // 第 13行 - lui x13, 0xe0f76
            imem[ 13] = 32'h5f92e737;  // 第 14行 - lui x14, 0x5f92e
            imem[ 14] = 32'hcc2337b7;  // 第 15行 - lui x15, 0xcc233
            imem[ 15] = 32'h7c4c9837;  // 第 16行 - lui x16, 0x7c4c9
            imem[ 16] = 32'hafb668b7;  // 第 17行 - lui x17, 0xafb66
            imem[ 17] = 32'hb500d937;  // 第 18行 - lui x18, 0xb500d
            imem[ 18] = 32'hdba319b7;  // 第 19行 - lui x19, 0xdba31
            imem[ 19] = 32'h130a3a37;  // 第 20行 - lui x20, 0x130a3
            // --- 第20条指令 ---
            imem[ 20] = 32'hc6125ab7;  // 第 21行 - lui x21, 0xc6125
            imem[ 21] = 32'hab105b37;  // 第 22行 - lui x22, 0xab105
            imem[ 22] = 32'h3a858bb7;  // 第 23行 - lui x23, 0x3a858
            imem[ 23] = 32'h3845ec37;  // 第 24行 - lui x24, 0x3845e
            imem[ 24] = 32'hdbdabcb7;  // 第 25行 - lui x25, 0xdbdab
            imem[ 25] = 32'h3d0cdd37;  // 第 26行 - lui x26, 0x3d0cd
            imem[ 26] = 32'ha769bdb7;  // 第 27行 - lui x27, 0xa769b
            imem[ 27] = 32'h32454e37;  // 第 28行 - lui x28, 0x32454
            imem[ 28] = 32'h6c40eeb7;  // 第 29行 - lui x29, 0x6c40e
            imem[ 29] = 32'h5f874f37;  // 第 30行 - lui x30, 0x5f874
            imem[ 30] = 32'h00000fb7;  // 第 31行 - lui x31, 0x0
            imem[ 31] = 32'h3c608093;  // 第 32行 - addi x1,x1,966
            imem[ 32] = 32'h87310113;  // 第 33行 - addi x2,x2,-1933
            imem[ 33] = 32'hcff18193;  // 第 34行 - addi x3,x3,-769
            imem[ 34] = 32'h8ec20213;  // 第 35行 - addi x4,x4,-1812
            imem[ 35] = 32'hccd28293;  // 第 36行 - addi x5,x5,-819
            imem[ 36] = 32'h7ab30313;  // 第 37行 - addi x6,x6,1963
            imem[ 37] = 32'hefb38393;  // 第 38行 - addi x7,x7,-261
            imem[ 38] = 32'h14640413;  // 第 39行 - addi x8,x8,326
            imem[ 39] = 32'hfff48493;  // 第 40行 - addi x9,x9,-1
            // --- 第40条指令 ---
            imem[ 40] = 32'h00150513;  // 第 41行 - addi x10,x10,1
            imem[ 41] = 32'h9e858593;  // 第 42行 - addi x11,x11,-1560
            imem[ 42] = 32'h38d60613;  // 第 43行 - addi x12,x12,909
            imem[ 43] = 32'h55a68693;  // 第 44行 - addi x13,x13,1370
            imem[ 44] = 32'h26370713;  // 第 45行 - addi x14,x14,611
            imem[ 45] = 32'h79f78793;  // 第 46行 - addi x15,x15,1951
            imem[ 46] = 32'h79a80813;  // 第 47行 - addi x16,x16,1946
            imem[ 47] = 32'hd3288893;  // 第 48行 - addi x17,x17,-718
            imem[ 48] = 32'h7b790913;  // 第 49行 - addi x18,x18,1975
            imem[ 49] = 32'h45898993;  // 第 50行 - addi x19,x19,1112
            imem[ 50] = 32'h95aa0a13;  // 第 51行 - addi x20,x20,-1702
            imem[ 51] = 32'h95da8a93;  // 第 52行 - addi x21,x21,-1699
            imem[ 52] = 32'h317b0b13;  // 第 53行 - addi x22,x22,791
            imem[ 53] = 32'hae9b8b93;  // 第 54行 - addi x23,x23,-1303
            imem[ 54] = 32'h8d4c0c13;  // 第 55行 - addi x24,x24,-1827
            imem[ 55] = 32'hcb2c8c93;  // 第 56行 - addi x25,x25,-846
            imem[ 56] = 32'h0c6d0d13;  // 第 57行 - addi x26,x26,198
            imem[ 57] = 32'heb4d8d93;  // 第 58行 - addi x27,x27,-332
            imem[ 58] = 32'h611e0e13;  // 第 59行 - addi x28,x28,1553
            imem[ 59] = 32'hd82e8e93;  // 第 60行 - addi x29,x29,-638
            // --- 第60条指令 ---
            imem[ 60] = 32'h641f0f13;  // 第 61行 - addi x30,x30,1601
            imem[ 61] = 32'hfb0f8f93;  // 第 62行 - addi x31,x31,-80
            imem[ 62] = 32'h00000013;  // 第 63行 - NOP
            imem[ 63] = 32'h00000013;  // 第 64行 - NOP
            imem[ 64] = 32'h00000013;  // 第 65行 - NOP
            imem[ 65] = 32'h00000013;  // 第 66行 - NOP
            imem[ 66] = 32'h00000013;  // 第 67行 - NOP
            imem[ 67] = 32'h002080b3;  // 第 68行 - add x1,x1,x2
            imem[ 68] = 32'h00418133;  // 第 69行 - add x2,x3,x4
            imem[ 69] = 32'h406281b3;  // 第 70行 - sub x3,x5,x6
            imem[ 70] = 32'h40838233;  // 第 71行 - sub x4,x7,x8
            imem[ 71] = 32'h12348293;  // 第 72行 - addi x5,x9,291
            imem[ 72] = 32'habc50313;  // 第 73行 - addi x6,x10,-1348
            imem[ 73] = 32'h0083f3b3;  // 第 74行 - and x7,x7,x8
            imem[ 74] = 32'h00946433;  // 第 75行 - or x8,x8,x9
            imem[ 75] = 32'h00c5c4b3;  // 第 76行 - xor x9,x11,x12
            imem[ 76] = 32'h00b59533;  // 第 77行 - sll x10,x11,x11
            imem[ 77] = 32'h00d655b3;  // 第 78行 - srl x11,x12,x13
            imem[ 78] = 32'h40e6d633;  // 第 79行 - sra x12,x13,x14
            imem[ 79] = 32'h00f726b3;  // 第 80行 - slt x13,x14,x15
            // --- 第80条指令 ---
            imem[ 80] = 32'h0107a733;  // 第 81行 - slt x14,x15,x16
            imem[ 81] = 32'h0108b7b3;  // 第 82行 - sltu x15,x17,x16
            imem[ 82] = 32'h01183833;  // 第 83行 - sll x16,x16,x17
            imem[ 83] = 32'hca397893;  // 第 84行 - andi x17,x18,-861
            imem[ 84] = 32'h80696913;  // 第 85行 - ori x18,x18,-2042
            imem[ 85] = 32'h2579c993;  // 第 86行 - xori x19,x19,599
            imem[ 86] = 32'hc9302a13;  // 第 87行 - slti x20,x0,-877
            imem[ 87] = 32'h7ff02a93;  // 第 88行 - sltiu x21,x0,2047
            imem[ 88] = 32'h000b3b13;  // 第 89行 - sltiu x22,x22,0
            imem[ 89] = 32'h9d1c3b93;  // 第 90行 - sltiu x23,x24,-623
            imem[ 90] = 32'h010c1c13;  // 第 91行 - slli x24,x24,16
            imem[ 91] = 32'h015d5c93;  // 第 92行 - srli x25,x26,21
            imem[ 92] = 32'h409ddd13;  // 第 93行 - srai x26,x27,9
            imem[ 93] = 32'h03cd8db3;  // 第 94行 - mul x27,x27,x25 (原注释 mul x27,x27,x28 是错误的)
            imem[ 94] = 32'h00000013;  // 第 95行 - NOP
            imem[ 95] = 32'h00000013;  // 第 96行 - NOP
            imem[ 96] = 32'h00000013;  // 第 97行 - NOP
            imem[ 97] = 32'h00000013;  // 第 98行 - NOP
            imem[ 98] = 32'h00000013;  // 第 99行 - NOP
            imem[ 99] = 32'h10006e13;  // 第100行 - ori x28,x0,256
            // --- 第100条指令 ---
            
            // 继续完整的指令序列...
            imem[100] = 32'h00000013;  // 第101行 - NOP
            imem[101] = 32'h00000013;  // 第102行 - NOP
            imem[102] = 32'h00000013;  // 第103行 - NOP
            imem[103] = 32'h00000013;  // 第104行 - NOP
            imem[104] = 32'h00000013;  // 第105行 - NOP
            imem[105] = 32'h002e2223;  // 第106行 - sw x2,4(x28)
            imem[106] = 32'h00000013;  // 第107行 - NOP
            imem[107] = 32'h00000013;  // 第108行 - NOP
            imem[108] = 32'h00000013;  // 第109行 - NOP
            imem[109] = 32'h00000013;  // 第110行 - NOP
            imem[110] = 32'h00000013;  // 第111行 - NOP
            imem[111] = 32'h003e1323;  // 第112行 - sh x3,6(x28)
            imem[112] = 32'h00000013;  // 第113行 - NOP
            imem[113] = 32'h00000013;  // 第114行 - NOP
            imem[114] = 32'h00000013;  // 第115行 - NOP
            imem[115] = 32'h00000013;  // 第116行 - NOP
            imem[116] = 32'h00000013;  // 第117行 - NOP
            imem[117] = 32'h004e03a3;  // 第118行 - sb x4,7(x28)
            imem[118] = 32'h00000013;  // 第119行 - NOP
            imem[119] = 32'h00000013;  // 第120行 - NOP
            // --- 第120条指令 ---
            imem[120] = 32'h00000013;  // 第121行 - NOP
            imem[121] = 32'h00000013;  // 第122行 - NOP
            imem[122] = 32'h00000013;  // 第123行 - NOP
            imem[123] = 32'hfece2e23;  // 第124行 - sw x14,-4(x28)
            imem[124] = 32'h00000013;  // 第125行 - NOP
            imem[125] = 32'h00000013;  // 第126行 - NOP
            imem[126] = 32'h00000013;  // 第127行 - NOP
            imem[127] = 32'h00000013;  // 第128行 - NOP
            imem[128] = 32'h00000013;  // 第129行 - NOP
            imem[129] = 32'h12028e63;  // 第130行 - beq x5,x0,292
            imem[130] = 32'h14000063;  // 第131行 - beq x0,x0,320
            imem[131] = 32'h14001263;  // 第132行 - bne x0,x0,324
            imem[132] = 32'h14029463;  // 第133行 - bne x5,x0,328
            imem[133] = 32'h14004663;  // 第134行 - blt x0,x0,332
            imem[134] = 32'h1402c863;  // 第135行 - blt x5,x0,336
            imem[135] = 32'h1402ea63;  // 第136行 - blt x5,x0,340
            imem[136] = 32'h14506c63;  // 第137行 - blt x0,x5,344
            imem[137] = 32'h1402de63;  // 第138行 - bge x5,x0,348
            imem[138] = 32'h16505063;  // 第139行 - bge x0,x5,352
            imem[139] = 32'h16507263;  // 第140行 - bgeu x0,x5,356
            // --- 第140条指令 ---
            imem[140] = 32'h1602f463;  // 第141行 - bgeu x5,x0,360
            imem[141] = 32'h00000013;  // 第142行 - NOP
            imem[142] = 32'h00000013;  // 第143行 - NOP
            imem[143] = 32'h00000013;  // 第144行 - NOP
            imem[144] = 32'h00000013;  // 第145行 - NOP
            imem[145] = 32'h00000013;  // 第146行 - NOP
            imem[146] = 32'h00000013;  // 第147行 - NOP
            imem[147] = 32'h004e2e83;  // 第148行 - lw x29,4(x28)
            imem[148] = 32'h00000013;  // 第149行 - NOP
            imem[149] = 32'h00000013;  // 第150行 - NOP
            imem[150] = 32'h00000013;  // 第151行 - NOP
            imem[151] = 32'h00000013;  // 第152行 - NOP
            imem[152] = 32'h00000013;  // 第153行 - NOP
            imem[153] = 32'h01df0f33;  // 第154行 - add x30,x30,x29
            imem[154] = 32'h00000013;  // 第155行 - NOP
            imem[155] = 32'h00000013;  // 第156行 - NOP
            imem[156] = 32'h00000013;  // 第157行 - NOP
            imem[157] = 32'h00000013;  // 第158行 - NOP
            imem[158] = 32'h00000013;  // 第159行 - NOP
            imem[159] = 32'hffee1e83;  // 第160行 - lh x29,-2(x28)
            // --- 第160条指令 ---
            imem[160] = 32'h00000013;  // 第161行 - NOP
            imem[161] = 32'h00000013;  // 第162行 - NOP
            imem[162] = 32'h00000013;  // 第163行 - NOP
            imem[163] = 32'h00000013;  // 第164行 - NOP
            imem[164] = 32'h00000013;  // 第165行 - NOP
            imem[165] = 32'h01df0f33;  // 第166行 - add x30,x30,x29
            imem[166] = 32'h00000013;  // 第167行 - NOP
            imem[167] = 32'h00000013;  // 第168行 - NOP
            imem[168] = 32'h00000013;  // 第169行 - NOP
            imem[169] = 32'h00000013;  // 第170行 - NOP
            imem[170] = 32'h00000013;  // 第171行 - NOP
            imem[171] = 32'hffee5e83;  // 第172行 - lhu x29,-2(x28)
            imem[172] = 32'h00000013;  // 第173行 - NOP
            imem[173] = 32'h00000013;  // 第174行 - NOP
            imem[174] = 32'h00000013;  // 第175行 - NOP
            imem[175] = 32'h00000013;  // 第176行 - NOP
            imem[176] = 32'h00000013;  // 第177行 - NOP
            imem[177] = 32'h01df0f33;  // 第178行 - add x30,x30,x29
            imem[178] = 32'h00000013;  // 第179行 - NOP
            imem[179] = 32'h00000013;  // 第180行 - NOP
            // --- 第180条指令 ---
            imem[180] = 32'h00000013;  // 第181行 - NOP
            imem[181] = 32'h00000013;  // 第182行 - NOP
            imem[182] = 32'h00000013;  // 第183行 - NOP
            imem[183] = 32'hfffe0e83;  // 第184行 - lb x29,-1(x28)
            imem[184] = 32'h00000013;  // 第185行 - NOP
            imem[185] = 32'h00000013;  // 第186行 - NOP
            imem[186] = 32'h00000013;  // 第187行 - NOP
            imem[187] = 32'h00000013;  // 第188行 - NOP
            imem[188] = 32'h00000013;  // 第189行 - NOP
            imem[189] = 32'h01df0f33;  // 第190行 - add x30,x30,x29
            imem[190] = 32'h00000013;  // 第191行 - NOP
            imem[191] = 32'h00000013;  // 第192行 - NOP
            imem[192] = 32'h00000013;  // 第193行 - NOP
            imem[193] = 32'h00000013;  // 第194行 - NOP
            imem[194] = 32'h00000013;  // 第195行 - NOP
            imem[195] = 32'hfffe4e83;  // 第196行 - lbu x29,-1(x28)
            imem[196] = 32'h00000013;  // 第197行 - NOP
            imem[197] = 32'h00000013;  // 第198行 - NOP
            imem[198] = 32'h00000013;  // 第199行 - NOP
            imem[199] = 32'h00000013;  // 第200行 - NOP
            // --- 第200条指令 ---
            imem[200] = 32'h00000013;  // 第201行 - NOP
            imem[201] = 32'h01df0f33;  // 第202行 - add x30,x30,x29
            imem[202] = 32'h001f8f93;  // 第203行 - addi x31,x31,1
            imem[203] = 32'h00000013;  // 第204行 - NOP
            imem[204] = 32'h00000013;  // 第205行 - NOP
            imem[205] = 32'h00000013;  // 第206行 - NOP
            imem[206] = 32'h00000013;  // 第207行 - NOP
            imem[207] = 32'h00000013;  // 第208行 - NOP
            imem[208] = 32'h001f8f93;  // 第209行 - addi x31,x31,1
            imem[209] = 32'hec0002e3;  // 第210行 - beq x0,x0,-320
            imem[210] = 32'h003f8f93;  // 第211行 - addi x31,x31,3
            imem[211] = 32'hec0000e3;  // 第212行 - beq x0,x0,-320
            imem[212] = 32'h005f8f93;  // 第213行 - addi x31,x31,5
            imem[213] = 32'hea000ee3;  // 第214行 - beq x0,x0,-324
            imem[214] = 32'h007f8f93;  // 第215行 - addi x31,x31,7
            imem[215] = 32'hea000ce3;  // 第216行 - beq x0,x0,-324
            imem[216] = 32'h009f8f93;  // 第217行 - addi x31,x31,9
            imem[217] = 32'hea000ae3;  // 第218行 - beq x0,x0,-324
            imem[218] = 32'h00bf8f93;  // 第219行 - addi x31,x31,11
            imem[219] = 32'hea0008e3;  // 第220行 - beq x0,x0,-324
            // --- 第220条指令 ---
            imem[220] = 32'h00df8f93;  // 第221行 - addi x31,x31,13
            imem[221] = 32'hea0006e3;  // 第222行 - beq x0,x0,-324
            imem[222] = 32'h00ff8f93;  // 第223行 - addi x31,x31,15
            imem[223] = 32'hea0004e3;  // 第224行 - beq x0,x0,-324
            imem[224] = 32'h011f8f93;  // 第225行 - addi x31,x31,17
            imem[225] = 32'hea0002e3;  // 第226行 - beq x0,x0,-324
            imem[226] = 32'h013f8f93;  // 第227行 - addi x31,x31,19
            imem[227] = 32'hea0000e3;  // 第228行 - beq x0,x0,-324
            imem[228] = 32'h015f8f93;  // 第229行 - addi x31,x31,21
            imem[229] = 32'he8000ee3;  // 第230行 - beq x0,x0,-328
            imem[230] = 32'h017f8f93;  // 第231行 - addi x31,x31,23
            imem[231] = 32'he8000ce3;  // 第232行 - beq x0,x0,-328

            // 剩余位置填充NOP (从第232条开始)
            for (i = 232; i < IMEM_SIZE; i = i + 1) begin
                imem[i] = 32'h00000013;  // NOP
            end
        end

        // 验证指令加载情况
        $display("=== 指令加载验证 ===");
        $display("总指令数: %d", IMEM_SIZE);
        if (hex_loaded) begin
            $display("✓ 使用标准hex文件测试集");
        end else begin
            $display("✓ 使用内置标准测试指令集");
        end
        
        // 显示关键指令检查点
        $display("前10条指令验证:");
        for (i = 0; i < 10; i = i + 1) begin
            $display("  [0x%03x]: 0x%08x %s", i*4, imem[i], 
                    (imem[i] == 32'h00000013) ? "(NOP)" : 
                    (imem[i][6:0] == 7'b0110111) ? "(LUI)" :
                    (imem[i][6:0] == 7'b0010011) ? "(ADDI/IMM)" :
                    (imem[i][6:0] == 7'b0110011) ? "(ARITH)" :
                    (imem[i][6:0] == 7'b0100011) ? "(STORE)" :
                    (imem[i][6:0] == 7'b0000011) ? "(LOAD)" : "(OTHER)");
        end
        
        // 新增：验证后续关键指令点
        $display("关键指令点验证:");
        $display("  [0x%03x]: 0x%08x (第100条)", 100*4, imem[100]);
        $display("  [0x%03x]: 0x%08x (第150条)", 150*4, imem[150]);
        $display("  [0x%03x]: 0x%08x (第200条)", 200*4, imem[200]);
        $display("  [0x%03x]: 0x%08x (第230条)", 230*4, imem[230]);
        
        // 统计非NOP指令数量
        non_nop_count = 0;
        for (i = 0; i < 232; i = i + 1) begin
            if (imem[i] != 32'h00000013) begin
                non_nop_count = non_nop_count + 1;
            end
        end
        $display("前232条指令中非NOP指令数: %d", non_nop_count);
        
        $display("指令存储器初始化完成");
    end
    
    // 读取指令
    assign instr_o = addr_valid ? imem[word_addr] : 32'h00000013;

endmodule
