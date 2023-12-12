`timescale 1ns / 1ns

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
        clk = 1'b0;
        forever begin
            #10 clk = ~clk;
        end
    end

    initial begin
        rst = 1'b0;
        #80; // Assert reset for 4 cycles
        rst = 1'b0;
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
        #80


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
        $stop;
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