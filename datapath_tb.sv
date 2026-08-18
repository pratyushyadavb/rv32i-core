module datapath_tb;
    logic clock, reset;
    logic [31:0] rd1, rd2, wd3;

    processor dut(
        .clock(clock), .reset(reset), .rd1(rd1), .rd2(rd2), .wd3(wd3)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, datapath_tb);
    end

    always #10 clock = ~clock;

    initial begin
        #40;
        $monitor("rd1: %d; rd2: %d; wd3: %d", rd1, rd2, wd3);
        $finish;
    end
endmodule