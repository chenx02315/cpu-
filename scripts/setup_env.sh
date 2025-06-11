#!/bin/bash

#================================================
# RISC-V CPU 仿真环境设置脚本
#================================================

echo "========================================="
echo "RISC-V CPU 仿真环境设置"
echo "========================================="

# 设置工作目录
export PROJECT_ROOT="/home/jiangchuanc/Desktop/Design_CPU"
export SIM_DIR="$PROJECT_ROOT/simulation_output"

# 检查VCS环境
if command -v vcs &> /dev/null; then
    echo "✓ VCS 已安装: $(which vcs)"
    vcs -ID | head -1
else
    echo "✗ VCS 未找到，请检查安装和环境变量"
    echo "  可能需要source VCS环境脚本"
    exit 1
fi

# 检查Verdi环境
if command -v verdi &> /dev/null; then
    echo "✓ Verdi 已安装: $(which verdi)"
    verdi -version | head -1
else
    echo "✗ Verdi 未找到，请检查安装和环境变量"
    echo "  可能需要source Verdi环境脚本"
fi

# 检查许可证
echo ""
echo "检查许可证状态..."
if command -v lmstat &> /dev/null; then
    lmstat -a | grep -E "(vcs|verdi)" | head -5
else
    echo "无法检查许可证状态 (lmstat未找到)"
fi

# 创建必要目录
echo ""
echo "创建项目目录..."
mkdir -p "$SIM_DIR"
mkdir -p "$PROJECT_ROOT/test/riscv_case"

# 检查测试文件
echo ""
echo "检查测试文件..."
if [ -f "$PROJECT_ROOT/test/riscv_case/riscv.hex" ]; then
    echo "✓ 找到测试文件: riscv.hex"
    echo "  大小: $(wc -l < $PROJECT_ROOT/test/riscv_case/riscv.hex) 行"
else
    echo "⚠ 测试文件不存在: test/riscv_case/riscv.hex"
    echo "  将使用内置测试指令"
fi

# 检查RTL文件
echo ""
echo "检查RTL文件..."
rtl_count=0
for file in rtl/*.v rtl/*/*.v; do
    if [ -f "$file" ]; then
        rtl_count=$((rtl_count + 1))
    fi
done
echo "✓ 找到 $rtl_count 个RTL文件"

# 检查测试文件
if [ -f "testbench/cpu_riscv_tb.v" ]; then
    echo "✓ 找到测试平台: cpu_riscv_tb.v"
else
    echo "✗ 测试平台不存在: testbench/cpu_riscv_tb.v"
fi

echo ""
echo "========================================="
echo "环境设置完成"
echo "========================================="
echo "使用方法:"
echo "  make help     - 查看可用命令"
echo "  make sim      - 运行仿真"
echo "  make wave     - 查看波形"
echo "========================================="
