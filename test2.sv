package definitions;
    typedef enum {lw, sw, add, sub, beq} instruction_t;
endpackage

import definitions::*;

module assemblycompiler(
    input definitions::instruction_t [2:0] instruction,
    input logic [4:0] rd, rs1, rs2,
    input logic [11:0] imm,
    output logic [31:0] machinecode
);
    always_comb begin
        case (instruction)
        lw : begin machinecode[6:0] = 7'b0000011; 
            machinecode[14:12] = 3'd2;
            machinecode[11:7] = rd;
            machinecode[19:15] = rs1;
            machinecode[31:20] = imm;
        end
        sw : begin
            machinecode[6:0] = 7'b0100011;
            machinecode[14:12] = 3'd2;
            machinecode[19:15] = rs1;
            machinecode[24:20] = rs2;
            machinecode[31:25] = imm[11:5];
            machinecode[11:7] = imm[4:0];
        end
        add : begin
            machinecode[6:0] = 7'b0110011;
            machinecode[14:12] = 3'd0;
            machinecode[31:25] = 7'd0;
            machinecode[11:7] = rd;
            machinecode[19:15] = rs1;
            machinecode[24:20] = rs2;
        end
        sub : begin
            machinecode[6:0] = 7'b0110011;
            machinecode[14:12] = 3'd0;
            machinecode[31:25] = 7'h20;
            machinecode[11:7] = rd;
            machinecode[19:15] = rs1;
            machinecode[24:20] = rs2;
        end
        beq : begin
            machinecode[6:0] = 7'b1100011;
            machinecode[14:12] = '0;
            machinecode[19:15] = rs1;
            machinecode[24:20] = rs2;
            machinecode[31] = imm[11];
            machinecode[30:25] = imm[9:4];
            machinecode[11:8] = imm[3:0];
            machinecode[7] = imm[10];
        end
        endcase
    end
endmodule