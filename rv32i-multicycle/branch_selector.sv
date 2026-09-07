module branch_selector(
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    input logic carry, zero, negative, overflow,
    output logic branch
);
    always_comb begin
        if (opcode == 7'b1100011) begin
            case (funct3)
            3'd0 : branch = zero;
            3'd1 : branch = ~zero;
            3'd4 : branch = negative ^ overflow;
            3'd5 : branch = ~(negative ^ overflow);
            3'd6 : branch = ~carry;
            3'd7 : branch = carry;
            endcase
        end
        else branch = '0;
    end
endmodule