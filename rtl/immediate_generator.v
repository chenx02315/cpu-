`include "defines.v"

module immediate_generator (
    input  wire [31:0] instruction_i,
    output reg  [31:0] immediate_o
);

    wire [6:0] opcode = instruction_i[6:0];
    
    always @(*) begin
        case (opcode)
            `OPCODE_LUI, `OPCODE_AUIPC: begin
                // U-type: imm[31:12] = inst[31:12], imm[11:0] = 0
                immediate_o = {instruction_i[31:12], 12'b0};
            end
            
            `OPCODE_JAL: begin
                // J-type: imm[20|10:1|11|19:12] = inst[31|30:21|20|19:12]
                immediate_o = {{12{instruction_i[31]}}, 
                              instruction_i[19:12], 
                              instruction_i[20], 
                              instruction_i[30:21], 
                              1'b0};
            end
            
            `OPCODE_JALR, `OPCODE_LOAD, `OPCODE_IMM: begin
                // I-type: imm[11:0] = inst[31:20]
                immediate_o = {{20{instruction_i[31]}}, instruction_i[31:20]};
            end
            
            `OPCODE_BRANCH: begin
                // B-type: imm[12|10:5|4:1|11] = inst[31|30:25|11:8|7]
                immediate_o = {{20{instruction_i[31]}}, 
                              instruction_i[7], 
                              instruction_i[30:25], 
                              instruction_i[11:8], 
                              1'b0};
            end
            
            `OPCODE_STORE: begin
                // S-type: imm[11:5] = inst[31:25], imm[4:0] = inst[11:7]
                immediate_o = {{20{instruction_i[31]}}, 
                              instruction_i[31:25], 
                              instruction_i[11:7]};
            end
            
            default: begin
                immediate_o = 32'h00000000;
            end
        endcase
    end

endmodule
