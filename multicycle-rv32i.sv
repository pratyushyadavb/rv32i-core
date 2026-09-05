module regfile(
    input logic [4:0] x1, x2, x3,
    input logic [31:0] wd3,
    input clock, we3,
    output logic [31:0] rd1, rd2
);
    logic [31:0] registers [0:31];

    assign rd1 = (x1 == '0) ? '0 : registers[x1];
    assign rd2 = (x2 == '0) ? '0 : registers[x2];

    always_ff @ (posedge clock) begin
    if (we3 && x3 != 5'b0) registers[x3] <= wd3;
    end
endmodule

module memory(
    input logic [31:0] addr,
    input logic pc_read,
    input logic [31:0] wd,
    input logic [2:0] funct3,
    input logic clock, we, re,
    output logic [31:0] rd
);
    logic [31:0] ram [0:255] = '{128: 32'hDEAD_BEEF, default: 32'h0};
    logic [7:0] word_idx;
    assign word_idx = addr[9:2];

    initial begin
        $readmemh("program.hex", ram);
    end

    always_ff @(posedge clock) begin
        if (we) begin
            case (funct3[1:0])
                2'b00: begin // SB
                    case (addr[1:0])
                        2'b00: ram[word_idx][7:0]   <= wd[7:0];
                        2'b01: ram[word_idx][15:8]  <= wd[7:0];
                        2'b10: ram[word_idx][23:16] <= wd[7:0];
                        2'b11: ram[word_idx][31:24] <= wd[7:0];
                    endcase
                end
                2'b01: begin // SH
                    if (addr[1] == 1'b0)
                        ram[word_idx][15:0]  <= wd[15:0];
                    else
                        ram[word_idx][31:16] <= wd[15:0];
                end
                2'b10: begin // SW
                    ram[word_idx] <= wd;
                end
                default: ram[word_idx] <= wd;
            endcase
        end
    end

    always_comb begin
        if (pc_read) begin rd = ram[word_idx]; end//for pc
        else if (re) begin //need to implement the opcode 0 for when pc is reading
            case (funct3)
                3'b000: begin // LB
                    case (addr[1:0])
                        2'b00: rd = {{24{ram[word_idx][7]}},  ram[word_idx][7:0]};
                        2'b01: rd = {{24{ram[word_idx][15]}}, ram[word_idx][15:8]};
                        2'b10: rd = {{24{ram[word_idx][23]}}, ram[word_idx][23:16]};
                        2'b11: rd = {{24{ram[word_idx][31]}}, ram[word_idx][31:24]};
                    endcase
                end
                3'b001: begin // LH
                    if (addr[1] == 1'b0)
                        rd = {{16{ram[word_idx][15]}}, ram[word_idx][15:0]};
                    else
                        rd = {{16{ram[word_idx][31]}}, ram[word_idx][31:16]};
                end
                3'b010: rd = ram[word_idx]; // LW
                3'b100: begin // LBU
                    case (addr[1:0])
                        2'b00: rd = {24'b0, ram[word_idx][7:0]};
                        2'b01: rd = {24'b0, ram[word_idx][15:8]};
                        2'b10: rd = {24'b0, ram[word_idx][23:16]};
                        2'b11: rd = {24'b0, ram[word_idx][31:24]};
                    endcase
                end
                3'b101: begin // LHU
                    if (addr[1] == 1'b0)
                        rd = {16'b0, ram[word_idx][15:0]};
                    else
                        rd = {16'b0, ram[word_idx][31:16]};
                end
                default: rd = ram[word_idx];
            endcase
        end
        else rd = 32'd0;
    end
endmodule

module alu (
    input  logic [31:0] src_a,
    input  logic [31:0] src_b,
    input  logic [3:0]  alu_control,
    output logic [31:0] alu_result,
    output logic        zero,
    output logic        carry,
    output logic        negative,
    output logic        overflow
);
    logic [32:0] ext_result;
    logic        is_sub;

    assign is_sub = (alu_control == 4'b0001);

    always_comb begin
        ext_result = 33'b0;
        case (alu_control)
            4'b0000: ext_result = {1'b0, src_a} + {1'b0, src_b}; //add
            4'b0001: ext_result = {1'b0, src_a} + {1'b0, ~src_b} + 33'b1; //subtraction using 2's complement
            4'b0010: ext_result = {1'b0, src_a & src_b}; //and
            4'b0011: ext_result = {1'b0, src_a | src_b}; //or
            4'b0100: ext_result = {1'b0, src_a ^ src_b}; //xor
            4'b0101: ext_result = {1'b0, ($signed(src_a) < $signed(src_b)) ? 32'b1 : 32'b0}; //slt
            4'b0110: ext_result = {1'b0, src_a << src_b[4:0]}; //sll
            4'b0111: ext_result = {1'b0, src_a >> src_b[4:0]}; //srl
            4'b1000: ext_result = {1'b0, $signed(src_a) >>> src_b[4:0]}; //sra
            4'b1001: ext_result = {1'b0, (src_a < src_b) ? 32'b1 : 32'b0}; //sltu
            default: ext_result = 33'b0;
        endcase
    end

    assign alu_result = ext_result[31:0];

    assign zero     = (alu_result == 32'b0);
    assign negative = alu_result[31];
    assign carry    = ext_result[32];
    assign overflow = is_sub ? ((src_a[31] ^ src_b[31]) & (src_a[31] ^ alu_result[31]))
                             : (~(src_a[31] ^ src_b[31]) & (src_a[31] ^ alu_result[31]));

endmodule

module branch_selector(
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    input logic carry, zero, negative, overflow,
    output logic branch
);
    always_comb begin
        if (opcode == 7'b1100011) begin
            case (funct3)
            3'd0 : branch = zero;
            3'd1 : branch = ~zero;
            3'd4 : branch = negative ^ overflow;
            3'd5 : branch = ~(negative ^ overflow);
            3'd6 : branch = ~carry;
            3'd7 : branch = carry;
            endcase
        end
        else branch = '0;
    end
endmodule

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
    
    
    assign wd = rd2;

    logic [31:0] datafrom_memory, a, b;
    
    logic zero, overflow, negative, carry;
    
    logic [31:0] alu_final_out;

    assign funct7 = instr[31:25];
    assign funct3 = instr[14:12];
    assign opcode = instr[6:0];

    branch_selector main_branchselector(.opcode(opcode), .funct3(funct3), .carry(carry), .zero(zero),
                                        .negative(negative), .overflow(overflow), .branch(branch));
                                        
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

    assign alu_final_out = (alump) ? alulatch : aluout;
    assign addr = (iord) ? alulatch : pc;
    assign funct3formemory = (funct3ctrl) ? 3'b010 : funct3;
    assign pc_new = (opcode == 7'b1100111) ? {alu_final_out[31:1], 1'b0} : alu_final_out;
    memory mainmemory(.addr(addr), .wd(wd), .funct3(funct3formemory), .clock(clock), .we(we),
                      .re(re), .rd(rd), .pc_read(pc_read));

    always_ff @ (posedge clock, posedge reset) begin
        if (reset) instr <= '0;
        else if (instrEnable) instr <= rd;
    end

    assign a1 = instr[19:15];
    assign a2 = instr[24:20];
    assign a3 = instr[11:7];

    regfile mainregfile(.x1(a1), .x2(a2), .x3(a3), .wd3(wd3), .clock(clock), .we3(we3), .rd1(rd1),
                        .rd2(rd2));
    

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

    alu mainalu(.src_a(alusrca), .src_b(alusrcb), .alu_control(aluctrl), .alu_result(aluout),
                .zero(zero), .carry(carry), .negative(negative), .overflow(overflow));
endmodule

typedef enum logic [4:0] {
    S0, S1, S2, S3, S4, S5, S6, S7, 
    S8, S9, S10, S11, S12, S13, S14, S15, S16
} state_t;

module main_fsm(
    input logic clock, reset, branch,
    input logic [6:0] opcode,
    output logic we, re, iord, pcwrite, funct3ctrl, instrEnable, we3, oldpcenable, alump, pc_read,
    output logic [1:0] srca, srcb, wd3ctrl,
    output logic [1:0] aluop,
    output logic [2:0] immctrl,
    output state_t state, nextstate
);

    always_ff @ (posedge clock, posedge reset) begin
        if (reset) state <= S0;
        else state <= nextstate;
    end

    always_comb begin
        we = '0; re = '0; iord = '0; pcwrite = '0; funct3ctrl = '0;
        instrEnable = '0; we3 = '0; oldpcenable = '0; alump = '0;
        srca = '0; srcb = '0; wd3ctrl = '0;
        aluop = '0; immctrl = '0; pc_read = '0;
        //aluctrl
        case (state)
        S0 : begin
            oldpcenable = '1;
            alump = '0;
            srcb = 2'b01;
            aluop = 2'b00;
            srca = 2'b00;
            instrEnable = '1;
            pc_read = '1;
            pcwrite = '1;
        end
        S1 : begin
            srca = 2'b01;
            srcb = 2'b11;
            immctrl = 3'b010;
            aluop = '0;
        end
        S2 : begin
            srca = 2'b01;
            srcb = 2'b11;
            immctrl = 3'b000;
            aluop = '0;
        end
        S3 : begin
            iord = '1;
            alump = '1;
            re = '1;
        end
        S4 : begin
            wd3ctrl = 3'b000;
            we3 = '1;
        end
        S5 : begin
            srca = 2'b10;
            srcb = 2'b11;
            immctrl = 3'b001;
            aluop = 2'b00;
        end
        S6 : begin
            // alump = '1;
            iord = '1;
            we = '1;
        end
        S7 : begin
            srca = 2'b10;
            srcb = '0;
            aluop = 2'b10;
        end
        S8 : begin
            alump = '1;
            wd3ctrl = 3'b001;
            we3 = '1;
        end
        S9 : begin
            srca = 2'b10;
            srcb = 2'b11;
            aluop = 2'b10;
            immctrl = 3'b000;
        end
        S16 : begin
            alump = '1;
            wd3ctrl = 2'b01;
            we3 = '1;
        end
        S10 : begin
            immctrl = 3'b011;
            wd3ctrl = 2'b11;
            we3 = '1;
        end
        S11 : begin
            srca = 2'b10;
            srcb = 2'b00;
            aluop = 2'b01;
            alump = '1;
            pcwrite = branch;
        end
        S12 : begin
            immctrl = 3'b011;
            aluop = '0;
            srca = 2'b01;
            srcb = 2'b11;
            alump = '0;
            wd3ctrl = 2'b01;
            we3 = '1;
        end
        S13 : begin
            wd3ctrl = 2'b10;
            we3 = '1;
            srca = 2'b01;
            srcb = 2'b11;
            immctrl = 3'b100;
            alump = '0;
            pcwrite = '1;
        end
        S14 : begin
            srca = 2'b10;
            srcb = 2'b11;
            immctrl = 3'd0;
            aluop = '0;
            alump = '0;
            we3 = '1;
            wd3ctrl = 2'b10;
            pcwrite = '1;
        end
        endcase
    end

    always_comb begin
        case (state)
        S0 : nextstate = S1;
        S1 : begin
            case (opcode)
            7'b0000011 : nextstate = S2;
            7'b0100011 : nextstate = S5;
            7'b0110011 : nextstate = S7;
            7'b0010011 : nextstate = S9;
            7'b1100011 : nextstate = S11;
            7'b0110111 : nextstate = S10;
            7'b0010111 : nextstate = S12;
            7'b1101111 : nextstate = S13;
            7'b1100111 : nextstate = S14;
            default : nextstate = S0;
            endcase
        end
        S2 : nextstate = S3;
        S3 : nextstate = S4;
        S4 : nextstate = S0;
        S5 : nextstate = S6;
        S6 : nextstate = S0;
        S7 : nextstate = S8;
        S8 : nextstate = S0;
        S9 : nextstate = S16;
        S10 : nextstate = S0;
        S11 : nextstate = S0;
        S12 : nextstate = S0;
        S13 : nextstate = S0;
        S14 : nextstate = S0;
        S16 : nextstate = S0;
        endcase
    end
endmodule

module alu_decoder(
    input logic [2:0] funct3,
    input logic [1:0] aluop,
    input logic [6:0] funct7,
    input logic [6:0] opcode,
    output logic [3:0] alucontrol
);
    always_comb begin
        case (aluop)
        2'b00 : alucontrol = 4'b0000;
        2'b01 : alucontrol = 4'b0001;
        2'b10 : begin
            case (funct3)
            3'b000 : begin
                // Only R-type (aluop == 2'b10) checks funct7 for SUB
                if (aluop == 2'b10 && funct7 == 7'h20 && opcode == 7'b0110011) 
                    alucontrol = 4'b0001; // SUB
                else alucontrol = 4'b0000; // ADD / ADDI
            end
            3'd4 : alucontrol = 4'b0100; //xor
            3'd6 : alucontrol = 4'b0011; //or
            3'd7 : alucontrol = 4'b0010; //and
            3'd1 : alucontrol = 4'b0110; //sll
            3'd5 : begin
                if (funct7 == 7'd0) alucontrol = 4'b0111; //srl
                else if (funct7 == 7'h20) alucontrol = 4'b1000;
                else alucontrol = 4'b0111;
            end
            3'd2 : alucontrol = 4'b0101;
            3'd3 : alucontrol = 4'b1001;
            default : alucontrol = 4'd0;
            endcase
        end
        default : alucontrol = 4'd0;
        endcase
    end
endmodule

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