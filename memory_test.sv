module memory(
    input logic [31:0] addr,
    input logic pc_read,
    input logic [31:0] wd,
    input logic [2:0] funct3,
    input logic clock, we, re,
    output logic [31:0] rd,
    output logic [7:0] word_idx
);
    logic [31:0] ram [0:255] = '{3: 32'hDEAD_BEEF, default: 32'h0};
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
        if (pc_read) rd = ram[word_idx]; //for pc
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
        end else begin
            rd = 32'b0;
        end
    end
endmodule

module memory_test;
    logic [31:0] addr, wd, rd;
    logic pc_read, clock, we, re;
    logic [2:0] funct3;

    memory dut(.addr(addr), .wd(wd), .rd(rd), .pc_read(pc_read), .clock(clock), .we(we), .re(re),
               .funct3(funct3));

    always #5 clock = ~clock;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, memory_test);

        clock = 0;
        addr = 31'd12;
        pc_read = '1;

        #20;

        $finish;
    end
endmodule