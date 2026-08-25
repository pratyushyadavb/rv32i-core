module data_memory #(
    parameter DATAWIDTH = 32,
    parameter RAMWIDTH  = 8
)
(
    input  logic                 clock, write_enable, read_enable,
    input  logic [2:0]           funct3,
    input  logic [DATAWIDTH-1:0] addr, wd,
    output logic [DATAWIDTH-1:0] rd
);
    logic [DATAWIDTH-1:0] ram [0:(1<<RAMWIDTH)-1] = '{3: 32'hDEAD_BEEF, default: 32'h0};
    wire [RAMWIDTH-1:0] word_idx = addr[RAMWIDTH+1:2];

    always_ff @(posedge clock) begin
        if (write_enable) begin
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
        if (read_enable) begin
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
        end else begin
            rd = 32'b0;
        end
    end

endmodule

module instr_memory #(parameter DATAWIDTH = 32,
                      parameter MEMORYWIDTH = 8)
(
    input logic [DATAWIDTH-1:0] addr,
    output logic [DATAWIDTH-1:0] instr
);
    logic [DATAWIDTH-1:0] ram [0:(1 << MEMORYWIDTH) - 1];

    initial begin
        $readmemh("program.hex", ram);
    end
    
    assign instr = ram[addr[MEMORYWIDTH+1:2]];

endmodule

module alu(
    input logic [31:0] alusrca, alusrcb,
    input [3:0] alucontrol,
    output logic [31:0] aluout,
    output zero
);
    assign zero = (aluout == 0) ? '1 : '0;

    always_comb begin
        case (alucontrol)
        4'd0 : aluout = alusrca + alusrcb;
        4'd1 : aluout = alusrca - alusrcb;
        4'd2 : aluout = alusrca ^ alusrcb;
        4'd3 : aluout = alusrca | alusrcb;
        4'd4 : aluout = alusrca & alusrcb;
        4'd5 : begin
            if ($signed(alusrca) < $signed(alusrcb)) aluout = '1;
            else aluout = '0;
        end
        4'd6 : aluout = alusrca << alusrcb;
        4'd7 : aluout = alusrca >> alusrcb;
        4'd8 : aluout = $signed(alusrca) >>> alusrcb;
        4'd9 : begin
            if (alusrca < alusrcb) aluout = '1;
            else aluout = '0;
        end
        default : aluout = '0;
        endcase
    end
endmodule

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
        if (we3) registers[x3] <= (wd3 == '0) ? '0 : wd3;
    end
endmodule

module datapath #(parameter DATAWIDTH = 32)
(
    input clock, reset,
    input logic regwrite, alusrcb, branch, we, re, regdatadst, bne,
    input logic [1:0] immcontrol,
    input logic [3:0] alucontrol,
    output logic [6:0] opcode,
    output logic [2:0] funct3,
    output logic [6:0] funct7,
    output logic [31:0] rd1_tb, rd2_tb, wd3_tb,
    output logic [4:0] x1_tb, x2_tb, x3_tb,
    output logic [31:0] imm_tb, pc_tb, instr_tb,
    output logic [31:0] rd_mainmem_tb, aluout_tb,
    output logic [31:0] forbeq_tb,
    output logic zero_tb
);
    logic [31:0] pc, pc_new;
    logic [31:0] instr;
    logic [31:0] wd3, rd1, rd2;
    logic [11:0] mainimm;
    logic [31:0] signext;
    logic [31:0] aluinputa, aluinputb;
    logic [31:0] aluout;
    logic zero;
    logic [31:0] wd, rd;
    logic [31:0] forbeq;
    logic [31:0] pcplus4;
    logic pc_branch_normal;

    always_comb begin
        if (immcontrol == 2'b00) mainimm = instr[31:20];
        else if (immcontrol == 2'b01) mainimm = {instr[31:25], instr[11:7]};
        else if (immcontrol == 2'b10) mainimm = {instr[31], instr[7], instr[30:25], instr[11:8]};
    end

    assign zero_tb = zero;
    assign forbeq_tb = forbeq;
    assign aluout_tb = aluout;
    assign rd_mainmem_tb = rd;
    assign instr_tb = instr;
    assign pc_tb = pc;
    assign x1_tb = instr[19:15];
    assign x2_tb = instr[24:20];
    assign x3_tb = instr[11:7];
    assign rd1_tb = rd1;
    assign rd2_tb = rd2;
    assign wd3_tb = wd3;
    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];
    assign signext = {{20{mainimm[11]}}, mainimm[11:0]};
    assign aluinputa = rd1;
    assign aluinputb = (alusrcb) ? signext : rd2;
    assign wd3 = (regdatadst) ? rd : aluout;
    assign wd = rd2;
    assign forbeq = signext + pc;
    assign pcplus4 = pc + 4;
    assign pc_new = (pc_branch_normal) ? forbeq : pcplus4;
    assign pc_branch_normal = branch & (zero ^ bne);
    assign imm_tb = mainimm;

    always_ff @ (posedge clock, posedge reset)
        if (reset) pc <= 0;
        else pc <= pc_new;

    instr_memory main_instrmemory(.addr(pc), .instr(instr));

    regfile main_regfile(.x1(instr[19:15]), .x2(instr[24:20]), .x3(instr[11:7]),
                         .clock(clock), .we3(regwrite), .rd1(rd1), .rd2(rd2), .wd3(wd3));

    alu mainalu(.alusrca(aluinputa), .alusrcb(aluinputb), .alucontrol(alucontrol),
                .aluout(aluout), .zero(zero));

    data_memory main_datamemory(.clock(clock), .write_enable(we), .read_enable(re),
                                .funct3(instr[14:12]), .addr(aluout), .wd(wd), .rd(rd));
    
endmodule


module main_decoder(
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    output logic regwrite, alusrcb, we, re, regdatadst, branch, bne,
    output logic [1:0] immcontrol,
    output logic [1:0] aluop
);
    always_comb begin
        case (opcode)
        7'b0000011 : begin
            regwrite = '1;
            alusrcb = '1;
            we = '0;
            re = '1;
            regdatadst = 1'd1;
            immcontrol = '0;
            branch = '0;
            aluop = 2'b00;
        end
        7'b0100011 : begin
            regwrite = '0;
            alusrcb = '1;
            we = '1;
            re = '0;
            regdatadst = 'x;
            immcontrol = 2'b01;
            branch = '0;
            aluop = '0;
        end
        7'b0110011 : begin
            regwrite = '1;
            alusrcb = '0;
            we = '0;
            re = '0;
            regdatadst = '0;
            immcontrol = 2'b01;
            branch = '0;
            aluop = 2'b10;
        end
        7'b1100011 : begin
            if (funct3 == 0) begin
            regwrite = '0;
            alusrcb = '0;
            we = '0;
            re = '0;
            regdatadst = 'x;
            immcontrol = 2'b10;
            branch = '1;
            aluop = 2'b01;
            bne = '0;
            end

            else if (funct3 == 0) begin
            regwrite = '0;
            alusrcb = '0;
            we = '0;
            re = '0;
            regdatadst = 'x;
            immcontrol = 2'b10;
            branch = '1;
            aluop = 2'b01;
            bne = '1;
            end
            
        end
        7'b0010011 : begin //i-type(arithmetic)
            regwrite = '1;
            alusrcb = '1;
            we = '0;
            re = '0;
            regdatadst = '0;
            immcontrol = '0;
            branch = '0;
            aluop = 2'b10;
        end
        endcase
    end
endmodule

module alu_decoder(
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic [1:0] aluop,
    output logic [3:0] alucontrol
);
    always_comb begin
        casex (aluop)
        2'b00 : alucontrol = 4'b0000; //add_forced
        2'b01 : alucontrol = 4'b0001; //sub_forced
        2'b1x : begin
            casex (funct3)
            3'd0 : begin if (funct7 == '0) alucontrol = 4'b0000; //add
                    else if (funct7 == 7'b0100000) alucontrol = 4'b0001; //sub
                    end
            3'd4 : alucontrol = 4'b0010; //xor
            3'd6 : alucontrol = 4'b0011; //or
            3'd7 : alucontrol = 4'b0100; //and
            3'd2 : alucontrol = 4'b0101; //slt
            3'd3 : alucontrol = 4'd9; //sltu
            3'd1 : alucontrol = 4'd6; //sll
            3'd5 : begin
                if (funct7 == '0) alucontrol = 4'd7;
                else if (funct7 == 7'h20) alucontrol = 4'd8;
            end
            endcase
        end
        endcase
    end
endmodule

module control_unit(
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    output logic [2:0] alucontrol,
    output logic regwrite, alusrcb, we, re, regdatadst, branch, bne,
    output logic [1:0] immcontrol
);
    logic [1:0] aluop;
    main_decoder main_maindecoder(.opcode(opcode), .funct3(funct3), .regwrite(regwrite), .alusrcb(alusrcb),
                                  .we(we), .re(re), .regdatadst(regdatadst), .branch(branch),
                                  .immcontrol(immcontrol), .aluop(aluop), .bne(bne));

    alu_decoder main_aludecoder(.funct7(funct7), .aluop(aluop), .alucontrol(alucontrol), .funct3(funct3));
endmodule

module processor(
    input clock, reset,
    output logic [31:0] rd1, rd2, wd3,
    output logic [4:0] x1, x2, x3,
    output logic [31:0] signed_imm, pc, instr, rd, aluout,
    output logic we, re,
    output logic [3:0] alucontrol,
    output logic [31:0] forbeq,
    output logic zero, branch
);
    logic regwrite, alusrcb, regdatadst, bne;
    logic [1:0] immcontrol;
    logic [2:0] funct3;
    logic [6:0] opcode, funct7;


    datapath main_datapath(.clock(clock), .reset(reset), .regwrite(regwrite), .immcontrol(immcontrol),
                           .alusrcb(alusrcb), .branch(branch), .re(re), .we(we),
                           .regdatadst(regdatadst), .alucontrol(alucontrol), .opcode(opcode),
                           .funct3(funct3), .funct7(funct7), .rd1_tb(rd1), .rd2_tb(rd2), .wd3_tb(wd3),
                           .x1_tb(x1), .x2_tb(x2), .x3_tb(x3), .imm_tb(signed_imm), .pc_tb(pc), .instr_tb(instr),
                           .rd_mainmem_tb(rd), .aluout_tb(aluout), .forbeq_tb(forbeq), .zero_tb(zero),
                           .bne(bne));
    control_unit main_controlunit(.opcode(opcode), .funct3(funct3), .funct7(funct7),
                                  .alucontrol(alucontrol), .regwrite(regwrite),
                                  .alusrcb(alusrcb), .we(we), .re(re), .regdatadst(regdatadst),
                                  .branch(branch), .immcontrol(immcontrol), .bne(bne));
endmodule
