package definitions;
    typedef enum {lw, sw, add, sub, xorfunc, orfunc, andfunc, sll, srl, sra, slt, sltu, beq, addi,
                  bne, blt, bge, bltu, bgeu, jal, jalr, lui, auipc, lb, lh, lbu, lhu,
                  sb, sh} instruction_t;
endpackage

import definitions::*;
//lw, sw, add, sub, beq
module assemblytranslator(
    input definitions::instruction_t [3:0] instruction,
    input logic [4:0] rd, rs1, rs2,
    input logic [11:0] imm,
    input logic [20:0] imm_20bits,
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
        lb : begin
            machinecode[6:0] = 7'b0000011;
            machinecode[14:12] = 3'd0;
            machinecode[11:7] = rd;
            machinecode[19:15] = rs1;
            machinecode[31:20] = imm;
        end
        lh : begin
            machinecode[6:0] = 7'b0000011;
            machinecode[14:12] = 3'd1;
            machinecode[11:7] = rd;
            machinecode[19:15] = rs1;
            machinecode[31:20] = imm;
        end
        lbu : begin
            machinecode[6:0] = 7'b0000011;
            machinecode[14:12] = 3'd4;
            machinecode[11:7] = rd;
            machinecode[19:15] = rs1;
            machinecode[31:20] = imm;
        end
        lhu : begin
            machinecode[6:0] = 7'b0000011;
            machinecode[14:12] = 3'd5;
            machinecode[11:7] = rd;
            machinecode[19:15] = rs1;
            machinecode[31:20] = imm;
        end
        sw : begin
            machinecode[6:0] = 7'b0100011;
            machinecode[14:12] = 3'd2;
            machinecode[19:15] = rs2;
            machinecode[24:20] = rs1;
            machinecode[31:25] = imm[11:5];
            machinecode[11:7] = imm[4:0];
        end
        sb : begin
            machinecode[6:0] = 7'b0100011;
            machinecode[14:12] = 3'd0;
            machinecode[19:15] = rs2;
            machinecode[24:20] = rs1;
            machinecode[31:25] = imm[11:5];
            machinecode[11:7] = imm[4:0];
        end
        sh : begin
            machinecode[6:0] = 7'b0100011;
            machinecode[14:12] = 3'd1;
            machinecode[19:15] = rs2;
            machinecode[24:20] = rs1;
            machinecode[31:25] = imm[11:5];
            machinecode[11:7] = imm[4:0];
        end
        add : begin
            machinecode[6:0] = 7'b0110011; //opcode
            machinecode[14:12] = 3'd0; //funct3
            machinecode[31:25] = 7'd0; //funct7
            machinecode[11:7] = rd; //rd
            machinecode[19:15] = rs1; //rs1
            machinecode[24:20] = rs2; //rs2
        end
        sub : begin
            machinecode[6:0] = 7'b0110011;
            machinecode[14:12] = 3'd0;
            machinecode[31:25] = 7'h20;
            machinecode[11:7] = rd;
            machinecode[19:15] = rs1;
            machinecode[24:20] = rs2;
        end
        xorfunc : begin
            machinecode[6:0] = 7'b0110011; //opcode
            machinecode[14:12] = 3'd4; //funct3
            machinecode[31:25] = 7'd0; //funct7
            machinecode[11:7] = rd; //rd
            machinecode[19:15] = rs1; //rs1
            machinecode[24:20] = rs2; //rs2
        end
        orfunc : begin
            machinecode[6:0] = 7'b0110011; //opcode
            machinecode[14:12] = 3'd6; //funct3
            machinecode[31:25] = 7'd0; //funct7
            machinecode[11:7] = rd; //rd
            machinecode[19:15] = rs1; //rs1
            machinecode[24:20] = rs2; //rs2
        end
        andfunc : begin
            machinecode[6:0] = 7'b0110011; //opcode
            machinecode[14:12] = 3'd0; //funct3
            machinecode[31:25] = 7'd0; //funct7
            machinecode[11:7] = rd; //rd
            machinecode[19:15] = rs1; //rs1
            machinecode[24:20] = rs2; //rs2
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
        sll : begin
            machinecode[6:0] = 7'b0110011; //opcode
            machinecode[14:12] = 3'd1; //funct3
            machinecode[31:25] = 7'd0; //funct7
            machinecode[11:7] = rd; //rd
            machinecode[19:15] = rs1; //rs1
            machinecode[24:20] = rs2; //rs2
        end
        srl : begin
            machinecode[6:0] = 7'b0110011; //opcode
            machinecode[14:12] = 3'd5; //funct3
            machinecode[31:25] = 7'd0; //funct7
            machinecode[11:7] = rd; //rd
            machinecode[19:15] = rs1; //rs1
            machinecode[24:20] = rs2; //rs2
        end
        sra : begin
            machinecode[6:0] = 7'b0110011; //opcode
            machinecode[14:12] = 3'd5; //funct3
            machinecode[31:25] = 7'd2; //funct7
            machinecode[11:7] = rd; //rd
            machinecode[19:15] = rs1; //rs1
            machinecode[24:20] = rs2; //rs2
        end
        sltu : begin
            machinecode[6:0] = 7'b0110011; //opcode
            machinecode[14:12] = 3'd3; //funct3
            machinecode[31:25] = 7'd0; //funct7
            machinecode[11:7] = rd; //rd
            machinecode[19:15] = rs1; //rs1
            machinecode[24:20] = rs2; //rs2
        end
        addi : begin
            machinecode[6:0] = 7'b0010011; //opcode
            machinecode[14:12] = 3'd0; //funct3
            machinecode[31:20] = imm[11:0]; //imm
            machinecode[11:7] = rd; //rd
            machinecode[19:15] = rs1; //rs1
        end
        bne : begin
            machinecode[6:0] = 7'b1100011;
            machinecode[14:12] = 3'd1;
            machinecode[19:15] = rs1;
            machinecode[24:20] = rs2;
            machinecode[31] = imm[11];
            machinecode[30:25] = imm[9:4];
            machinecode[11:8] = imm[3:0];
            machinecode[7] = imm[10];
        end
        blt : begin
            machinecode[6:0] = 7'b1100011;
            machinecode[14:12] = 3'd4;
            machinecode[19:15] = rs1;
            machinecode[24:20] = rs2;
            machinecode[31] = imm[11];
            machinecode[30:25] = imm[9:4];
            machinecode[11:8] = imm[3:0];
            machinecode[7] = imm[10];
        end
        bge : begin
            machinecode[6:0] = 7'b1100011;
            machinecode[14:12] = 3'b101;
            machinecode[19:15] = rs1;
            machinecode[24:20] = rs2;
            machinecode[31] = imm[11];
            machinecode[30:25] = imm[9:4];
            machinecode[11:8] = imm[3:0];
            machinecode[7] = imm[10];
        end
        bltu : begin
            machinecode[6:0] = 7'b1100011;
            machinecode[14:12] = 3'b110;
            machinecode[19:15] = rs1;
            machinecode[24:20] = rs2;
            machinecode[31] = imm[11];
            machinecode[30:25] = imm[9:4];
            machinecode[11:8] = imm[3:0];
            machinecode[7] = imm[10];
        end
        bgeu : begin
            machinecode[6:0] = 7'b1100011;
            machinecode[14:12] = 3'b111;
            machinecode[19:15] = rs1;
            machinecode[24:20] = rs2;
            machinecode[31] = imm[11];
            machinecode[30:25] = imm[9:4];
            machinecode[11:8] = imm[3:0];
            machinecode[7] = imm[10];
        end
        jal : begin
            machinecode[31] = imm_20bits[20];
            machinecode[30:21] = imm_20bits[10:1];
            machinecode[20] = imm_20bits[11];
            machinecode[19:12] = imm_20bits[19:12];
            machinecode[11:7] = rd;
            machinecode[6:0] = 7'b1101111;
        end
        jalr : begin
            machinecode[31:20] = imm[11:0];
            machinecode[19:15] = rs1;
            machinecode[14:12] = 3'd0;
            machinecode[11:7] = rd;
            machinecode[6:0] = 7'b1100111;
        end
        lui : begin
            machinecode[31:12] = imm_20bits;
            machinecode[11:7] = rd;
            machinecode[6:0] = 7'b0110111;
        end
        auipc : begin
            machinecode[31:12] = imm_20bits;
            machinecode[11:7] = rd;
            machinecode[6:0] = 7'b0010111;
        end
        endcase
    end
endmodule