`timescale 1ns / 1ps

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
    output [15:0] data_out, // to data memory
    output [15:0] addr, // to data memory
    output we, // write enable to data memory
    output [15:0] out_reg, // output from ALU
    output zero,
    output carry
);
    
    // Internal ports definitions
    wire [3:0] opcode, reg1, reg2, destReg;
    wire [15:0] reg_data1, reg_data2, alu_result, alu_operand1, alu_operand2, immediate, write_data;
    wire carry_in, write_enable;

    // Intermediate registers for pipelining
    reg [15:0] reg_data1_d, reg_data2_d, alu_result_d, alu_operand1_d, alu_operand2_d;
    reg [15:0] write_data_d;
    reg [3:0] opcode_d, reg1_d, reg2_d, destReg_d;
    reg [15:0] immediate_d;
    reg carry_in_d, write_enable_d;
    reg [15:0] out_reg_d, addr_d, data_out_d;
    reg we_d;

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
            opcode_d <= 4'b0;
            reg1_d <= 4'b0;
            reg2_d <= 4'b0;
            destReg_d <= 4'b0;
            immediate_d <= 16'b0;
        end else begin
            // Latch decoded instruction
            opcode_d <= id.opcode;
            reg1_d <= id.reg1;
            reg2_d <= id.reg2;
            destReg_d <= id.destReg;
            immediate_d <= id.immediate;
        end
    end

    // Pipeline stage 2: Register file read
    always @(posedge clk) begin
        alu_operand1_d <= reg_data1;
        alu_operand2_d <= (opcode == `ADDI || opcode == `SUBI || opcode == `ANDI || opcode == `ORI || opcode == `XORI) ? immediate : reg_data2;
        write_enable_d <= !(opcode == `NOP || opcode == `STORE);
        write_data_d <= (opcode == `LOAD) ? data_in : alu_result;
    end

    // Pipeline stage 3: ALU operation and memory write
    always @(posedge clk) begin
        out_reg_d <= alu_result;
        carry_in_d <= carry; // Feedback carry for next cycle
        // Memory write logic
        we_d <= (opcode == `STORE);
        addr_d <= immediate;
        data_out_d <= (opcode == `STORE) ? reg_data1_d : 16'b0;
    end

    assign opcode = opcode_d;
    assign reg1 = reg1_d;
    assign reg2 = reg2_d;
    assign destReg = destReg_d;
    assign reg_data1 = reg_data1_d;
    assign reg_data2 = reg_data2_d;
    assign alu_result = alu_result_d;
    assign alu_operand1 = alu_operand1_d;
    assign alu_operand2 = alu_operand2_d;
    assign immediate = immediate_d;
    assign carry_in = carry_in_d;
    assign write_enable = write_enable_d;
    assign out_reg = out_reg_d;
    assign addr = addr_d;
    assign data_out = data_out_d;
    assign we = we_d;

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
    output [15:0] result,
    output zero,
    output carry_out
);

    reg [15:0] result_d;
    reg zero_d, carry_out_d;

    always @(*) begin
        carry_out_d = 1'b0; // Default carry out
        case (opcode)
            `ADDC: {carry_out_d, result_d} = operand1 + operand2 + carry_in;
            `SUBC: {carry_out_d, result_d} = operand1 - (operand2 + carry_in);
            `AND, `ANDI: result_d = operand1 & operand2;
            `OR, `ORI: result_d = operand1 | operand2;
            `XOR, `XORI: result_d = operand1 ^ operand2;
            `SHL: result_d = operand1 << operand2;
            `SHR: result_d = operand1 >> operand2;
            `SHRA: result_d = $signed(operand1) >>> operand2;
            `ADDI: result_d = operand1 + operand2; // operand2 is immediate in this case
            `SUBI: result_d = operand1 - operand2; // operand2 is immediate
            default: result_d = 16'b0;
        endcase

        // Set zero flag
        zero_d = (result_d == 16'b0) ? 1'b1 : 1'b0;
    end

    assign result = result_d;
    assign zero = zero_d;
    assign carry_out = carry_out_d;

endmodule


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


module final_top_tb;

    reg clk;
    reg rst;
    reg [31:0] instruction;
    wire [15:0] data_in; // Connected to data_out of SRAM
    reg [15:0] data_out_expected, out_reg_expected, addr_expected;
    reg we_expected, zero_expected, carry_expected;
    reg [15:0] data_out_d, addr_d, out_reg_d;
    reg we_d, zero_d, carry_d;
    
    wire [15:0] data_out, addr, out_reg;
    wire we, zero, carry;

    assign data_out = data_out_d;
    assign addr = addr_d;
    assign out_reg = out_reg_d;
    assign we = we_d;
    assign zero = zero_d;
    assign carry = carry_d;

    // Instantiate the final_top and sram modules
    final_top uut (
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .data_in(data_in),
        .data_out(data_out),
        .addr(addr),
        .we(we),
        .out_reg(out_reg),
        .zero(zero),
        .carry(carry)
    );

    sram mem (
        .addr(addr),
        .data_in(data_out),
        .we(we),
        .clk(clk),
        .data_out(data_in)
    );

    // File handlers for test vector files
    integer instr_file, data_out_file, out_reg_file, addr_file, we_file, zero_file, carry_file;
    integer scan_file, total_tests, failed_tests, i;

    // Clock generation (50 MHz)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // Testbench logic
    initial begin
        // Open test vector files
        instr_file = $fopen("instructions_program.tv", "r");
        data_out_file = $fopen("data_out.tv", "r");
        out_reg_file = $fopen("out_reg.tv", "r");
        addr_file = $fopen("addr.tv", "r");
        we_file = $fopen("we.tv", "r");
        zero_file = $fopen("zero.tv", "r");
        carry_file = $fopen("carry.tv", "r");

        total_tests = 0;
        failed_tests = 0;
        rst = 1;
        #80; // Assert reset for 4 cycles
        rst = 0;

        // Run 16 tests, each in 4 phases over 10 clock cycles
        repeat (16) begin
            // Phases 1 and 2: Prepare registers (cycles 1-6)
            for (i = 1; i <= 2; i = i+1) begin
                scan_file = $fscanf(instr_file, "%b\n", instruction);
                #60; // 3 clock cycles per instruction
            end

            // Phase 3: Execute actual instruction (cycles 7-9)
            scan_file = $fscanf(instr_file, "%b\n", instruction);
            #60; // 3 clock cycles

            // Phase 4: Evaluate outputs (cycle 10)
            total_tests = total_tests + 1;
            scan_file = $fscanf(data_out_file, "%b\n", data_out_expected);
            scan_file = $fscanf(out_reg_file, "%b\n", out_reg_expected);
            scan_file = $fscanf(addr_file, "%b\n", addr_expected);
            scan_file = $fscanf(we_file, "%b\n", we_expected);
            scan_file = $fscanf(zero_file, "%b\n", zero_expected);
            scan_file = $fscanf(carry_file, "%b\n", carry_expected);

            check_and_report(data_out, data_out_expected, instruction, "Data Out");
            check_and_report(out_reg, out_reg_expected, instruction, "Out Reg");
            check_and_report(addr, addr_expected, instruction, "Addr");
            check_and_report_bit(we, we_expected, instruction, "WE");
            check_and_report_bit(zero, zero_expected, instruction, "Zero");
            check_and_report_bit(carry, carry_expected, instruction, "Carry");

            #20; // Move to the next test
        end

        $fclose(instr_file);
        $fclose(data_out_file);
        $fclose(out_reg_file);
        $fclose(addr_file);
        $fclose(we_file);
        $fclose(zero_file);
        $fclose(carry_file);

        // Summary
        $display("Total Tests: %d, Failed Tests: %d", total_tests, failed_tests);
        $finish;
    end

    // Tasks for checking results and reporting errors
    task check_and_report;
        input [15:0] actual, expected;
        input [31:0] instr;
        input [15*8:0] signal_name; // Signal name as string
        begin
            if (actual !== expected) begin
                $display("Test %d Failed: %s. Instruction: %b, Expected: %h, Actual: %h",
                         total_tests, signal_name, instr, expected, actual);
                failed_tests = failed_tests + 1;
            end
        end
    endtask

    task check_and_report_bit;
        input actual, expected;
        input [31:0] instr;
        input [15*8:0] signal_name; // Signal name as string
        begin
            if (actual !== expected) begin
                $display("Test %d Failed: %s. Instruction: %b, Expected: %b, Actual: %b",
                         total_tests, signal_name, instr, expected, actual);
                failed_tests = failed_tests + 1;
            end
        end
    endtask

endmodule
