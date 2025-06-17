`timescale 1ns/1ps
`include "defines.v"

module cpu_boundary_tb;

    // Clock and Reset
    reg clk;
    reg rst_n;

    // CPU debug interface
    wire [31:0] pc_if_tb;
    wire [31:0] instruction_if_tb;

    // Clock Generation (100MHz)
    parameter CLK_PERIOD = 10;
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test Parameters
    parameter TARGET_INSTRUCTION_COUNT = 28; // Instructions executed before JALR to halt
    parameter FINAL_HALT_PC          = 32'h000A00BC; // PC after JALR jump
    parameter MAX_CYCLES             = 500;
    parameter PROGRESS_INTERVAL      = 50;

    // Reset Generation
    initial begin
        rst_n = 0;
        #(CLK_PERIOD * 10);
        rst_n = 1;
        $display("================================================");
        $display("RISC-V CPU Boundary Conditions Test - START");
        $display("Time: %0t", $time);
        $display("Target: Execute %0d instructions, halt at PC 0x%08x", TARGET_INSTRUCTION_COUNT, FINAL_HALT_PC);
        $display("Clock Period: %0dns", CLK_PERIOD);
        $display("IMPORTANT: Ensure instruction_memory.v loads 'boundary_conditions_test.hex'");
        $display("================================================");
    end

    // Instantiate CPU
    cpu_top u_cpu_top (
        .clk(clk),
        .rst_n(rst_n),
        .pc_if(pc_if_tb),
        .instruction_if(instruction_if_tb)
    );

    // Counters and Flags
    reg [31:0] cycle_count = 0;
    reg [31:0] executed_instruction_count = 0;
    reg [31:0] pc_previous = 32'hFFFFFFFF; // Initialize to a non-zero, non-reset PC
    reg [7:0]  pc_stall_monitor = 0;
    reg test_passed = 1'b0;

    // Cycle and Instruction Counting
    always @(posedge clk) begin
        if (rst_n) begin
            cycle_count <= cycle_count + 1;
            // Count instructions only if PC changes and is not the halt PC yet
            if (pc_if_tb != pc_previous && pc_if_tb < FINAL_HALT_PC && pc_if_tb != `RESET_PC) begin
                 // A simple way to count executed instructions is when PC advances.
                 // This might slightly miscount if there are flushes right at the start,
                 // but good enough for this test's purpose.
                 // More accurate counting would track WB stage completion.
                if (pc_previous != 32'hFFFFFFFF) begin // Don't count the initial PC=0 as an executed instruction
                    executed_instruction_count <= executed_instruction_count + 1;
                end
            end
            pc_previous <= pc_if_tb;
        end else begin
            pc_previous <= 32'hFFFFFFFF; // Reset pc_previous on reset
            executed_instruction_count <= 0;
            cycle_count <= 0;
        end
    end

    // Monitoring and Test Completion
    always @(posedge clk) begin
        if (rst_n) begin
            // Progress Report
            if (cycle_count > 0 && cycle_count % PROGRESS_INTERVAL == 0) begin
                $display("[PROGRESS] Cycle: %5d, PC: 0x%08x, Instr: 0x%08x, Executed: %d",
                         cycle_count, pc_if_tb, instruction_if_tb, executed_instruction_count);
            end

            // Test End Condition
            if (pc_if_tb == FINAL_HALT_PC) begin
                test_passed = 1'b1;
                $display("\n=== Boundary Conditions Test HALTED (PC=0x%08x) ===", pc_if_tb);
                dump_registers_boundary("Final State after Halt");
                final_validation_boundary();
                test_summary_boundary();
                #(CLK_PERIOD * 5);
                $finish;
            end

            // Timeout
            if (cycle_count >= MAX_CYCLES) begin
                $display("\nERROR: Max cycles (%d) reached. Test timed out.", MAX_CYCLES);
                $display("Current PC: 0x%08x, Executed Instructions: %d", pc_if_tb, executed_instruction_count);
                dump_registers_boundary("State at Timeout");
                final_validation_boundary(); // Still try to validate
                test_summary_boundary();
                #(CLK_PERIOD * 5);
                $finish;
            end

            // PC Stall Detection
            if (pc_if_tb == pc_previous && pc_if_tb != `RESET_PC && cycle_count > 20) begin // Avoid early false positives
                pc_stall_monitor <= pc_stall_monitor + 1;
                if (pc_stall_monitor >= 50) begin
                    $display("\nERROR: PC stalled at 0x%08x for 50 cycles.", pc_if_tb);
                    dump_registers_boundary("State at PC Stall");
                    final_validation_boundary();
                    test_summary_boundary();
                    #(CLK_PERIOD * 5);
                    $finish;
                end
            end else begin
                pc_stall_monitor <= 0;
            end
        end
    end

    // Expected Register Values for boundary_conditions_test.hex
    reg [31:0] standard_registers_boundary [0:31];
    initial begin
        for (int i = 0; i < 32; i = i + 1) standard_registers_boundary[i] = 32'h0;

        standard_registers_boundary[0]  = 32'h00000000;
        standard_registers_boundary[1]  = 32'h00000064; // x1 = 100
        standard_registers_boundary[2]  = 32'h000015B3; // x2 = 5555
        standard_registers_boundary[3]  = 32'h000015B3; // x3 = 5555 (from lw)
        standard_registers_boundary[4]  = 32'h000015B3; // x4 = x3
        standard_registers_boundary[5]  = 32'h00000000; // x5 = 0 (from add x0, x0)
        standard_registers_boundary[6]  = 32'h700007FF; // x6 = 0x70000000 + 0x7FF
        standard_registers_boundary[7]  = 32'hFFFFF800; // x7 = -2048
        standard_registers_boundary[8]  = 32'h700007FF; // x8 = x6
        standard_registers_boundary[9]  = 32'hFFFFF800; // x9 = x7
        standard_registers_boundary[10] = 32'h6FFFFFFF; // x10 = x8 + x9
        standard_registers_boundary[11] = 32'h0000000A; // x11 = 10
        standard_registers_boundary[12] = 32'h0000000A; // x12 = 10
        // x13 is skipped by BEQ, then overwritten by ADDI after BNE target
        standard_registers_boundary[14] = 32'h000000DE; // x14 = 222
        // Test 3: Branching (Taken and Not Taken - simplified to one taken for this example)
        // PC=0x034: addi x11, x0, 10
        // PC=0x038: addi x12, x0, 10
        // PC=0x03C: beq x11, x12, L1_target (+8, to 0x044)
        // PC=0x040: addi x13, x0, 111    // SKIPPED
        // PC=0x044: L1_target: addi x14, x0, 222 // x14 = 222
        // For the provided HEX, there's only one branch. x13 is not set to 111.
        // If there were a second branch as in my thought process, x13 would be different.
        // The current HEX has:
        // 044: 0DE00713 -> addi x14, x0, 222
        // So x13 remains 0.

        standard_registers_boundary[17] = 32'h00000007; // x17 = 7
        standard_registers_boundary[18] = 32'hFFFFFFFC; // x18 = -4
        standard_registers_boundary[19] = 32'hFFFFFFF4; // x19 = 7 * -4 = -28 (corrected from FFFFFFFE4 to FFFFFFF4)
                                                        // 7 * -4 = -28. 0xFFFFFFE4 is -28. My previous hex was 02C889B3 (mul x19,x17,x18)
                                                        // For 02C889B3 (mul x19, x17, x18) with x17=7, x18=-4:
                                                        // 7 (0x00000007) * -4 (0xFFFFFFFC) = -28 (0xFFFFFFE4). This is correct.
        standard_registers_boundary[19] = 32'hFFFFFFFFE4; // x19 = 7 * -4 = -28

        standard_registers_boundary[20] = 32'hFFFFFFFF; // x20 = mulh(7, -4) = -1
        standard_registers_boundary[21] = 32'h00000000; // x21 = 0
        standard_registers_boundary[22] = 32'h00000000; // x22 = 7 * 0 = 0
        standard_registers_boundary[23] = 32'h000A00BC; // x23 = 0xA0000 + 0xBC (target for JALR)
        standard_registers_boundary[24] = 32'h0000007B; // x24 = 123
        standard_registers_boundary[25] = 32'h00000070; // x25 = PC_jalr (0x06C) + 4
    end

    // Register Dump Task
    task dump_registers_boundary;
        input [127:0] stage_name;
        integer i;
        $display("\n--- %s ---", stage_name);
        for (i = 0; i < 32; i = i + 4) begin
            $display("x%02d:0x%08x x%02d:0x%08x x%02d:0x%08x x%02d:0x%08x",
                     i,   (i==0) ? 0 : u_cpu_top.u_register_file.registers[i],
                     i+1, u_cpu_top.u_register_file.registers[i+1],
                     i+2, u_cpu_top.u_register_file.registers[i+2],
                     i+3, u_cpu_top.u_register_file.registers[i+3]);
        end
        $display("-----------------------------------");
    endtask

    // Final Validation Task
    task final_validation_boundary;
        integer errors = 0;
        integer i;
        $display("\n=== Final Register Validation (Boundary Test) ===");
        for (i = 0; i < 32; i = i + 1) begin
            automatic logic [31:0] actual_val = (i == 0) ? 0 : u_cpu_top.u_register_file.registers[i];
            if (actual_val !== standard_registers_boundary[i]) begin
                $display("MISMATCH x%02d: Expected 0x%08x, Got 0x%08x",
                         i, standard_registers_boundary[i], actual_val);
                errors = errors + 1;
            end
        end
        if (errors == 0) begin
            $display("✓ All register values match expected values.");
        end else begin
            $display("✗ %d register mismatches found.", errors);
            test_passed = 1'b0; // Mark test as failed if any mismatch
        end
        $display("==============================================");
    endtask

    // Test Summary Task
    task test_summary_boundary;
        $display("\n================================================");
        $display("RISC-V CPU Boundary Conditions Test - SUMMARY");
        $display("------------------------------------------------");
        $display("Test Status: %s", test_passed ? "PASSED" : "FAILED");
        $display("Final PC: 0x%08x (Target Halt PC: 0x%08x)", pc_if_tb, FINAL_HALT_PC);
        $display("Total Cycles: %d", cycle_count);
        $display("Executed Instructions (approx): %d (Target: %d)", executed_instruction_count, TARGET_INSTRUCTION_COUNT);
        if (executed_instruction_count > 0) begin
            $display("Approximate CPI: %.2f", real'(cycle_count) / real'(executed_instruction_count));
        end
        $display("================================================");
    endtask

    // Waveform Dumping
    initial begin
        if (!$test$plusargs("nofsdb")) begin
            $fsdbDumpfile("cpu_boundary_conditions.fsdb");
            $fsdbDumpvars(0, cpu_boundary_tb, "+mda"); // Dump multi-dimensional arrays
        end
        $dumpfile("cpu_boundary_conditions.vcd");
        $dumpvars(0, cpu_boundary_tb);
        $display("Waveform dumping (FSDB/VCD) enabled for boundary test.");
    end

endmodule
