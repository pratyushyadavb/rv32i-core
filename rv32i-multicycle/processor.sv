module main_processor(
    input logic clock, reset,
    output logic [4:0] a1, a2, a3,
    output logic [6:0] opcode, funct7,
    output logic [3:0] aluctrl,
    output logic [1:0] srca, srcb, wd3ctrl,
    output logic we, re, iord, pcwrite, funct3ctrl, instrEnable, we3, oldpcenable, alump, branch,
    output logic [2:0] immctrl, funct3,
    output logic [31:0] mainimm,
    output logic [31:0] pc, pc_new, oldpc,
    output logic [31:0] rd1, rd2, wd3,
    output logic [31:0] instr,
    output logic [31:0] rd, wd,
    output state_t state, nextstate,
    output logic [31:0] alusrca, alusrcb, aluout, alulatch
);
    logic pc_read;
    datapath main_datapath(.clock(clock), .reset(reset), .we(we), .re(re), .iord(iord), .pcwrite(pcwrite),
                           .funct3ctrl(funct3ctrl), .instrEnable(instrEnable), .we3(we3), .oldpcenable(oldpcenable),
                           .alump(alump), .srca(srca), .srcb(srcb), .wd3ctrl(wd3ctrl), .aluctrl(aluctrl), .immctrl(immctrl),
                           .funct3(funct3), .opcode(opcode), .branch(branch), .funct7(funct7),
                           .a1(a1), .a2(a2), .a3(a3), .mainimm(mainimm), .pc(pc), .pc_new(pc_new),
                           .oldpc(oldpc), .rd1(rd1), .rd2(rd2), .wd3(wd3), .instr(instr),
                           .rd(rd), .wd(wd), .pc_read(pc_read), .alusrca(alusrca), .alusrcb(alusrcb),
                           .aluout(aluout), .alulatch(alulatch));


    control_unit main_controlunit(.clock(clock), .reset(reset), .branch(branch), .opcode(opcode),
                                  .funct3(funct3), .funct7(funct7), .we(we), .re(re), .iord(iord),
                                  .pcwrite(pcwrite), .funct3ctrl(funct3ctrl), .instrEnable(instrEnable),
                                  .we3(we3), .oldpcenable(oldpcenable), .alump(alump), .srca(srca),
                                  .srcb(srcb), .wd3ctrl(wd3ctrl), .aluctrl(aluctrl), .immctrl(immctrl),
                                  .state(state), .nextstate(nextstate), .pc_read(pc_read));
endmodule