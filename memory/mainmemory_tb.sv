module mainmemory_tb;
    localparam DATAWIDTH = 32;
    localparam RAMWIDTH  = 6;

    logic                 clock;
    logic                 write_enable;
    logic                 read_enable;
    logic [2:0]           funct3;
    logic [DATAWIDTH-1:0] addr;
    logic [DATAWIDTH-1:0] wd;
    logic [DATAWIDTH-1:0] rd;

    data_memory #(
        .DATAWIDTH(DATAWIDTH),
        .RAMWIDTH(RAMWIDTH)
    ) dut (
        .clock(clock),
        .write_enable(write_enable),
        .read_enable(read_enable),
        .funct3(funct3),
        .addr(addr),
        .wd(wd),
        .rd(rd)
    );

    always #5 clock = ~clock;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, mainmemory_tb);
    end

    initial begin
        clock = 0;
        write_enable = 0;
        read_enable = 0;
        funct3 = '0;
        addr = '0;
        wd = '0;
        rd = '0;
        #10;


        read_enable = 1'd1;
        addr = 32'd12;
        funct3 = 3'd2;
        #20;
        $finish;
    end
endmodule