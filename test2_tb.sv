module test2_tb;
    logic [2:0] instructiontype;
    logic [4:0] rd, rs1, rs2;
    logic [11:0] imm;
    logic [31:0] machinecode;

    assemblycompiler dut(.instruction(instructiontype), .rd(rd), .rs1(rs1), .rs2(rs2), .imm(imm), .machinecode(machinecode));

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, test2_tb);
    end
    
    initial begin
        $monitor("machinecode: %h", machinecode);
        instructiontype = '0;
        rd = '0;
        rs1 = '0;
        imm = '0;
        #5;

        instructiontype = 3'b000;;
        rd = 5'd4;
        rs1 = 5'd0;
        imm = 12'd12;
        #10;

        instructiontype = 3'b000;
        rd = 5'd3;
        rs1 = 5'd0;
        imm = 12'd12;
        #10;

        instructiontype = 3'b100;
        rs1 = 5'd3;
        rs2 = 5'd4;
        imm = 12'd1;
        #10;

        instructiontype = 3'b001;
        rs1 = 5'd4;
        rs2 = 5'd0;
        imm = 12'd4;
        #10;

        instructiontype = 3'b010;
        rd = 5'd2;
        rs1 = 5'd4;
        rs2 = 5'd3;
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