`include "opcodes.vh"

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
    wire [15:0] alu_result, alu_operand1, alu_operand2, immediate, write_data, reg_data1, reg_data2;
    wire write_enable_rf, zero_d2, carry_d2;

    // Intermediate registers for pipelining
    reg [31:0] instruction_d1;
    reg [15:0] data_in_d1, alu_operand1_d2, alu_operand2_d2, addr_d2, data_out_d2, write_data_d3, addr_d3, alu_result_d3;
    reg [3:0] opcode_d2, destReg_d2, destReg_d3;
    reg we_d2, zero_d3, carry_d3, write_enable_rf_d3;

    // Instantiation of modules
    instruction_decoder id (
        .instruction (instruction_d1),
        .opcode (opcode),
        .reg1 (reg1),
        .reg2 (reg2),
        .destReg (destReg),
        .immediate (immediate)
    );

    reg_file rf (
        .clk(clk),
        .rst(rst),
        .read_reg1(reg1),
        .read_reg2(reg2),
        .write_reg(destReg_d3),
        .write_data(write_data),
        .write_enable(write_enable_rf),
        .read_data1(reg_data1),
        .read_data2(reg_data2)
    );

    alu alu_unit (
        .operand1(alu_operand1),
        .operand2(alu_operand2),
        .carry_in(carry_d3),
        .opcode(opcode_d2),
        .result(alu_result),
        .zero(zero_d2),
        .carry_out(carry_d2)
    );

    // Pipeline stage 1: Instruction decode
    always @(posedge clk or rst) begin
        if (rst) begin
            // Reset logic
            instruction_d1 <= 32'b0;
        end else begin
            // Reg instruction
            instruction_d1 <= instruction;
        end
    end

    // Pipeline stage 2: Register file read
    always @(posedge clk or rst) begin
        if (rst) begin
            // Reset logic
            opcode_d2 <= 4'b0;
            alu_operand1_d2 <= 16'b0;
            alu_operand2_d2 <= 16'b0;
            addr_d2 <= 16'b0;
            data_out_d2 <= 16'b0;
            we_d2 <= 1'b0;
            destReg_d2 <= 4'b0;
        end else begin
            // Reg decoded instruction
            opcode_d2 <= opcode;
            alu_operand1_d2 <= reg_data1;
            alu_operand2_d2 <= (opcode == `ADDI || opcode == `SUBI || opcode == `ANDI || opcode == `ORI || opcode == `XORI) ? immediate : reg_data2;
            addr_d2 <= immediate;
            data_out_d2 <= (opcode == `STORE) ? reg_data1 : 16'b0;
            destReg_d2 <= destReg;
            // Memory write logic
            we_d2 <= (opcode == `STORE);
        end
    end

    // Pipeline stage 3: ALU operation and memory write
    always @(posedge clk or rst) begin
        if (rst) begin
            write_enable_rf_d3 <= 1'b0;
            write_data_d3 <= 16'b0;
            addr_d3 <= 16'b0;
            alu_result_d3 <= 16'b0;
            zero_d3 <= 1'b0;
            carry_d3 <= 1'b0;
            destReg_d3 <= 4'b0;
        end else begin
            carry_d3 <= carry_d2; // Feedback carry for next cycle
            write_enable_rf_d3 <= !(opcode_d2 == `NOP || opcode_d2 == `STORE);
            write_data_d3 <= (opcode_d2 == `LOAD) ? data_in_d1 : alu_result;
            addr_d3 <= addr_d2;
            alu_result_d3 <= alu_result;
            zero_d3 <= zero_d2;
            destReg_d3 <= destReg_d2;
        end    
    end

    assign alu_operand1 = alu_operand1_d2;
    assign alu_operand2 = alu_operand2_d2;
    assign write_enable_rf = write_enable_rf_d3;
    assign write_data = write_data_d3;
    assign out_reg = alu_result_d3;
    assign addr = addr_d3;
    assign data_out = data_out_d2;
    assign we = we_d2;
    assign zero = zero_d3;
    assign carry = carry_d3;

endmodule