module test(
    // input logic clock, reset,
    input logic [3:0] a,
    output logic [3:0] b,
    output logic [3:0] y,
    output logic carryin
);
    
    assign carryin = 1'b1;
    assign {carryin, y} = a - b;
endmodule

module test_tb;
    logic [3:0] a;
  	logic [3:0] y;
    logic [3:0] b;
    logic carryin;
    // logic clock, reset;

    test dut(.a(a), .y(y), .b(b), .carryin(carryin));

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, test_tb);
    end

    always #5 clock = ~clock;

    initial begin
        a = '0;
        b = '0;
        #5;
        a = 4'b0110;
        b = 4'b1001;
        #10;
        a = 4'b1001;
        b = 4'b0110;
        #10;
        $finish;
    end
endmodule