#================================================
# RISC-V CPU 仿真 Makefile (VCS + Verdi)
#================================================

# 项目配置
PROJECT_NAME = riscv_cpu
TOP_MODULE = cpu_riscv_tb
WORK_DIR = $(PWD)
SIM_DIR = simulation_output
TEST_DIR = test

# 工具配置
VCS = vcs
VERDI = verdi
VCS_FLAGS = -full64 -debug_access+all -kdb -lca -sverilog +v2k
VERDI_FLAGS = -full64 -sv

# 文件配置
FSDB_FILE = $(SIM_DIR)/cpu_riscv_test.fsdb
VCD_FILE = $(SIM_DIR)/cpu_riscv_test.vcd
LOG_FILE = $(SIM_DIR)/simulation.log
EXECUTABLE = $(SIM_DIR)/$(PROJECT_NAME)

# RTL源文件
RTL_SOURCES = \
	rtl/defines.v \
	rtl/alu.v \
	rtl/multiplier.v \
	rtl/immediate_generator.v \
	rtl/ex_alu_mul_mux.v \
	rtl/control_unit.v \
	rtl/register_file.v \
	rtl/memory/instruction_memory.v \
	rtl/memory/data_memory.v \
	rtl/pipeline_stages/if_stage.v \
	rtl/pipeline_stages/id_stage.v \
	rtl/pipeline_stages/ex_stage.v \
	rtl/pipeline_stages/mem_stage.v \
	rtl/pipeline_stages/wb_stage.v \
	rtl/pipeline_registers/if_id_register.v \
	rtl/pipeline_registers/id_ex_register.v \
	rtl/pipeline_registers/ex_mem_register.v \
	rtl/pipeline_registers/mem_wb_register.v \
	rtl/pc_logic.v \
	rtl/hazard_unit.v \
	rtl/cpu_top.v

# 测试文件
TB_SOURCES = testbench/cpu_riscv_tb.v

# 所有源文件
ALL_SOURCES = $(RTL_SOURCES) $(TB_SOURCES)

# 编译选项
COMPILE_OPTS = +define+VCS_SIM +incdir+rtl +incdir+testbench

# 仿真选项
SIM_OPTS = +load_hex +fsdbfile=$(FSDB_FILE)

#================================================
# 主要目标
#================================================

.PHONY: all clean compile sim wave debug lint help prepare_test

# 默认目标
all: sim

# 准备测试环境
prepare_test:
	@echo "准备测试环境..."
	@mkdir -p $(SIM_DIR)
	@mkdir -p $(TEST_DIR)
	@if [ ! -f $(TEST_DIR)/riscv_case/riscv.hex ]; then \
		echo "警告: 测试文件 $(TEST_DIR)/riscv_case/riscv.hex 不存在"; \
		echo "将使用内置测试指令"; \
	else \
		echo "找到测试文件: $(TEST_DIR)/riscv_case/riscv.hex"; \
		cp $(TEST_DIR)/riscv_case/riscv.hex $(SIM_DIR)/; \
	fi

# 编译
compile: prepare_test $(EXECUTABLE)

$(EXECUTABLE): $(ALL_SOURCES)
	@echo "========================================="
	@echo "开始VCS编译..."
	@echo "========================================="
	@mkdir -p $(SIM_DIR)
	$(VCS) $(VCS_FLAGS) \
		-o $(EXECUTABLE) \
		-top $(TOP_MODULE) \
		$(COMPILE_OPTS) \
		$(ALL_SOURCES) \
		2>&1 | tee $(SIM_DIR)/compile.log
	@if [ $$? -eq 0 ]; then \
		echo "✓ 编译成功!"; \
	else \
		echo "✗ 编译失败，查看 $(SIM_DIR)/compile.log"; \
		exit 1; \
	fi

# 仿真
sim: $(EXECUTABLE)
	@echo "========================================="
	@echo "开始仿真..."
	@echo "========================================="
	cd $(SIM_DIR) && \
	./$(notdir $(EXECUTABLE)) $(SIM_OPTS) 2>&1 | tee simulation.log
	@echo "仿真完成! 日志文件: $(LOG_FILE)"
	@if [ -f $(FSDB_FILE) ]; then \
		echo "波形文件: $(FSDB_FILE)"; \
	fi

# 快速仿真（不生成波形）
sim_fast: $(EXECUTABLE)
	@echo "开始快速仿真（无波形）..."
	cd $(SIM_DIR) && \
	./$(notdir $(EXECUTABLE)) +nofsdb 2>&1 | tee simulation_fast.log

# 详细仿真（指令跟踪）
sim_trace: $(EXECUTABLE)
	@echo "开始详细仿真（指令跟踪）..."
	cd $(SIM_DIR) && \
	./$(notdir $(EXECUTABLE)) $(SIM_OPTS) +trace_instr 2>&1 | tee simulation_trace.log

# 分支调试仿真
sim_branch: $(EXECUTABLE)
	@echo "开始分支调试仿真..."
	cd $(SIM_DIR) && \
	./$(notdir $(EXECUTABLE)) $(SIM_OPTS) +trace_branch 2>&1 | tee simulation_branch.log

# 全面调试仿真（指令+分支）
sim_debug: $(EXECUTABLE)
	@echo "开始全面调试仿真..."
	cd $(SIM_DIR) && \
	./$(notdir $(EXECUTABLE)) $(SIM_OPTS) +trace_instr +trace_branch 2>&1 | tee simulation_debug.log

# 查看波形 (Verdi)
wave: $(FSDB_FILE)
	@echo "启动Verdi波形查看器..."
	cd $(SIM_DIR) && \
	$(VERDI) $(VERDI_FLAGS) -ssf $(notdir $(FSDB_FILE)) &

# 查看波形 (GTKWave备用)
wave_gtk: $(VCD_FILE)
	@echo "启动GTKWave波形查看器..."
	gtkwave $(VCD_FILE) &

# 调试模式
debug: $(EXECUTABLE)
	@echo "启动调试模式..."
	cd $(SIM_DIR) && \
	$(VERDI) $(VERDI_FLAGS) -kdb &
	cd $(SIM_DIR) && \
	./$(notdir $(EXECUTABLE)) $(SIM_OPTS) +interactive

# 语法检查
lint:
	@echo "开始语法检查..."
	$(VCS) -lint $(VCS_FLAGS) $(COMPILE_OPTS) $(RTL_SOURCES) -top cpu_top

# 回归测试
regress: clean
	@echo "开始回归测试..."
	@$(MAKE) sim
	@echo "回归测试完成"

# 性能分析
perf: $(EXECUTABLE)
	@echo "开始性能分析..."
	cd $(SIM_DIR) && \
	./$(notdir $(EXECUTABLE)) $(SIM_OPTS) +perf_analysis 2>&1 | tee perf_analysis.log

# 生成覆盖率报告
coverage: $(EXECUTABLE)
	@echo "生成覆盖率报告..."
	$(VCS) $(VCS_FLAGS) -cm line+cond+fsm+tgl+branch \
		-o $(EXECUTABLE)_cov \
		-top $(TOP_MODULE) \
		$(COMPILE_OPTS) \
		$(ALL_SOURCES)
	cd $(SIM_DIR) && \
	./$(notdir $(EXECUTABLE))_cov $(SIM_OPTS) -cm line+cond+fsm+tgl+branch
	urg -dir $(SIM_DIR)/*.vdb -report $(SIM_DIR)/coverage_report

#================================================
# 清理和维护
#================================================

# 清理编译产物
clean:
	@echo "清理编译产物..."
	rm -rf $(SIM_DIR)
	rm -rf csrc
	rm -rf *.log
	rm -rf *.vpd
	rm -rf *.fsdb
	rm -rf *.vcd
	rm -rf DVEfiles
	rm -rf ucli.key
	rm -rf *.daidir
	rm -rf verdiLog
	rm -rf novas*
	rm -rf *.conf
	rm -rf .vcs*

# 深度清理
distclean: clean
	@echo "深度清理..."
	rm -rf *.tar.gz
	rm -rf backup_*

# 创建备份
backup:
	@echo "创建项目备份..."
	tar -czf backup_$(shell date +%Y%m%d_%H%M%S).tar.gz \
		rtl/ testbench/ test/ Makefile README.md

#================================================
# 信息和帮助
#================================================

# 显示状态
status:
	@echo "========================================="
	@echo "项目状态"
	@echo "========================================="
	@echo "项目名称: $(PROJECT_NAME)"
	@echo "顶层模块: $(TOP_MODULE)"
	@echo "工作目录: $(WORK_DIR)"
	@echo "仿真目录: $(SIM_DIR)"
	@echo ""
	@if [ -f $(EXECUTABLE) ]; then \
		echo "✓ 可执行文件已存在"; \
	else \
		echo "✗ 需要重新编译"; \
	fi
	@echo "RTL源文件数: $(words $(RTL_SOURCES))"
	@echo "测试文件数: $(words $(TB_SOURCES))"

# 显示帮助
help:
	@echo "========================================="
	@echo "RISC-V CPU 仿真 Makefile 帮助"
	@echo "========================================="
	@echo "主要目标:"
	@echo "  all         - 完整流程 (编译+仿真)"
	@echo "  compile     - 编译RTL和测试文件"
	@echo "  sim         - 运行仿真"
	@echo "  sim_fast    - 快速仿真 (无波形)"
	@echo "  sim_trace   - 详细仿真 (指令跟踪)"
	@echo "  sim_branch  - 分支调试仿真"
	@echo "  sim_debug   - 全面调试仿真 (指令+分支)"
	@echo "  wave        - 查看波形 (Verdi)"
	@echo "  wave_gtk    - 查看波形 (GTKWave)"
	@echo "  debug       - 调试模式"
	@echo ""
	@echo "分析目标:"
	@echo "  lint        - 语法检查"
	@echo "  coverage    - 覆盖率分析"
	@echo "  perf        - 性能分析"
	@echo ""
	@echo "维护目标:"
	@echo "  clean       - 清理编译产物"
	@echo "  distclean   - 深度清理"
	@echo "  backup      - 创建备份"
	@echo "  status      - 显示项目状态"
	@echo ""
	@echo "示例用法:"
	@echo "  make sim              # 标准仿真"
	@echo "  make sim_trace        # 带指令跟踪的仿真"
	@echo "  make sim_branch       # 分支调试仿真"
	@echo "  make sim_debug        # 全面调试仿真"
	@echo "  make wave             # 查看波形"
	@echo "  make clean sim        # 清理后重新仿真"
	@echo "========================================="

# 显示版本信息
version:
	@echo "工具版本信息:"
	@which $(VCS) > /dev/null && $(VCS) -ID || echo "VCS 未找到"
	@which $(VERDI) > /dev/null && $(VERDI) -version | head -1 || echo "Verdi 未找到"
