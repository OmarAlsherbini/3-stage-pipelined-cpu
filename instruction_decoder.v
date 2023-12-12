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