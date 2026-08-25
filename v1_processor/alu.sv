//add, sub, xor, or, and, slt
module alu(
    input logic [31:0] alusrca, alusrcb,
    input [2:0] alucontrol,
    output [31:0] aluout,
    output zero
);
    assign zero = (aluout == 0) ? '1 : '0;

    always_comb begin
        case (alucontrol)
        3'b000 : aluout = alusrca + alusrcb;
        3'b001 : aluout = alusrca - alusrcb;
        3'b010 : aluout = alusrca ^ alusrcb;
        3'b011 : aluout = alusrca | alusrcb;
        3'b100 : aluout = alusrca & alusrcb;
        3'b101 : begin
            if ($signed(a) < $signed(b)) aluout = '1;
            else aluout = '0;
        end
        default : aluout = '0;
        endcase
    end
endmodule