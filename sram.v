module sram (
    input [15:0] addr,        // Memory address input
    input [15:0] data_in,     // Data input for write operation
    input we,                 // Write Enable signal
    input clk,                // Clock input
    output [15:0] data_out    // Data output for read operation
);

    // Declare memory array
    reg [15:0] mem [2**16-1:0]; // 65536 locations, each 16 bits wide

    // Internal register to hold data output
    reg [15:0] data_out_bus;

    // Memory access logic
    always @(negedge clk) begin
        if (we) begin
            // Write operation
            mem[addr] = data_in;    // Write data_in to the specified address
        end else begin
            // Read operation
            data_out_bus = mem[addr]; // Read data from the specified address
        end
    end

    // Output assignment
    assign data_out = data_out_bus; // Output the data read from memory

endmodule