`include "opcodes.vh"

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
        case (opcode)
            `ADDC: {carry_out, result} <= operand1 + operand2 + carry_in;
            `SUBC: {carry_out, result} <= operand1 - (operand2 + carry_in);
            `AND, `ANDI: {carry_out, result} <= {1'b0, operand1 & operand2};
            `OR, `ORI: {carry_out, result} <= {1'b0, operand1 | operand2};
            `XOR, `XORI: {carry_out, result} <= {1'b0, operand1 ^ operand2};
            `SHL: {carry_out, result} <= {1'b0, operand1 << operand2};
            `SHR: {carry_out, result} <= {1'b0, operand1 >> operand2};
            `SHRA: {carry_out, result} <= {1'b0, $signed(operand1) >>> operand2};
            `ADDI: {carry_out, result} <= {1'b0, operand1 + operand2}; // operand2 is immediate in this case
            `SUBI: {carry_out, result} <= {1'b0, operand1 - operand2}; // operand2 is immediate
            default: {carry_out, result} <= 17'b0;
        endcase

        // Set zero flag
        zero <= ({carry_out, result} == 17'b0) ? 1'b1 : 1'b0;
    end

/*
    always @(posedge clk or rst) begin
        if rst begin
            {zero, carry_out, result} <= 18'b0;
        end else begin
            case (opcode)
                `ADDC: {carry_out, result} <= operand1 + operand2 + carry_in;
                `SUBC: {carry_out, result} <= operand1 - (operand2 + carry_in);
                `AND, `ANDI: {carry_out, result} <= {1'b0, operand1 & operand2};
                `OR, `ORI: {carry_out, result} <= {1'b0, operand1 | operand2};
                `XOR, `XORI: {carry_out, result} <= {1'b0, operand1 ^ operand2};
                `SHL: {carry_out, result} <= {1'b0, operand1 << operand2};
                `SHR: {carry_out, result} <= {1'b0, operand1 >> operand2};
                `SHRA: {carry_out, result} <= {1'b0, $signed(operand1) >>> operand2};
                `ADDI: {carry_out, result} <= {1'b0, operand1 + operand2}; // operand2 is immediate in this case
                `SUBI: {carry_out, result} <= {1'b0, operand1 - operand2}; // operand2 is immediate
                default: {carry_out, result} <= 17'b0;
            endcase

            // Set zero flag
            zero <= ({carry_out, result} == 17'b0) ? 1'b1 : 1'b0;
        end
    end
*/

endmodule