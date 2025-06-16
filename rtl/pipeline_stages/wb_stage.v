`include "defines.v"

module wb_stage (
    input  wire [31:0] pc_plus_4_wb_i,
    input  wire [31:0] mem_read_data_wb_i,
    input  wire [31:0] ex_result_wb_i,
    input  wire [4:0]  rd_addr_wb_i,
    input  wire        reg_write_wb_i,
    input  wire [1:0]  mem_to_reg_wb_i,
    
    output wire        reg_write_o,
    output wire [4:0]  rd_addr_o,
    output wire [31:0] write_data_o
);

    // 写回数据选择
    reg [31:0] write_data_selected;
    
    always @(*) begin
        case (mem_to_reg_wb_i)
            `MEM_TO_REG_ALU: write_data_selected = ex_result_wb_i;
            `MEM_TO_REG_MEM: write_data_selected = mem_read_data_wb_i;
            `MEM_TO_REG_PC4: write_data_selected = pc_plus_4_wb_i;
            default:         write_data_selected = ex_result_wb_i;
        endcase
    end
    
    // 输出信号
    assign reg_write_o = reg_write_wb_i;
    assign rd_addr_o = rd_addr_wb_i;
    assign write_data_o = write_data_selected;

    // Debugging Write-Back Stage
    always @(*) begin
        // Unconditional check for instructions that *should* be writing back from memory
        if (mem_to_reg_wb_i == `MEM_TO_REG_MEM) begin
            $display("[WB_STAGE_LW_CHECK] PC_PLUS_4_WB=0x%h (indicative), RD_WB=%d", pc_plus_4_wb_i, rd_addr_wb_i);
            $display("    Controls: reg_write_wb_i=%b, mem_to_reg_wb_i=%b", reg_write_wb_i, mem_to_reg_wb_i);
            $display("    Data: EX_Result_WB=0x%h, Mem_Read_Data_WB=0x%h, Selected_Write_Data(write_data_o)=0x%h",
                     ex_result_wb_i, mem_read_data_wb_i, write_data_selected);
        end

        // Original conditional debug
        if (reg_write_wb_i && rd_addr_wb_i != `REG_ZERO) begin // Only display if actual write is happening to non-x0
            // $display("[WB_STAGE_DEBUG] PC_PLUS_4_WB=0x%h, RD_WB=%d, REG_WRITE_WB=%b, MEM_TO_REG_WB=%b",
            //          pc_plus_4_wb_i, rd_addr_wb_i, reg_write_wb_i, mem_to_reg_wb_i);
            // $display("    EX_Result_WB: 0x%h, Mem_Read_Data_WB: 0x%h",
            //          ex_result_wb_i, mem_read_data_wb_i);
            // $display("    Selected_Write_Data (write_data_o): 0x%h", write_data_selected);
        end
    end

endmodule
