module instruction_decoder (
    input reg [31:0] instruction,
    output reg [3:0] opcode,
    output reg [3:0] reg1,
    output reg [3:0] reg2,
    output reg [3:0] destReg,
    output reg [15:0] immediate
);

    always @(*) begin
        // Decode the Opcode
        opcode = instruction[31:28];

        // Decode the Register Identifiers
        reg1 = instruction[27:24];
        reg2 = instruction[23:20];
        destReg = instruction[19:16];

        // Decode the Immediate Value
        immediate = instruction[15:0];
    end
/*
    always @(posedge clk or rst) begin
        if rst begin
            // Decode the Opcode
            opcode <= 4'b0;

            // Decode the Register Identifiers
            reg1 <= 4'b0;
            reg2 <= 4'b0;
            destReg <= 4'b0;
*/

endmodule