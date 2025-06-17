`include "defines.v"

module ex_stage (
    input  wire        clk,
    input  wire        rst_n,

    // Inputs from ID/EX Register
    input  wire [31:0] pc_ex_i,
    input  wire [31:0] pc_plus_4_ex_i,
    input  wire [31:0] operand_a_ex_i,
    input  wire [31:0] operand_b_src_ex_i, // rs2_data if not immediate, or immediate itself for some interpretations
    input  wire [31:0] immediate_ex_i,
    input  wire [4:0]  rd_addr_ex_i,
    input  wire [2:0]  funct3_ex_i,
    input  wire [6:0]  funct7_ex_i,
    input  wire [6:0]  opcode_ex_i,
    input  wire [3:0]  alu_op_ex_i,
    input  wire        alu_src_ex_i,       // 0: operand_b from reg, 1: operand_b from immediate
    input  wire        mem_read_ex_i,
    input  wire        mem_write_ex_i,
    input  wire        branch_ctrl_ex_i,   // Indicates if instruction is a branch type
    input  wire        reg_write_ex_i,
    input  wire [1:0]  mem_to_reg_ex_i,

    // Forwarding inputs
    input  wire [31:0] forward_data_a_i,   // Data from EX/MEM (ALU result of previous cycle)
    input  wire [31:0] forward_data_b_i,   // Data from MEM/WB (Result of instruction two cycles ago)
    input  wire [1:0]  forward_a_select_i, // Forwarding MUX select for operand A
    input  wire [1:0]  forward_b_select_i, // Forwarding MUX select for operand B

    // Outputs to EX/MEM Register
    output reg [31:0] pc_for_mem_o,
    output reg [31:0] pc_plus_4_mem_o,
    output reg [31:0] ex_result_mem_o,     // This will now come from the alu_mul_mux
    output reg        zero_flag_mem_o,
    output reg [31:0] reg2_data_mem_o,      // Data to be stored (rs2_data)
    output reg [31:0] immediate_mem_o,    // Pass immediate for potential use in MEM (e.g. offset for branch)
    output reg [4:0]  rd_addr_mem_o,
    output reg [2:0]  funct3_mem_o,
    output reg [6:0]  opcode_mem_o,
    output reg        mem_read_mem_o,
    output reg        mem_write_mem_o,
    output reg        branch_ctrl_mem_o,  // To be used by MEM stage for branch decision
    output reg        reg_write_mem_o,
    output reg [1:0]  mem_to_reg_mem_o
);

    // Internal signals for ALU operands
    reg [31:0] alu_operand_a;
    reg [31:0] alu_operand_b;
    wire [31:0] alu_result_internal;
    wire        zero_flag_internal;

    // Internal signals for forwarded operands
    reg [31:0] operand_a_forwarded_local;
    reg [31:0] operand_b_forwarded_local;

    // Signals for Multiplier and MUX
    wire [31:0] mul_result_internal;
    wire [1:0]  mul_op_type_internal;
    wire [31:0] final_ex_result; // Output of the ex_alu_mul_mux

    // ALU instantiation
    alu u_alu (
        .operand_a(alu_operand_a),
        .operand_b(alu_operand_b),
        .alu_op(alu_op_ex_i),
        .alu_result(alu_result_internal),
        .zero_flag(zero_flag_internal)
    );

    // Derive mul_op_type for the multiplier module
    assign mul_op_type_internal = (alu_op_ex_i == `ALU_MUL)   ? `MUL_OP_MUL :
                                  (alu_op_ex_i == `ALU_MULH)  ? `MUL_OP_MULH :
                                  (alu_op_ex_i == `ALU_MULHSU)? `MUL_OP_MULHSU :
                                  (alu_op_ex_i == `ALU_MULHU) ? `MUL_OP_MULHU :
                                  `MUL_OP_MUL; // Default, should not be hit if alu_op is for mul

    // Instantiate Multiplier
    multiplier u_multiplier (
        .operand_a_i(alu_operand_a),      // Use forwarded operand_a
        .operand_b_i(alu_operand_b),      // Use forwarded operand_b (or immediate)
        .mul_op_type_i(mul_op_type_internal),
        .mul_result_o(mul_result_internal)
    );

    // Instantiate ALU and Multiplier result selection MUX
    ex_alu_mul_mux u_ex_alu_mul_mux (
        .alu_op(alu_op_ex_i),             // To determine if it's a multiply op
        .alu_result(alu_result_internal),
        .mul_result(mul_result_internal),
        .final_result(final_ex_result)
    );
    
    // Combinational logic for EX stage
    always @(*) begin
        // ** FIX: Default assignment for forwarded operands **
        operand_a_forwarded_local = operand_a_ex_i;
        operand_b_forwarded_local = operand_b_src_ex_i; 

        // Forwarding logic for operand A
        if (forward_a_select_i == `FORWARD_EX_MEM) begin
            operand_a_forwarded_local = forward_data_a_i;
        end else if (forward_a_select_i == `FORWARD_MEM_WB) begin
            operand_a_forwarded_local = forward_data_b_i;
        end

        // Forwarding logic for operand B
        if (forward_b_select_i == `FORWARD_EX_MEM) begin
            operand_b_forwarded_local = forward_data_a_i;
        end else if (forward_b_select_i == `FORWARD_MEM_WB) begin
            operand_b_forwarded_local = forward_data_b_i;
        end
        
        // Select ALU operands (these are also inputs to multiplier)
        alu_operand_a = operand_a_forwarded_local;
        
        if (alu_src_ex_i) begin 
            alu_operand_b = immediate_ex_i;
        end else begin 
            alu_operand_b = operand_b_forwarded_local;
        end

        // Pass-through control signals and data to EX/MEM register
        pc_for_mem_o        = pc_ex_i;
        pc_plus_4_mem_o     = pc_plus_4_ex_i;
        ex_result_mem_o     = final_ex_result; // MODIFIED: Use output of ALU/MUL MUX
        zero_flag_mem_o     = zero_flag_internal;
                                                       
        if (mem_write_ex_i) begin 
             reg2_data_mem_o = operand_b_src_ex_i; 
        end else begin
             reg2_data_mem_o = operand_b_forwarded_local; 
        end

        immediate_mem_o     = immediate_ex_i; 
        rd_addr_mem_o       = rd_addr_ex_i;
        funct3_mem_o        = funct3_ex_i;
        opcode_mem_o        = opcode_ex_i;
        mem_read_mem_o      = mem_read_ex_i;
        mem_write_mem_o     = mem_write_ex_i;
        branch_ctrl_mem_o   = branch_ctrl_ex_i;
        reg_write_mem_o     = reg_write_ex_i;
        mem_to_reg_mem_o    = mem_to_reg_ex_i;

        // Debugging information for multiplication
        if (alu_op_ex_i == `ALU_MUL || alu_op_ex_i == `ALU_MULH || alu_op_ex_i == `ALU_MULHSU || alu_op_ex_i == `ALU_MULHU) begin
            $display("[EX_STAGE_MUL_DEBUG] PC_EX=0x%h, ALU_OP=%b, RD=%d, REG_WRITE=%b", pc_ex_i, alu_op_ex_i, rd_addr_ex_i, reg_write_ex_i);
            $display("    MUL_Inputs: A=0x%h, B=0x%h, MulOpType=%b", alu_operand_a, alu_operand_b, mul_op_type_internal);
            $display("    MUL_Output_Internal (from multiplier): 0x%h", mul_result_internal);
            $display("    ALU_Output_Internal (from ALU for this op): 0x%h", alu_result_internal);
            $display("    EX_ALU_MUL_MUX_Output (final_ex_result): 0x%h", final_ex_result);
        end
    end

endmodule