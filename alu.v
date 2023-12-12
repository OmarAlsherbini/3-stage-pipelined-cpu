`include "opcodes.vh"

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