#!/usr/bin/env python3
"""
RISC-V CPU寄存器值对比分析工具
用于对比实际输出与标准答案的差异
"""

def parse_register_line(line):
    """解析寄存器行，返回寄存器字典"""
    registers = {}
    parts = line.split()
    for part in parts:
        if '=' in part:
            reg_name, value = part.split('=')
            registers[reg_name] = value
    return registers

def compare_registers():
    """对比寄存器值"""
    # 标准答案
    standard = {
        'x00': '0x00000000', 'x01': '0x9ddcfc39', 'x02': '0x7a09a5eb', 'x03': '0xec66e522',
        'x04': '0x5980edb5', 'x05': '0x80000122', 'x06': '0x7ffffabd', 'x07': '0x401e1042',
        'x08': '0x7fffffff', 'x09': '0x6eefda65', 'x10': '0x31a9e800', 'x11': '0x00000003',
        'x12': '0xfc1eecab', 'x13': '0x00000000', 'x14': '0x00000001', 'x15': '0x00000000',
        'x16': '0x00000001', 'x17': '0xb500d4a3', 'x18': '0xffffffb7', 'x19': '0xdba3160f',
        'x20': '0x00000000', 'x21': '0x00000001', 'x22': '0x00000000', 'x23': '0x00000001',
        'x24': '0xd8d40000', 'x25': '0x000001e8', 'x26': '0xffd3b4d7', 'x27': '0x424dd1f4',
        'x28': '0x00000100', 'x29': '0x000000fc', 'x30': '0x14aae560', 'x31': '0xffffffff'
    }
    
    # 实际输出
    actual = {
        'x00': '0x00000000', 'x01': '0x9ddcfc39', 'x02': '0x7a09a5eb', 'x03': '0xec66e522',
        'x04': '0xd7b839d9', 'x05': '0x80000122', 'x06': '0x7ffffabd', 'x07': '0x401e1042',
        'x08': '0x7fffffff', 'x09': '0x6eefda65', 'x10': '0x31a9e800', 'x11': '0x00000003',
        'x12': '0xfc1eecab', 'x13': '0x00000000', 'x14': '0x00000001', 'x15': '0x00000000',
        'x16': '0x00000001', 'x17': '0xb500d4a3', 'x18': '0xffffffb7', 'x19': '0xdba3160f',
        'x20': '0x00000000', 'x21': '0x00000001', 'x22': '0x00000000', 'x23': '0x00000001',
        'x24': '0xd8d40000', 'x25': '0x000001e8', 'x26': '0xffd3b4d7', 'x27': '0x424dd1f4',
        'x28': '0x00000100', 'x29': '0x6c40dd82', 'x30': '0x5f874641', 'x31': '0xffffffe7'
    }
    
    print("=" * 80)
    print("RISC-V CPU 寄存器值对比分析")
    print("=" * 80)
    print(f"{'寄存器':<6} {'标准答案':<12} {'实际输出':<12} {'状态':<6} {'差值':<12}")
    print("-" * 80)
    
    differences = []
    matches = 0
    
    for reg in sorted(standard.keys()):
        std_val = standard[reg]
        act_val = actual[reg]
        
        if std_val == act_val:
            status = "✓"
            matches += 1
            diff = "0"
        else:
            status = "✗"
            differences.append(reg)
            # 计算差值
            try:
                std_int = int(std_val, 16)
                act_int = int(act_val, 16)
                diff_val = act_int - std_int
                if diff_val >= 0:
                    diff = f"+0x{diff_val:08x}"
                else:
                    diff = f"-0x{-diff_val:08x}"
            except:
                diff = "N/A"
        
        print(f"{reg:<6} {std_val:<12} {act_val:<12} {status:<6} {diff:<12}")
    
    print("-" * 80)
    print(f"匹配数量: {matches}/32")
    print(f"不匹配数量: {len(differences)}/32")
    print(f"匹配率: {matches/32*100:.1f}%")
    
    if differences:
        print(f"\n不匹配的寄存器: {', '.join(differences)}")
        
        print("\n详细分析:")
        for reg in differences:
            std_val = standard[reg]
            act_val = actual[reg]
            print(f"\n{reg}: 标准 {std_val} vs 实际 {act_val}")
            
            # 二进制对比
            std_int = int(std_val, 16)
            act_int = int(act_val, 16)
            std_bin = f"{std_int:032b}"
            act_bin = f"{act_int:032b}"
            
            print(f"  标准(bin): {std_bin}")
            print(f"  实际(bin): {act_bin}")
            
            # 找出不同的位
            diff_bits = []
            for i in range(32):
                if std_bin[i] != act_bin[i]:
                    bit_pos = 31 - i
                    diff_bits.append(str(bit_pos))
            
            if diff_bits:
                print(f"  不同位: {', '.join(diff_bits)}")
    
    print("\n" + "=" * 80)
    
    # 问题分析建议
    print("问题分析建议:")
    if 'x04' in differences:
        print("- x4差异可能源于SUB指令或算术运算错误")
    if 'x29' in differences:
        print("- x29差异可能与内存操作或地址计算有关")
    if 'x30' in differences:
        print("- x30差异可能与累加操作或内存加载有关")
    if 'x31' in differences:
        print("- x31差异可能与计数器或循环逻辑有关")
    
    print("\n建议检查:")
    print("1. ALU减法运算逻辑")
    print("2. 内存加载/存储指令实现")
    print("3. 分支跳转条件判断")
    print("4. 寄存器写入时序")

if __name__ == "__main__":
    compare_registers()
