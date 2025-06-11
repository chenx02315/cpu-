`include "defines.v"

module id_stage (
    input  wire [31:0] pc_i,
    input  wire [31:0] pc_plus_4_i,
    input  wire [31:0] instruction_i,
    
    // 寄存器文件接口
    output wire [4:0]  rs1_addr_rf_o,
    output wire [4:0]  rs2_addr_rf_o,
    input  wire [31:0] rs1_data_i,
    input  wire [31:0] rs2_data_i,
    
    // 输出到EX阶段
    output wire [31:0] pc_ex_o,
    output wire [31:0] pc_plus_4_ex_o,
    output wire [31:0] operand_a_ex_o,
    output wire [31:0] operand_b_ex_o,
    output wire [31:0] reg2_data_ex_o,
    output wire [31:0] immediate_ex_o,
    output wire [4:0]  rs1_addr_ex_o,
    output wire [4:0]  rs2_addr_ex_o,
    output wire [4:0]  rd_addr_ex_o,
    output wire [2:0]  funct3_ex_o,
    output wire [6:0]  funct7_ex_o,
    output wire [6:0]  opcode_ex_o,
    output wire [3:0]  alu_op_ex_o,
    output wire        alu_src_ex_o,
    output wire        mem_read_ex_o,
    output wire        mem_write_ex_o,
    output wire        branch_ex_o,
    output wire        reg_write_ex_o,
    output wire [1:0]  mem_to_reg_ex_o
);

    // 指令字段解码
    wire [6:0] opcode = instruction_i[6:0];
    wire [4:0] rd_addr = instruction_i[11:7];
    wire [2:0] funct3 = instruction_i[14:12];
    wire [4:0] rs1_addr = instruction_i[19:15];
    wire [4:0] rs2_addr = instruction_i[24:20];
    wire [6:0] funct7 = instruction_i[31:25];
    
    // 调试输出 - 显示指令解码过程
    always @(*) begin
        if (pc_i < 32'h40) begin // 只显示前16条指令
            $display("[ID] PC=0x%08x, 指令=0x%08x, opcode=0x%02x, rd=x%0d", 
                    pc_i, instruction_i, opcode, rd_addr);
            if (opcode == `OPCODE_LUI) begin
                $display("     -> LUI指令: x%0d = 0x%08x", rd_addr, {instruction_i[31:12], 12'b0});
            end
        end
    end
    
    // 立即数生成
    wire [31:0] immediate;
    immediate_generator u_immediate_generator (
        .instruction_i(instruction_i),
        .immediate_o(immediate)
    );
    
    // 控制单元
    control_unit u_control_unit (
        .opcode_i(opcode),
        .funct3_i(funct3),
        .funct7_i(funct7),
        .alu_op_o(alu_op_ex_o),
        .alu_src_o(alu_src_ex_o),
        .mem_read_o(mem_read_ex_o),
        .mem_write_o(mem_write_ex_o),
        .branch_o(branch_ex_o),
        .reg_write_o(reg_write_ex_o),
        .mem_to_reg_o(mem_to_reg_ex_o)
    );
    
    // 寄存器文件地址输出
    assign rs1_addr_rf_o = rs1_addr;
    assign rs2_addr_rf_o = rs2_addr;
    
    // 传递到EX阶段的信号
    assign pc_ex_o = pc_i;
    assign pc_plus_4_ex_o = pc_plus_4_i;
    
    // LUI指令特殊处理：operand_a应该是0
    assign operand_a_ex_o = (opcode == `OPCODE_LUI) ? 32'h00000000 : rs1_data_i;
    assign operand_b_ex_o = rs2_data_i;
    assign reg2_data_ex_o = rs2_data_i;
    assign immediate_ex_o = immediate;
    assign rs1_addr_ex_o = rs1_addr;
    assign rs2_addr_ex_o = rs2_addr;
    assign rd_addr_ex_o = rd_addr;
    assign funct3_ex_o = funct3;
    assign funct7_ex_o = funct7;
    assign opcode_ex_o = opcode;

endmodule
