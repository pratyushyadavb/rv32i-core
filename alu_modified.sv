module alu (
    input  logic [31:0] src_a,
    input  logic [31:0] src_b,
    input  logic [3:0]  alu_control,
    output logic [31:0] alu_result,
    output logic        zero,
    output logic        carry,
    output logic        negative,
    output logic        overflow
);
    logic [32:0] ext_result;
    logic        is_sub;

    assign is_sub = (alu_control == 4'b0001);

    always_comb begin
        ext_result = 33'b0;
        case (alu_control)
            4'b0000: ext_result = {1'b0, src_a} + {1'b0, src_b}; //add
            4'b0001: ext_result = {1'b0, src_a} + {1'b0, ~src_b} + 33'b1; //subtraction using 2's complement
            4'b0010: ext_result = {1'b0, src_a & src_b}; //and
            4'b0011: ext_result = {1'b0, src_a | src_b}; //or
            4'b0100: ext_result = {1'b0, src_a ^ src_b}; //xor
            4'b0101: ext_result = {1'b0, ($signed(src_a) < $signed(src_b)) ? 32'b1 : 32'b0}; //slt
            4'b0110: ext_result = {1'b0, src_a << src_b[4:0]}; //sll
            4'b0111: ext_result = {1'b0, src_a >> src_b[4:0]}; //srl
            4'b1000: ext_result = {1'b0, $signed(src_a) >>> src_b[4:0]}; //sra
            4'b1001: ext_result = {1'b0, (srca < srcb) ? 32'b1 : 32'b0}; //sltu
            default: ext_result = 33'b0;
        endcase
    end

    assign alu_result = ext_result[31:0];

    assign zero     = (alu_result == 32'b0);
    assign negative = alu_result[31];
    assign carry    = ext_result[32];
    assign overflow = is_sub ? ((src_a[31] ^ src_b[31]) & (src_a[31] ^ alu_result[31]))
                             : (~(src_a[31] ^ src_b[31]) & (src_a[31] ^ alu_result[31]));

endmodule