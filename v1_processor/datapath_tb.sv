module datapath_tb;
    logic clock, reset, we, re, branch, zero;
    logic [31:0] rd1, rd2, wd3;
    logic [4:0] x1, x2, x3;
    logic [31:0] signed_imm, pc, instr, rd, aluout, forbeq;
    logic [3:0] alucontrol;

    processor dut(
        .clock(clock), .reset(reset), .rd1(rd1), .rd2(rd2), .wd3(wd3),
        .x1(x1), .x2(x2), .x3(x3), .signed_imm(signed_imm), .pc(pc), .instr(instr),
        .rd(rd), .re(re), .we(we), .aluout(aluout), .alucontrol(alucontrol),
        .zero(zero), .forbeq(forbeq), .branch(branch)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, datapath_tb);
    end

    always #5 clock = ~clock;

    initial begin
        clock = '0;
        reset = '1;
        #10;
        reset = '0;
        #200;
        $monitor("rd1: %d; rd2: %d; wd3: %d; x1: %d; x2: %d; x3: %d; signedimm: %d", rd1, rd2, wd3, x1, x2, x3, signed_imm);

        $finish;
    end
endmodule