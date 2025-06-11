#!/bin/bash

#================================================
# RISC-V CPU 自动化测试脚本
#================================================

# 脚本配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_LOG="$PROJECT_ROOT/simulation_output/test_result.log"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$TEST_LOG"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1" | tee -a "$TEST_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$TEST_LOG"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1" | tee -a "$TEST_LOG"
}

# 初始化测试环境
init_test() {
    log_info "初始化测试环境..."
    cd "$PROJECT_ROOT"
    
    # 创建输出目录
    mkdir -p simulation_output
    
    # 清理旧的日志
    > "$TEST_LOG"
    
    log_info "项目根目录: $PROJECT_ROOT"
    log_info "测试日志: $TEST_LOG"
}

# 检查环境
check_environment() {
    log_info "检查仿真环境..."
    
    # 检查VCS
    if ! command -v vcs &> /dev/null; then
        log_error "VCS 未找到，请检查安装和环境变量"
        return 1
    fi
    log_success "VCS 环境正常"
    
    # 检查Verdi
    if ! command -v verdi &> /dev/null; then
        log_warning "Verdi 未找到，无法查看波形"
    else
        log_success "Verdi 环境正常"
    fi
    
    # 检查源文件
    local rtl_files=(rtl/*.v rtl/*/*.v)
    local tb_files=(testbench/*.v)
    
    log_info "检查源文件..."
    for pattern in "${rtl_files[@]}" "${tb_files[@]}"; do
        if ! ls $pattern 1> /dev/null 2>&1; then
            log_error "源文件缺失: $pattern"
            return 1
        fi
    done
    log_success "源文件检查通过"
    
    return 0
}

# 运行编译
run_compile() {
    log_info "开始编译..."
    
    if make compile >> "$TEST_LOG" 2>&1; then
        log_success "编译成功"
        return 0
    else
        log_error "编译失败，查看日志获取详细信息"
        return 1
    fi
}

# 运行仿真
run_simulation() {
    log_info "开始仿真..."
    
    # 运行仿真并捕获输出
    if make sim >> "$TEST_LOG" 2>&1; then
        log_success "仿真完成"
        return 0
    else
        log_error "仿真失败，查看日志获取详细信息"
        return 1
    fi
}

# 检查仿真结果
check_results() {
    log_info "检查仿真结果..."
    
    local sim_log="simulation_output/simulation.log"
    
    if [ ! -f "$sim_log" ]; then
        log_error "仿真日志文件不存在: $sim_log"
        return 1
    fi
    
    # 检查是否完成所有测试阶段
    local test_stages=$(grep -c "检查点" "$sim_log" || echo "0")
    log_info "完成的测试检查点: $test_stages"
    
    # 检查是否有错误
    local error_count=$(grep -c "错误\|Error\|FAIL" "$sim_log" || echo "0")
    if [ "$error_count" -gt 0 ]; then
        log_error "发现 $error_count 个错误"
        return 1
    fi
    
    # 检查是否正常结束
    if grep -q "测试完成" "$sim_log"; then
        log_success "测试正常完成"
        return 0
    else
        log_warning "测试可能未完全完成"
        return 1
    fi
}

# 生成测试报告
generate_report() {
    log_info "生成测试报告..."
    
    local report_file="simulation_output/test_report.txt"
    
    cat > "$report_file" << EOF
========================================
RISC-V CPU 测试报告
生成时间: $(date)
========================================

测试环境:
- 项目路径: $PROJECT_ROOT
- VCS版本: $(vcs -ID 2>/dev/null | head -1 || echo "未知")
- Verdi版本: $(verdi -version 2>/dev/null | head -1 || echo "未知")

测试文件:
- RTL文件数: $(find rtl -name "*.v" | wc -l)
- 测试文件数: $(find testbench -name "*.v" | wc -l)

仿真结果:
EOF
    
    if [ -f "simulation_output/simulation.log" ]; then
        echo "- 检查点完成数: $(grep -c "检查点" simulation_output/simulation.log || echo "0")" >> "$report_file"
        echo "- 错误数: $(grep -c "错误\|Error\|FAIL" simulation_output/simulation.log || echo "0")" >> "$report_file"
        echo "- 总周期数: $(grep "总周期数" simulation_output/simulation.log | tail -1 | awk '{print $2}' || echo "未知")" >> "$report_file"
    fi
    
    echo "" >> "$report_file"
    echo "详细日志请查看: simulation_output/simulation.log" >> "$report_file"
    echo "波形文件: simulation_output/cpu_riscv_test.fsdb" >> "$report_file"
    
    log_success "测试报告已生成: $report_file"
}

# 清理功能
cleanup() {
    if [ "$1" == "all" ]; then
        log_info "清理所有文件..."
        make distclean >> "$TEST_LOG" 2>&1
    else
        log_info "清理编译产物..."
        make clean >> "$TEST_LOG" 2>&1
    fi
    log_success "清理完成"
}

# 主函数
main() {
    case "$1" in
        "compile")
            init_test
            check_environment && run_compile
            ;;
        "sim")
            init_test
            check_environment && run_compile && run_simulation && check_results
            ;;
        "all")
            init_test
            if check_environment && run_compile && run_simulation && check_results; then
                generate_report
                log_success "所有测试完成"
            else
                log_error "测试失败"
                exit 1
            fi
            ;;
        "clean")
            cleanup
            ;;
        "distclean")
            cleanup all
            ;;
        "report")
            generate_report
            ;;
        *)
            echo "用法: $0 {compile|sim|all|clean|distclean|report}"
            echo ""
            echo "  compile   - 仅编译"
            echo "  sim       - 编译并仿真"
            echo "  all       - 完整测试流程"
            echo "  clean     - 清理编译产物"
            echo "  distclean - 深度清理"
            echo "  report    - 生成测试报告"
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
