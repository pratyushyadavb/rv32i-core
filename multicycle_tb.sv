module multicycle_tb;
    logic clock, reset;
    logic [4:0] a1, a2, a3;
    logic [6:0] opcode, funct7;
    logic [3:0] aluctrl;
    logic [1:0] srca, srcb, wd3ctrl;
    logic we, re, iord, pcwrite, funct3ctrl, instrEnable, we3, oldpcenable, alump, branch;
    logic [2:0] immctrl, funct3;
    logic [31:0] mainimm;
    logic [31:0] pc, pc_new, oldpc, rd1, rd2, wd3, instr, rd, wd;
    state_t state, nextstate;
    logic [31:0] alusrca, alusrcb, aluout, alulatch

    always #5 clock = ~clock;

    main_processor dut(
        .clock(clock),
        .reset(reset),
        .a1(a1), .a2(a2), .a3(a3), .opcode(opcode), .funct7(funct7), .aluctrl(aluctrl),
        .srca(srca), .srcb(srcb), .wd3ctrl(wd3ctrl), .we(we), .re(re), .iord(iord), .pcwrite(pcwrite),
        .funct3ctrl(funct3ctrl), .instrEnable(instrEnable), .we3(we3), .oldpcenable(oldpcenable),
        .alump(alump), .branch(branch), .immctrl(immctrl), .funct3(funct3), .mainimm(mainimm),
        .pc(pc), .pc_new(pc_new), .oldpc(oldpc), .rd1(rd1), .rd2(rd2), .wd3(wd3), .instr(instr),
        .rd(rd), .wd(wd), .state(state), .nextstate(nextstate), .alusrca(alusrca), .alusrcb(alusrcb),
        .aluout(aluout), .alulatch(alulatch)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, multicycle_tb);
    end

    initial begin
        clock = 0;
        reset = 1;
        #10;
        reset = 0;
        #100;
        $finish;
    end
endmodule