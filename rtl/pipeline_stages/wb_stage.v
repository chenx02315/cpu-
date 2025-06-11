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

endmodule
