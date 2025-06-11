#!/usr/bin/env python3

def parse_hex_file(hex_file_path):
    """解析hex文件并生成Verilog指令数组"""
    instructions = []
    
    try:
        with open(hex_file_path, 'r') as f:
            for line_num, line in enumerate(f):
                line = line.strip()
                if line and not line.startswith('//'):
                    # 确保是8位十六进制数
                    if len(line) == 8:
                        instructions.append((line_num, f"32'h{line}"))
                    else:
                        print(f"警告: 第{line_num+1}行格式不正确: {line}")
    except FileNotFoundError:
        print(f"错误: 找不到文件 {hex_file_path}")
        return []
    
    return instructions

def generate_verilog_instructions(instructions):
    """生成Verilog指令赋值语句"""
    print("// === 完整的指令序列 (来自riscv.hex) ===")
    
    for i, (line_num, instr_hex) in enumerate(instructions):
        print(f"            imem[{i:3d}] = {instr_hex};  // 第{line_num+1:3d}行")
        
        # 每20条指令添加一个分组注释
        if (i + 1) % 20 == 0:
            print(f"            // --- 第{i+1}条指令 ---")
    
    # 剩余位置填充NOP
    total_instructions = len(instructions)
    print(f"""
            // 剩余位置填充NOP (从第{total_instructions}条开始)
            for (i = {total_instructions}; i < IMEM_SIZE; i = i + 1) begin
                imem[i] = 32'h00000013;  // NOP
            end""")

def main():
    hex_file = "test/riscv_case/riscv.hex"
    
    print("正在解析hex文件...")
    instructions = parse_hex_file(hex_file)
    
    if instructions:
        print(f"成功解析 {len(instructions)} 条指令")
        print("\n生成Verilog代码:")
        print("="*60)
        generate_verilog_instructions(instructions)
        print("="*60)
    else:
        print("解析失败或文件为空")

if __name__ == "__main__":
    main()
