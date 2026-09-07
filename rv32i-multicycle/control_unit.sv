module control_unit(
    input logic clock, reset, branch,
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    output logic we, re, iord, pcwrite, funct3ctrl, instrEnable, we3, oldpcenable, alump,
    output logic [1:0] srca, srcb, wd3ctrl,
    output logic [3:0] aluctrl,
    output logic [2:0] immctrl,
    output state_t state, nextstate,
    output logic pc_read
);
    logic [1:0] aluop;
    
    main_fsm main_mainfsm(.clock(clock), .reset(reset), .branch(branch), .opcode(opcode),
                          .we(we), .re(re), .iord(iord), .pcwrite(pcwrite), .funct3ctrl(funct3ctrl),
                          .instrEnable(instrEnable), .we3(we3), .oldpcenable(oldpcenable), .alump(alump),
                          .srca(srca), .srcb(srcb), .wd3ctrl(wd3ctrl), .aluop(aluop),
                          .immctrl(immctrl), .state(state), .nextstate(nextstate), .pc_read(pc_read));

    alu_decoder main_aludecoder(.funct3(funct3), .aluop(aluop), .funct7(funct7), .alucontrol(aluctrl),
                                .opcode(opcode));
endmodule