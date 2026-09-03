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
    output zero, lessthan, lessthanu
);
    assign zero = (aluout == 0) ? '1 : '0;
    assign lessthan = ($signed(alusrca) < $signed(alusrcb)) ? '1 : '0;
    assign lessthanu = (alusrca < alusrcb) ? '1 : '0;

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
    input logic regwrite, branch, we, re, regdatadst, bne,
    input logic [1:0] pc_select,
    input logic [2:0] immcontrol,
    input logic [3:0] alucontrol,
    input logic [1:0] wd3control, //here
    output logic [6:0] opcode,
    output logic [2:0] funct3,
    input logic [1:0] alusrcb,
    output logic [6:0] funct7,
    output logic [31:0] rd1_tb, rd2_tb, wd3_tb,
    output logic [4:0] x1_tb, x2_tb, x3_tb,
    output logic [31:0] imm_tb, pc_tb, instr_tb,
    output logic [31:0] rd_mainmem_tb, aluout_tb,
    output logic [31:0] forbeq_tb,
    output logic zero_tb,
    output logic zero, lessthan, lessthanu
);
    logic [31:0] pc, pc_new;
    logic [31:0] instr;
    logic [31:0] wd3, rd1, rd2;
    logic [31:0] mainimm;
    logic [31:0] signext;
    logic [31:0] aluinputa, aluinputb;
    logic [31:0] aluout;
    logic [31:0] wd, rd;
    logic [31:0] forbeq;
    logic [31:0] pcplus4;
    logic [31:0] wd3_fromdatamem_alu;
    logic [31:0] lui_imm;

    
    assign wd3_fromdatamem_alu = (regdatadst) ? rd : aluout;
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
    assign aluinputa = rd1;
    assign aluinputb = (alusrcb) ? mainimm : rd2;
    assign lui_imm = mainimm << 12;
    assign imm_tb = mainimm;
    assign wd = rd2;
    assign forbeq = mainimm + pc; 
    assign pcplus4 = pc + 4;



    always_comb begin
        if (immcontrol == 3'b000) mainimm = {{20{instr[31]}}, instr[31:20]}; //lw imm
        else if (immcontrol == 3'b001) mainimm = {{20{instr[31]}}, instr[31:25], instr[11:7]}; //sw imm
        else if (immcontrol == 3'b010) mainimm = {{20{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8]};
        else if (immcontrol == 3'b011) mainimm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
        else if (immcontrol == 3'b100) mainimm = {{12{instr[31]}}, instr[31:12]};
    end
    always_comb begin
        if (pc_select == '0) pc_new = pcplus4;
        else if (pc_select == 2'd1) pc_new = forbeq;
        else if (pc_select == 2'd2) pc_new = aluout;
    end
    
    always_comb begin
        if (wd3control == 2'd0) wd3 = wd3_fromdatamem_alu;
        else if (wd3control == 2'd1) wd3 = pcplus4;
        else if (wd3control == 2'd2) wd3 = lui_imm;
        else if (wd3control == 2'd3) wd3 = pc + lui_imm;
    end
    always_ff @ (posedge clock, posedge reset) begin
        if (reset) pc <= 0;
        else pc <= pc_new;
    end



    instr_memory main_instrmemory(.addr(pc), .instr(instr));

    regfile main_regfile(.x1(instr[19:15]), .x2(instr[24:20]), .x3(instr[11:7]),
                         .clock(clock), .we3(regwrite), .rd1(rd1), .rd2(rd2), .wd3(wd3));

    alu mainalu(.alusrca(aluinputa), .alusrcb(aluinputb), .alucontrol(alucontrol),
                .aluout(aluout), .zero(zero), .lessthan(lessthan), .lessthanu(lessthanu));

    data_memory main_datamemory(.clock(clock), .write_enable(we), .read_enable(re),
                                .funct3(instr[14:12]), .addr(aluout), .wd(wd), .rd(rd));
    
endmodule


module main_decoder(
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    input logic zero, lessthan, lessthanu,
    output logic regwrite, we, re, regdatadst, branch, bne,
    output logic [1:0] alusrcb,
    output logic [2:0] immcontrol,
    output logic [1:0] aluop, pc_select,
    output logic [1:0] wd3control
);
    always_comb begin
        pc_select = '0;
        wd3control = '0;
        case (opcode)
        7'b0000011 : begin
            regwrite = '1;
            alusrcb = 2'd1;
            we = '0;
            re = '1;
            regdatadst = 1'd1;
            immcontrol = '0;
            branch = '0;
            aluop = 2'b00;
        end
        7'b0100011 : begin
            regwrite = '0;
            alusrcb = 2'd1;
            we = '1;
            re = '0;
            regdatadst = 'x;
            immcontrol = 3'b001;
            branch = '0;
            aluop = '0;
        end
        7'b0110011 : begin
            regwrite = '1;
            alusrcb = 2'd0;
            we = '0;
            re = '0;
            regdatadst = '0;
            immcontrol = 3'b001;
            branch = '0;
            aluop = 2'b10;
        end
        7'b1100011 : begin
            regwrite = '0;
            alusrcb = 2'd0;
            we = '0;
            re = '0;
            immcontrol = 3'b010;
            aluop = 2'b01;
            case (funct3)
            3'd0 : pc_select = (zero) ? 2'b1 : '0; //beq
            3'd1 : pc_select = (zero) ? '0 : 2'd1; //bne
            3'd4 : pc_select = (lessthan) ? 2'd1 : '0; //blt
            3'd5 : pc_select = (~lessthan) ? 2'd1 : '0; //bge
            3'd6 : pc_select = (lessthanu) ? 2'd1 : '0; //bltu
            3'd7 : pc_select = (~lessthanu) ? 2'd1 : '0; //bgeu
            endcase
        end
        7'b0010011 : begin //i-type(arithmetic)
            regwrite = '1;
            alusrcb = 2'd1;
            we = '0;
            re = '0;
            regdatadst = '0;
            immcontrol = '0;
            branch = '0;
            aluop = 2'b10;
        end
        7'b1101111 : begin //jal operation
            wd3control = 2'd1;
            regwrite = '1;
            pc_select = 2'd1;
            we = '0;
            re = '0;
            immcontrol = 3'b011;
        end
        7'b1100111 : begin
            wd3control = 2'd1; //to set rd = pcplus4
            regwrite = '1;
            pc_select = 2'd2;
            we = '0;
            re = '0;
            aluop = 2'd0; //to force add immediate and pc
            immcontrol = 3'd0;
        end
        7'b0110111: begin //lui
            wd3control = 2'd2;
            regwrite = '1;
            we = '0;
            re = '0;
            immcontrol = 3'd4;
        end
        7'b0010111 : begin //auipc
            wd3control = 2'd3;
            regwrite = '1;
            we = '0;
            re = '0;
            immcontrol = 3'd4;
        end
        7'b1110011 : begin //ecall and ebreak
            we = '0;
            re = '0;
            regwrite = '0;
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
    input logic zero, lessthan, lessthanu,
    output logic [3:0] alucontrol,
    output logic regwrite, we, re, regdatadst, branch, bne,
    output logic [1:0] alusrcb, pc_select, wd3control,
    output logic [2:0] immcontrol
);
    logic [1:0] aluop;
    main_decoder main_maindecoder(.opcode(opcode), .funct3(funct3), .regwrite(regwrite), .alusrcb(alusrcb),
                                  .we(we), .re(re), .regdatadst(regdatadst), .branch(branch),
                                  .immcontrol(immcontrol), .aluop(aluop), .bne(bne),
                                  .zero(zero), .lessthan(lessthan), .pc_select(pc_select),
                                  .lessthanu(lessthanu), .wd3control(wd3control));

    alu_decoder main_aludecoder(.funct7(funct7), .aluop(aluop), .alucontrol(alucontrol), .funct3(funct3));
endmodule

module processor(
    input clock, reset,
    output logic [31:0] rd1, rd2, wd3,
    output logic [4:0] x1, x2, x3,
    output logic [31:0] signed_imm, pc, instr, rd, aluout, //here
    output logic we, re,
    output logic [3:0] alucontrol,
    output logic [31:0] forbeq,
    output logic zero_tb, branch
);
    logic regwrite, regdatadst, bne, lessthan, lessthanu, zero;
    logic [1:0] alusrcb, pc_select, wd3control;
    logic [2:0] funct3, immcontrol;
    logic [6:0] opcode, funct7;


    datapath main_datapath(.clock(clock), .reset(reset), .regwrite(regwrite), .immcontrol(immcontrol),
                           .alusrcb(alusrcb), .branch(branch), .re(re), .we(we),
                           .regdatadst(regdatadst), .alucontrol(alucontrol), .opcode(opcode),
                           .funct3(funct3), .funct7(funct7), .rd1_tb(rd1), .rd2_tb(rd2), .wd3_tb(wd3),
                           .x1_tb(x1), .x2_tb(x2), .x3_tb(x3), .imm_tb(signed_imm), .pc_tb(pc), .instr_tb(instr),
                           .rd_mainmem_tb(rd), .aluout_tb(aluout), .forbeq_tb(forbeq), .zero_tb(zero_tb),
                           .bne(bne), .zero(zero), .lessthan(lessthan), .pc_select(pc_select), .lessthanu(lessthanu),
                           .wd3control(wd3control));



    control_unit main_controlunit(.opcode(opcode), .funct3(funct3), .funct7(funct7),
                                  .alucontrol(alucontrol), .regwrite(regwrite),
                                  .alusrcb(alusrcb), .we(we), .re(re), .regdatadst(regdatadst),
                                  .branch(branch), .immcontrol(immcontrol), .bne(bne), .zero(zero),
                                  .lessthan(lessthan), .pc_select(pc_select), .lessthanu(lessthanu),
                                  .wd3control(wd3control));
endmodule
