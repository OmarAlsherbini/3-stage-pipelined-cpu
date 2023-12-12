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
    instruction_decoder id (
        .instruction (instruction),
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
        .write_reg(destReg),
        .write_data(write_data),
        .write_enable(write_enable),
        .read_data1(reg_data1),
        .read_data2(reg_data2)
    );

    alu alu_unit (
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