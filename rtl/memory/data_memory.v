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
    parameter DATA_MEM_SIZE = 4096; // 4KB = 4096 Bytes
    
    // 字节存储器数组
    reg [7:0] data_mem [0:DATA_MEM_SIZE-1];
    
    // 地址计算
    wire [31:0] byte_addr = addr_i;
    // 使用地址的低12位作为索引，因为4KB = 2^12 Bytes
    wire [11:0] mem_index = byte_addr[11:0]; 
    
    // 地址有效性和对齐检查
    // 确保地址在0到DATA_MEM_SIZE-1的范围内
    wire addr_in_bounds_base = (byte_addr < DATA_MEM_SIZE); // Check against full byte address range

    // 对齐检查
    wire byte_aligned = 1'b1; // 字节访问总是对齐
    wire half_aligned = (byte_addr[0] == 1'b0); // 半字地址的最低位必须为0
    wire word_aligned = (byte_addr[1:0] == 2'b00); // 字地址的最低两位必须为00
    
    // 根据访问类型确定边界检查
    // For byte, index must be < SIZE
    wire addr_valid_byte = (mem_index < DATA_MEM_SIZE);
    // For halfword, index and index+1 must be < SIZE
    wire addr_valid_half = half_aligned && (mem_index < DATA_MEM_SIZE - 1);
    // For word, index, index+1, index+2, index+3 must be < SIZE
    wire addr_valid_word = word_aligned && (mem_index < DATA_MEM_SIZE - 3);

    // 初始化数据存储器 (通常在仿真中使用)
    integer i;
    initial begin
        for (i = 0; i < DATA_MEM_SIZE; i = i + 1) begin
            data_mem[i] = 8'h00;
        end
        $display("数据存储器初始化完成，大小: %0d字节 (0x%0x - 0x%0x)", DATA_MEM_SIZE, 0, DATA_MEM_SIZE-1);
    end

    // 写操作 (异步写，但在时钟控制的模块中通常是同步的，这里保持异步风格以匹配常见简单内存模型)
    // 实际处理器中内存写通常是同步的
    always @(*) begin
        if (write_en_i) begin
            case (funct3_i)
                `FUNCT3_SB: begin // Store Byte
                    if (addr_valid_byte) begin
                        data_mem[mem_index] = write_data_i[7:0];
                        $display("[DM_WRITE] SB Addr=0x%h, Data=0x%h (@ %0t)", byte_addr, write_data_i[7:0], $time);
                    end else begin
                        $display("[DM_ERROR] SB Addr 0x%h out of bounds or misaligned (@ %0t)", byte_addr, $time);
                    end
                end
                `FUNCT3_SH: begin // Store Halfword
                    if (addr_valid_half) begin
                        data_mem[mem_index]   = write_data_i[7:0];
                        data_mem[mem_index+1] = write_data_i[15:8];
                        $display("[DM_WRITE] SH Addr=0x%h, Data=0x%h (@ %0t)", byte_addr, write_data_i[15:0], $time);
                    end else begin
                        $display("[DM_ERROR] SH Addr 0x%h out of bounds or misaligned (@ %0t)", byte_addr, $time);
                    end
                end
                `FUNCT3_SW: begin // Store Word
                    if (addr_valid_word) begin
                        data_mem[mem_index]   = write_data_i[7:0];
                        data_mem[mem_index+1] = write_data_i[15:8];
                        data_mem[mem_index+2] = write_data_i[23:16];
                        data_mem[mem_index+3] = write_data_i[31:24];
                        $display("[DM_WRITE] SW Addr=0x%h, Data=0x%h (@ %0t)", byte_addr, write_data_i, $time);
                    end else begin
                        $display("[DM_ERROR] SW Addr 0x%h out of bounds or misaligned (@ %0t)", byte_addr, $time);
                    end
                end
                default: begin
                    $display("[DM_ERROR] Unknown funct3 for store: %b (@ %0t)", funct3_i, $time);
                end
            endcase
        end
    end
    
    // 读操作 (组合逻辑读)
    always @(*) begin
        read_data_o = 32'hdeadbeef; // Default to a recognizable garbage value if read is invalid
        if (read_en_i) begin
            case (funct3_i)
                `FUNCT3_LB: begin // Load Byte
                    if (addr_valid_byte) begin
                        read_data_o = {{24{data_mem[mem_index][7]}}, data_mem[mem_index]}; // Sign extend
                    end else begin
                        $display("[DM_ERROR] LB Addr 0x%h out of bounds or misaligned (@ %0t)", byte_addr, $time);
                        read_data_o = 32'hbad0add0; // Error value
                    end
                end
                `FUNCT3_LBU: begin // Load Byte Unsigned
                    if (addr_valid_byte) begin
                        read_data_o = {24'b0, data_mem[mem_index]}; // Zero extend
                    end else begin
                        $display("[DM_ERROR] LBU Addr 0x%h out of bounds or misaligned (@ %0t)", byte_addr, $time);
                        read_data_o = 32'hbad0add1; // Error value
                    end
                end
                `FUNCT3_LH: begin // Load Halfword
                    if (addr_valid_half) begin
                        read_data_o = {{16{data_mem[mem_index+1][7]}}, data_mem[mem_index+1], data_mem[mem_index]}; // Sign extend
                    end else begin
                        $display("[DM_ERROR] LH Addr 0x%h out of bounds or misaligned (@ %0t)", byte_addr, $time);
                        read_data_o = 32'hbad0add2; // Error value
                    end
                end
                `FUNCT3_LHU: begin // Load Halfword Unsigned
                    if (addr_valid_half) begin
                        read_data_o = {16'b0, data_mem[mem_index+1], data_mem[mem_index]}; // Zero extend
                    end else begin
                        $display("[DM_ERROR] LHU Addr 0x%h out of bounds or misaligned (@ %0t)", byte_addr, $time);
                        read_data_o = 32'hbad0add3; // Error value
                    end
                end
                `FUNCT3_LW: begin // Load Word
                    if (addr_valid_word) begin
                        read_data_o = {data_mem[mem_index+3], data_mem[mem_index+2], data_mem[mem_index+1], data_mem[mem_index]};
                    end else begin
                        $display("[DM_ERROR] LW Addr 0x%h out of bounds or misaligned (@ %0t)", byte_addr, $time);
                        read_data_o = 32'hbad0add4; // Error value
                    end
                end
                default: begin
                    $display("[DM_ERROR] Unknown funct3 for load: %b (@ %0t)", funct3_i, $time);
                    read_data_o = 32'hbad0add5; // Error value
                end
            endcase
            if (read_en_i && (funct3_i == `FUNCT3_LB || funct3_i == `FUNCT3_LBU || funct3_i == `FUNCT3_LH || funct3_i == `FUNCT3_LHU || funct3_i == `FUNCT3_LW))
                $display("[DM_READ] Addr=0x%h, Funct3=%b, Data=0x%h (@ %0t)", byte_addr, funct3_i, read_data_o, $time);
        end
    end

endmodule
