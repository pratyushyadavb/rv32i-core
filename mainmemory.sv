module data_memory # (parameter DATAWIDTH = 32,
                      parameter RAMWIDTH = 6)
(
    input logic clock, write_enable, read_enable,
    input logic [2:0] funct3,
    input logic [DATAWIDTH-1:0] addr, wd,
    output logic [DATAWIDTH-1:0] rd
);
    logic [DATAWIDTH-1:0] ram [0:(1<<RAMWIDTH)-1];

    wire [RAMWIDTH-2:0] ram_idx = 
    always_ff @ (posedge clock) begin
        if (write_enable) begin
            case (funct3)
            3'b000 :case(addr[1:0])
                    2'b00 : ram[addr[RAMWIDTH-1:2]][7:0] <= wd[7:0];
                    2'b01 : ram[addr[RAMWIDTH-1:2]][15:8] <= wd[7:0];
                    2'b10 : ram[addr[RAMWIDTH-1:2]][23:16] <= wd[7:0];
                    2'b11 : ram[addr[RAMWIDTH-1:2]][31:24] <= wd[7:0];
                    endcase
            3'b001 : if (addr[1:0] == 2'b00) ram[addr[RAMWIDTH-1:2]][15:0] <= wd[15:0];
                    else if (addr[1:0] == 2'b10) ram[addr[RAMWIDTH-1:2]][31:16] <= wd[15:0];
            3'b010 : ram[addr[RAMWIDTH-1:2]] <= wd;
            default : ram[addr[RAMWIDTH-1:2]] <= wd;
            endcase
        end
    end
    always_comb begin
        if (read_enable) begin
            case (funct3)
            3'b000 :case(addr[1:0])
                    2'b00 : rd = {{24{ram[addr[RAMWIDTH-1:2][7]]}}, {ram[addr[RAMWIDTH-1:2]][7:0]}};
                    2'b01 : rd = {{24{ram[addr[RAMWIDTH-1:2][15]]}}, {ram[addr[RAMWIDTH-1:2]][15:8]}};
                    2'b10 : rd = {{24{ram[addr[RAMWIDTH-1:2][23]]}}, {ram[addr[RAMWIDTH-1:2]][23:16]}};
                    2'b11 : rd = {{24{ram[addr[RAMWIDTH-1:2][31]]}}, {ram[addr[RAMWIDTH-1:2]][31:24]}};
                    endcase
            3'b001 :if (addr[1:0] == 2'b00) rd = {{16{ram[addr[RAMWIDTH-1:2]][15]}}, {ram[addr[RAMWIDTH-1:2]][15:0]}};
                    else if (addr[1:0] == 2'b10) rd = {{16{ram[addr[RAMWIDTH-1:2]][31]}}, {ram[addr[RAMWIDTH-1:2]][31:16]}};
            3'b010 : rd = ram[addr[RAMWIDTH-1:2]];
            3'b100 :case(addr[1:0])
                    2'b00 : rd = {{24{0}}, {ram[addr[RAMWIDTH-1:2]][7:0]}};
                    2'b01 : rd = {{24{0}}, {ram[addr[RAMWIDTH-1:2]][15:8]}};
                    2'b10 : rd = {{24{0}}, {ram[addr[RAMWIDTH-1:2]][23:16]}};
                    2'b11 : rd = {{24{0}}, {ram[addr[RAMWIDTH-1:2]][31:24]}};
                    endcase
            3'b101 :if (addr[1:0] = 2'b00) rd = {{16{0}}, {ram[addr[RAMWIDTH-1:2]][15:0]}};
                    else if (addr[1:0] = 2'b10) 2'b10 : rd = {{16{0}}, {ram[addr[RAMWIDTH-1:2]][31:16]}};
            default : rd = ram[addr[RAMWIDTH-1:2]];
            endcase
        end
        else begin rd = 32'b0;
        end
    end
endmodule

module mainmemory_tb;
    logic clock, write_enable, read_enable;
    logic [2:0] funct3;
    logic [31:0] addr, wd, rd;

    always @ ()
endmodule


module data_memory #(
    parameter DATAWIDTH = 32,
    parameter RAMWIDTH  = 8
)(
    input  logic                 clock, write_enable, read_enable,
    input  logic [2:0]           funct3,
    input  logic [DATAWIDTH-1:0] addr, wd,
    output logic [DATAWIDTH-1:0] rd
);

    logic [DATAWIDTH-1:0] ram [0:(1<<RAMWIDTH)-1];

    // Array indexing range calculation
    wire [RAMWIDTH-1:0] word_idx = addr[RAMWIDTH+1:2];

    // 1. SYNCHRONOUS WRITE PATH (Non-blocking <= assignments)
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

    // 2. COMBINATIONAL READ PATH (Blocking = assignments)
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

module instr_memory #(parameter DATAWIDTH = 32;
                      parameter MEMORYWIDTH = 8) //256 WORDS
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