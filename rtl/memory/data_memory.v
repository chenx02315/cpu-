`include "defines.v"

module data_memory (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] addr_i,        // 数据地址
    input  wire [31:0] write_data_i,  // 写入数据
    input  wire        read_en_i,     // 读使能
    input  wire        write_en_i,    // 写使能
    input  wire [2:0]  funct3_i,      // 用于区分字节/半字/字操作
    
    output reg  [31:0] read_data_o    // 读取数据
);

    // 数据存储器大小：4KB
    parameter DATA_MEM_SIZE = 4096;
    
    // 字节存储器数组
    reg [7:0] data_mem [0:DATA_MEM_SIZE-1];
    
    // 地址计算
    wire [31:0] byte_addr = addr_i;
    wire [11:0] mem_index = byte_addr[11:0];
    
    // 地址有效性和对齐检查
    wire addr_in_bounds = (mem_index < DATA_MEM_SIZE);
    wire byte_aligned = 1'b1;  // 字节访问始终对齐
    wire half_aligned = (byte_addr[0] == 1'b0);
    wire word_aligned = (byte_addr[1:0] == 2'b00);
    
    // 根据访问类型确定边界检查
    wire addr_valid_byte = addr_in_bounds;
    wire addr_valid_half = addr_in_bounds && half_aligned && (mem_index + 1 < DATA_MEM_SIZE);
    wire addr_valid_word = addr_in_bounds && word_aligned && (mem_index + 3 < DATA_MEM_SIZE);
    
    // 读操作
    always @(*) begin
        read_data_o = 32'h00000000;
        
        if (read_en_i) begin
            case (funct3_i)
                `FUNCT3_LB: begin // LB - 字节加载 (有符号扩展)
                    if (addr_valid_byte) begin
                        read_data_o = {{24{data_mem[mem_index][7]}}, data_mem[mem_index]};
                    end else begin
                        $display("Error: LB access out of bounds at address 0x%08h", byte_addr);
                        read_data_o = 32'h00000000;
                    end
                end
                
                `FUNCT3_LH: begin // LH - 半字加载 (有符号扩展)
                    if (addr_valid_half) begin
                        read_data_o = {{16{data_mem[mem_index+1][7]}}, 
                                      data_mem[mem_index+1], data_mem[mem_index]};
                    end else begin
                        if (!half_aligned) begin
                            $display("Error: LH misaligned access at address 0x%08h", byte_addr);
                        end else begin
                            $display("Error: LH access out of bounds at address 0x%08h", byte_addr);
                        end
                        read_data_o = 32'h00000000;
                    end
                end
                
                `FUNCT3_LW: begin // LW - 字加载
                    if (addr_valid_word) begin
                        read_data_o = {data_mem[mem_index+3], data_mem[mem_index+2], 
                                      data_mem[mem_index+1], data_mem[mem_index]};
                    end else begin
                        if (!word_aligned) begin
                            $display("Error: LW misaligned access at address 0x%08h", byte_addr);
                        end else begin
                            $display("Error: LW access out of bounds at address 0x%08h", byte_addr);
                        end
                        read_data_o = 32'h00000000;
                    end
                end
                
                `FUNCT3_LBU: begin // LBU - 字节加载 (无符号扩展)
                    if (addr_valid_byte) begin
                        read_data_o = {24'h000000, data_mem[mem_index]};
                    end else begin
                        $display("Error: LBU access out of bounds at address 0x%08h", byte_addr);
                        read_data_o = 32'h00000000;
                    end
                end
                
                `FUNCT3_LHU: begin // LHU - 半字加载 (无符号扩展)
                    if (addr_valid_half) begin
                        read_data_o = {16'h0000, data_mem[mem_index+1], data_mem[mem_index]};
                    end else begin
                        if (!half_aligned) begin
                            $display("Error: LHU misaligned access at address 0x%08h", byte_addr);
                        end else begin
                            $display("Error: LHU access out of bounds at address 0x%08h", byte_addr);
                        end
                        read_data_o = 32'h00000000;
                    end
                end
                
                default: read_data_o = 32'h00000000;
            endcase
        end
    end
    
    // 写操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位时清零数据存储器
            integer i;
            for (i = 0; i < DATA_MEM_SIZE; i = i + 1) begin
                data_mem[i] <= 8'h00;
            end
            $display("数据存储器初始化完成，大小: %0d字节 (0x000 - 0x%03x)", 
                     DATA_MEM_SIZE, DATA_MEM_SIZE-1);
        end
        else if (write_en_i) begin
            case (funct3_i)
                `FUNCT3_SB: begin // SB - 字节存储
                    if (addr_valid_byte) begin
                        data_mem[mem_index] <= write_data_i[7:0];
                        $display("SB: 地址0x%08h <- 0x%02h", byte_addr, write_data_i[7:0]);
                    end else begin
                        $display("Error: SB write out of bounds at address 0x%08h", byte_addr);
                    end
                end
                
                `FUNCT3_SH: begin // SH - 半字存储
                    if (addr_valid_half) begin
                        data_mem[mem_index]   <= write_data_i[7:0];
                        data_mem[mem_index+1] <= write_data_i[15:8];
                        $display("SH: 地址0x%08h <- 0x%04h", byte_addr, write_data_i[15:0]);
                    end else begin
                        if (!half_aligned) begin
                            $display("Error: SH write misaligned at address 0x%08h", byte_addr);
                        end else begin
                            $display("Error: SH write out of bounds at address 0x%08h", byte_addr);
                        end
                    end
                end
                
                `FUNCT3_SW: begin // SW - 字存储
                    if (addr_valid_word) begin
                        data_mem[mem_index]   <= write_data_i[7:0];
                        data_mem[mem_index+1] <= write_data_i[15:8];
                        data_mem[mem_index+2] <= write_data_i[23:16];
                        data_mem[mem_index+3] <= write_data_i[31:24];
                        $display("SW: 地址0x%08h <- 0x%08h", byte_addr, write_data_i);
                    end else begin
                        if (!word_aligned) begin
                            $display("Error: SW write misaligned at address 0x%08h (地址必须4字节对齐)", byte_addr);
                            $display("       建议地址: 0x%08h", {byte_addr[31:2], 2'b00});
                        end else begin
                            $display("Error: SW write out of bounds at address 0x%08h", byte_addr);
                        end
                    end
                end
                
                default: begin
                    // 无操作
                end
            endcase
        end
    end

endmodule
