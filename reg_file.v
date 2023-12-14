module reg_file (
    input clk,
    input rst, // Active high reset signal
    input reg [3:0] read_reg1,
    input reg [3:0] read_reg2,
    input [3:0] write_reg,
    input [15:0] write_data,
    input write_enable,
    output reg [15:0] read_data1,
    output reg [15:0] read_data2
);

    // Declare the register array
    reg [15:0] registers[15:0];
    
    integer i;

    always @(*) begin
        if (rst) begin
            // Reset all registers to zero
            for (i = 0; i < 16; i = i + 1) begin
                registers[i] = 16'b0;
            end
        end else begin
            if (write_enable) begin
                // Normal write operation
                registers[write_reg] = write_data;
            end
        end
    end    

    // Write operation with reset
    always @(posedge clk) begin
        // Read operations
        read_data1 = registers[read_reg1];
        read_data2 = registers[read_reg2];
    end


endmodule