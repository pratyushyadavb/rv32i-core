module alu(
    input logic [31:0] alusrca, alusrcb,
    input [3:0] alucontrol,
    output logic [31:0] aluout,
    output zero
);
    assign zero = (aluout == 0) ? '1 : '0;

    always_comb begin
        case (alucontrol)
        4'd0 : aluout = alusrca + alusrcb;
        4'd1 : aluout = alusrca - alusrcb;
        4'd2 : aluout = alusrca ^ alusrcb;
        4'd3 : aluout = alusrca | alusrcb;
        4'd4 : aluout = alusrca & alusrcb;
        4'd5 : begin
            if ($signed(alusrca) < $signed(alusrcb)) aluout = '1;
            else aluout = '0;
        end
        4'd6 : aluout = alusrca << alusrcb;
        4'd7 : aluout = alusrca >> alusrcb;
        4'd8 : begin
            aluout = alusrca >> alusrcb;
            if (alusrca[31-alusrcb] == '1) begin
                aluout = 
            end
            
        end
        default : aluout = '0;
        endcase
    end
endmodule