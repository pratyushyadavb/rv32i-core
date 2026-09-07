module alu_decoder(
    input logic [2:0] funct3,
    input logic [1:0] aluop,
    input logic [6:0] funct7,
    input logic [6:0] opcode,
    output logic [3:0] alucontrol
);
    always_comb begin
        case (aluop)
        2'b00 : alucontrol = 4'b0000;
        2'b01 : alucontrol = 4'b0001;
        2'b10 : begin
            case (funct3)
            3'b000 : begin
                // Only R-type (aluop == 2'b10) checks funct7 for SUB
                if (aluop == 2'b10 && funct7 == 7'h20 && opcode == 7'b0110011) 
                    alucontrol = 4'b0001; // SUB
                else alucontrol = 4'b0000; // ADD / ADDI
            end
            3'd4 : alucontrol = 4'b0100; //xor
            3'd6 : alucontrol = 4'b0011; //or
            3'd7 : alucontrol = 4'b0010; //and
            3'd1 : alucontrol = 4'b0110; //sll
            3'd5 : begin
                if (funct7 == 7'd0) alucontrol = 4'b0111; //srl
                else if (funct7 == 7'h20) alucontrol = 4'b1000;
                else alucontrol = 4'b0111;
            end
            3'd2 : alucontrol = 4'b0101;
            3'd3 : alucontrol = 4'b1001;
            default : alucontrol = 4'd0;
            endcase
        end
        default : alucontrol = 4'd0;
        endcase
    end
endmodule