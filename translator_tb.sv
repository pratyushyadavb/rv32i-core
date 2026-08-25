module translator_tb;
    enum {lw, sw, add, sub, xorfunc, orfunc, andfunc, sll, srl, sra, slt, sltu, beq, addi} instructiontype;
    logic [4:0] rd, rs1, rs2;
    logic [11:0] imm;
    logic [31:0] machinecode;

    assemblytranslator dut(.instruction(instructiontype), .rd(rd), .rs1(rs1), .rs2(rs2), .imm(imm), .machinecode(machinecode));

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

        instructiontype = addi;
        rd = 5'd1;
        rs1 = 5'd0;
        imm = 12'd37;
        #10;

        instructiontype = addi;
        rd = 5'd2;
        rs1 = 5'd0;
        imm = 12'd19;
        #10;

        instructiontype = sw;
        rs1 = 5'd1;
        rs2 = 5'd0;
        imm = 12'd16;
        #10;

        instructiontype = lw;
        rd = 5'd3;
        rs1 = 5'd0;
        imm = 12'd16;
        #10;

        instructiontype = add;
        rd = 5'd4;
        rs1 = 5'd0;
        rs2 = 5'd1;
        #10;

        instructiontype = beq;
        rs1 = 5'd1;
        rs2 = 5'd3;
        imm = 12'd8;
        #10;

        instructiontype = sub;
        rd = 5'd5;
        rs1 = 5'd1;
        rs2 = 5'd2;
        #10;

        instructiontype = add;
        rd = 5'd6;
        rs1 = 5'd1;
        rs2 = 5'd2;
        #10;

        instructiontype = addi;
        rd = 5'd7;
        rs1 = 5'd0;
        imm = 12'd10;
        #10;

        instructiontype = addi;
        rd = 5'd8;
        rs1 = 5'd0;
        imm = 12'd12;
        #10;

        instructiontype = addi;
        rd = 5'd9;
        rs1 = 5'd0;
        imm = 12'd49;
        #10;
        $finish;
    end
endmodule

//lw x4, 12(x0)
//lw x3, 12(x0)
//beq x3, x4, 1
//sw x4, 4(x0)
//add x2, x4, x3
//typedef enum {lw, sw, add, sub, beq} instruction_t;