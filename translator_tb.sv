module translator_tb;
    enum {lw, sw, add, sub, xorfunc, orfunc, andfunc, sll, srl, sra, slt, sltu, beq, addi,
                  bne, blt, bge, bltu, bgeu, jal, jalr, lui, auipc} instructiontype;
    logic [4:0] rd, rs1, rs2;
    logic [11:0] imm;
    logic [31:0] machinecode;
    logic [20:0] imm_20bits;

    assemblytranslator dut(.instruction(instructiontype), .rd(rd), .rs1(rs1), .rs2(rs2),
                           .imm(imm), .machinecode(machinecode), .imm_20bits(imm_20bits));

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, translator_tb);
    end
    
    initial begin
        $monitor("%h", machinecode);
        instructiontype = lw;
        rd = '0;
        rs1 = '0;
        imm = '0;
        #5;

        // instructiontype = addi;
        // rd = 5'd1;
        // rs1 = '0;
        // imm = 12'd20;
        // #10;

        // instructiontype = addi;
        // rd = 5'd2;
        // rs1 = '0;
        // imm = 12'd20;
        // #10;

        // instructiontype = addi;
        // rd = 5'd3;
        // rs1 = '0;
        // imm = 12'd100;
        // #10;

        // instructiontype = jalr;
        // rd = 5'd4;
        // imm = 12'd8;
        // rs1 = 5'd1;
        // #10;

        // instructiontype = addi;
        // rd = 5'd0;
        // rs1 = 5'd0;
        // #10;

        instructiontype = auipc;
        rd = 5'd1;
        imm_20bits = 20'h00001;
        $finish;
    end
endmodule

//lw x4, 12(x0)
//lw x3, 12(x0)
//beq x3, x4, 1
//sw x4, 4(x0)
//add x2, x4, x3
//typedef enum {lw, sw, add, sub, beq} instruction_t;