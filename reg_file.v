module reg_file (
    input clk,
    input rst, // Active high reset signal
    input [3:0] read_reg1,
    input [3:0] read_reg2,
    input [3:0] write_reg,
    input [15:0] write_data,
    input write_enable,
    output [15:0] read_data1,
    output [15:0] read_data2
);

    // Declare the register array
    reg [15:0] registers[15:0];
    
    integer i;

    // Read operations
    assign read_data1 = registers[read_reg1];
    assign read_data2 = registers[read_reg2];

    // Write operation with reset
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all registers to zero
            for (i = 0; i < 16; i = i + 1) begin
                registers[i] <= 16'b0;
            end
        end else if (write_enable) begin
            // Normal write operation
            registers[write_reg] <= write_data;
        end
    end

endmodule