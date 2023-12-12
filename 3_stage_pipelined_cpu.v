`define NOP   4'b0000
`define STORE 4'b0001
`define LOAD  4'b0010
`define ADDC  4'b0011
`define SUBC  4'b0100
`define AND   4'b0101
`define OR    4'b0110
`define XOR   4'b0111
`define SHL   4'b1000
`define SHR   4'b1001
`define SHRA  4'b1010
`define ADDI  4'b1011
`define SUBI  4'b1100
`define ANDI  4'b1101
`define ORI   4'b1110
`define XORI  4'b1111


module final_top (
    input clk,
    input rst, // active high
    input [31:0] instruction,
    input [15:0] data_in, // from data memory
    output reg [15:0] data_out, // to data memory
    output reg [15:0] addr, // to data memory
    output reg we, // write enable to data memory
    output reg [15:0] out_reg, // output from ALU
    output reg zero,
    output reg carry
);

    // Intermediate registers for pipelining
    reg [15:0] reg_data1, reg_data2, alu_result, alu_operand1, alu_operand2;
    reg [15:0] write_data;
    reg [3:0] opcode, reg1, reg2, destReg;
    reg [15:0] immediate;
    reg carry_in, write_enable;

    // Instantiation of modules
    instruction_decoder id(
        .instruction(instruction),
        .opcode(opcode),
        .reg1(reg1),
        .reg2(reg2),
        .destReg(destReg),
        .immediate(immediate)
    );

    reg_file rf(
        .clk(clk),
        .rst(rst),
        .read_reg1(reg1),
        .read_reg2(reg2),
        .write_reg(destReg),
        .write_data(write_data),
        .write_enable(write_enable),
        .read_data1(reg_data1),
        .read_data2(reg_data2)
    );

    alu alu_unit(
        .operand1(alu_operand1),
        .operand2(alu_operand2),
        .carry_in(carry_in),
        .opcode(opcode),
        .result(alu_result),
        .zero(zero),
        .carry_out(carry_out)
    );

    // Pipeline stage 1: Instruction decode
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset logic
            opcode <= 4'b0;
            reg1 <= 4'b0;
            reg2 <= 4'b0;
            destReg <= 4'b0;
            immediate <= 16'b0;
        end else begin
            // Latch decoded instruction
            opcode <= id.opcode;
            reg1 <= id.reg1;
            reg2 <= id.reg2;
            destReg <= id.destReg;
            immediate <= id.immediate;
        end
    end

    // Pipeline stage 2: Register file read
    always @(posedge clk) begin
        alu_operand1 <= reg_data1;
        alu_operand2 <= (opcode == `ADDI || opcode == `SUBI || opcode == `ANDI || opcode == `ORI || opcode == `XORI) ? immediate : reg_data2;
        write_enable <= !(opcode == `NOP || opcode == `STORE);
        write_data <= (opcode == `LOAD) ? data_in : alu_result;
    end

    // Pipeline stage 3: ALU operation and memory write
    always @(posedge clk) begin
        out_reg <= alu_result;
        carry_in <= carry; // Feedback carry for next cycle
        // Memory write logic
        we <= (opcode == `STORE);
        addr <= immediate;
        data_out <= (opcode == `STORE) ? reg_data1 : 16'b0;
    end

endmodule


module instruction_decoder (
    input [31:0] instruction,
    output [3:0] opcode,
    output [3:0] reg1,
    output [3:0] reg2,
    output [3:0] destReg,
    output [15:0] immediate
);

    // Decode the Opcode
    assign opcode = instruction[31:28];

    // Decode the Register Identifiers
    assign reg1 = instruction[27:24];
    assign reg2 = instruction[23:20];
    assign destReg = instruction[19:16];

    // Decode the Immediate Value
    assign immediate = instruction[15:0];

endmodule


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


module alu (
    input [15:0] operand1,
    input [15:0] operand2,
    input carry_in,
    input [3:0] opcode,
    output reg [15:0] result,
    output reg zero,
    output reg carry_out
);


    always @(*) begin
        carry_out = 1'b0; // Default carry out
        case (opcode)
            `ADDC: {carry_out, result} = operand1 + operand2 + carry_in;
            `SUBC: {carry_out, result} = operand1 - (operand2 + carry_in);
            `AND, `ANDI: result = operand1 & operand2;
            `OR, `ORI: result = operand1 | operand2;
            `XOR, `XORI: result = operand1 ^ operand2;
            `SHL: result = operand1 << operand2;
            `SHR: result = operand1 >> operand2;
            `SHRA: result = $signed(operand1) >>> operand2;
            `ADDI: result = operand1 + operand2; // operand2 is immediate in this case
            `SUBI: result = operand1 - operand2; // operand2 is immediate
            default: result = 16'b0;
        endcase

        // Set zero flag
        zero = (result == 16'b0) ? 1'b1 : 1'b0;
    end

endmodule


/*
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
*/