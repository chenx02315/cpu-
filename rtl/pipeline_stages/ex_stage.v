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
    output reg [31:0] ex_result_mem_o,
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


    // ALU instantiation
    alu u_alu (
        .operand_a(alu_operand_a),
        .operand_b(alu_operand_b),
        .alu_op(alu_op_ex_i),
        .alu_result(alu_result_internal),
        .zero_flag(zero_flag_internal)
    );
    
    // Combinational logic for EX stage
    always @(*) begin
        // ** FIX: Default assignment for forwarded operands **
        // These lines ensure that if no forwarding is selected,
        // the operands from the ID/EX register are used.
        operand_a_forwarded_local = operand_a_ex_i;
        operand_b_forwarded_local = operand_b_src_ex_i; // This is rs2_data if alu_src is register

        // Forwarding logic for operand A
        if (forward_a_select_i == `FORWARD_EX_MEM) begin
            operand_a_forwarded_local = forward_data_a_i;
        end else if (forward_a_select_i == `FORWARD_MEM_WB) begin
            operand_a_forwarded_local = forward_data_b_i;
        end

        // Forwarding logic for operand B (only if not using immediate for ALU op B)
        if (forward_b_select_i == `FORWARD_EX_MEM) begin
            operand_b_forwarded_local = forward_data_a_i;
        end else if (forward_b_select_i == `FORWARD_MEM_WB) begin
            operand_b_forwarded_local = forward_data_b_i;
        end
        
        // Select ALU operands
        alu_operand_a = operand_a_forwarded_local;
        
        if (alu_src_ex_i) begin // If alu_src is 1, operand B is immediate
            alu_operand_b = immediate_ex_i;
        end else begin // Otherwise, operand B is from register (possibly forwarded)
            alu_operand_b = operand_b_forwarded_local;
        end

        // Pass-through control signals and data to EX/MEM register
        pc_for_mem_o        = pc_ex_i;
        pc_plus_4_mem_o     = pc_plus_4_ex_i;
        ex_result_mem_o     = alu_result_internal;
        zero_flag_mem_o     = zero_flag_internal;
        reg2_data_mem_o     = operand_b_forwarded_local; // For store instructions, pass rs2_data (potentially forwarded)
                                                       // Note: if alu_src_ex_i is 1, operand_b_src_ex_i might be garbage if not handled.
                                                       // For stores, alu_src is 1, but operand_b_src_ex_i should be rs2_data.
                                                       // Control unit should ensure alu_src is 0 for R-type and Store.
                                                       // For Store, operand_b_src_ex_i is rs2_data.
                                                       // The immediate is used for address calculation with rs1_data.
                                                       // So, reg2_data_mem_o should be operand_b_src_ex_i (original rs2 value from ID/EX)
                                                       // if it's a store.
                                                       // Let's pass the original operand_b_src_ex_i for stores.
        if (mem_write_ex_i) begin // If it's a store instruction
             reg2_data_mem_o = operand_b_src_ex_i; // Pass the original rs2 data for store
        end else begin
             reg2_data_mem_o = operand_b_forwarded_local; // For other uses, pass the (potentially) forwarded value
        end

        immediate_mem_o     = immediate_ex_i; // Pass immediate for branch offset calculation in MEM
        rd_addr_mem_o       = rd_addr_ex_i;
        funct3_mem_o        = funct3_ex_i;
        opcode_mem_o        = opcode_ex_i;
        mem_read_mem_o      = mem_read_ex_i;
        mem_write_mem_o     = mem_write_ex_i;
        branch_ctrl_mem_o   = branch_ctrl_ex_i;
        reg_write_mem_o     = reg_write_ex_i;
        mem_to_reg_mem_o    = mem_to_reg_ex_i;

        // Debug: This is where the testbench's EX_SUPER_DEBUG would sample from
        // To verify, you can add $display here too.
        // Example:
        // if (pc_ex_i == 32'h00000118) begin
        //     $display("[EX_STAGE_INTERNAL_DEBUG] @ %0t", $time);
        //     $display("  Inputs: op_a_ex_i=0x%h, op_b_src_ex_i=0x%h", operand_a_ex_i, operand_b_src_ex_i);
        //     $display("  Fwd Sel: fwd_a_sel=%b, fwd_b_sel=%b", forward_a_select_i, forward_b_select_i);
        //     $display("  Fwd Data: fwd_data_a=0x%h, fwd_data_b=0x%h", forward_data_a_i, forward_data_b_i);
        //     $display("  Locals: op_a_fwd_local=0x%h, op_b_fwd_local=0x%h", operand_a_forwarded_local, operand_b_forwarded_local);
        //     $display("  ALU Inputs: alu_op_a=0x%h, alu_op_b=0x%h", alu_operand_a, alu_operand_b);
        //     $display("  ALU Ctrl: alu_src_ex_i=%b, alu_op_ex_i=%b", alu_src_ex_i, alu_op_ex_i);
        // end

    end

endmodule
