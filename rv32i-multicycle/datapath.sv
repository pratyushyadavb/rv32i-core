module datapath(
    input logic clock, reset, we, re, iord, pcwrite, funct3ctrl, instrEnable, we3, oldpcenable, alump,
    input logic [1:0] srca, srcb, wd3ctrl,
    input logic pc_read,
    input logic [3:0] aluctrl,
    input logic [2:0] immctrl,
    output logic [2:0] funct3,
    output logic [6:0] funct7,
    output logic [6:0] opcode,
    output logic [4:0] a1, a2, a3,
    output logic branch,
    output logic [31:0] mainimm,
    output logic [31:0] pc, pc_new, oldpc,
    output logic [31:0] rd1, rd2, wd3,
    output logic [31:0] instr,
    output logic [31:0] rd, wd,
    output logic [31:0] alusrca, alusrcb, aluout, alulatch
);
    logic [31:0] addr;
    logic [2:0] funct3formemory;
    logic [31:0] datafrom_memory, a, b;
    logic zero, overflow, negative, carry;
    logic [31:0] alu_final_out;
    
    

    
    assign wd = rd2;
    assign funct7 = instr[31:25];
    assign funct3 = instr[14:12];
    assign opcode = instr[6:0];
    assign alu_final_out = (alump) ? alulatch : aluout;
    assign addr = (iord) ? alulatch : pc;
    assign funct3formemory = (funct3ctrl) ? 3'b010 : funct3;
    assign pc_new = (opcode == 7'b1100111) ? {alu_final_out[31:1], 1'b0} : alu_final_out;
    assign a1 = instr[19:15];
    assign a2 = instr[24:20];
    assign a3 = instr[11:7];


    
                                        
    always_comb begin
        if (immctrl == 3'd0) mainimm = {{20{instr[31]}}, instr[31:20]};
        else if (immctrl == 3'd1) mainimm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
        else if (immctrl == 3'd2) begin // B-Type
            mainimm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            end
        else if (immctrl == 3'd3) mainimm = {instr[31:12], {12{1'b0}}};
        else if (immctrl == 3'd4) mainimm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
    end
    always_comb begin
        if (srcb == 2'd0) alusrcb = b;
        else if (srcb == 2'd1) alusrcb = 32'd4;
        else if (srcb == 2'd3) alusrcb = mainimm;
    end
    always_comb begin
        if (srca == 2'd0) alusrca = pc;
        else if (srca == 2'd1) alusrca = oldpc;
        else if (srca == 2'd2) alusrca = a;
    end
    always_ff @ (posedge clock) begin
        alulatch <= aluout;
    end
    always_ff @ (posedge clock) begin
        if (oldpcenable) oldpc <= pc;
    end
    always_ff @ (posedge clock, posedge reset) begin
        if (reset) pc <= '0;
        else if (pcwrite) pc <= pc_new;
    end 
    always_ff @ (posedge clock, posedge reset) begin
        if (reset) instr <= '0;
        else if (instrEnable) instr <= rd;
    end
    always_ff @ (posedge clock) begin
        datafrom_memory <= rd;
        a <= rd1;
        b <= rd2;
    end
    always_comb begin
        case (wd3ctrl)
        2'b00 : wd3 = datafrom_memory;
        2'b01 : wd3 = alu_final_out;
        2'b10 : wd3 = oldpc + 32'd4;
        2'b11 : wd3 = mainimm;
        endcase
    end

    branch_selector main_branchselector(.opcode(opcode), .funct3(funct3), .carry(carry), .zero(zero),
                                        .negative(negative), .overflow(overflow), .branch(branch));
    memory mainmemory(.addr(addr), .wd(wd), .funct3(funct3formemory), .clock(clock), .we(we),
                      .re(re), .rd(rd), .pc_read(pc_read));
    regfile mainregfile(.x1(a1), .x2(a2), .x3(a3), .wd3(wd3), .clock(clock), .we3(we3), .rd1(rd1),
                        .rd2(rd2));
    alu mainalu(.src_a(alusrca), .src_b(alusrcb), .alu_control(aluctrl), .alu_result(aluout),
                .zero(zero), .carry(carry), .negative(negative), .overflow(overflow));
endmodule