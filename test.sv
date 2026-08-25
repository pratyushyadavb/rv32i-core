module test(
    input logic [3:0] a,
    input logic [3:0] b,
    output logic [3:0] y
);
    always_comb begin
        if ($signed(a) < $signed(b)) y = '1;
        else y = '0;
    end
endmodule

module test_tb;
    logic [3:0] a;
    logic [3:0] b;
  	logic [3:0] y;

    test dut(.a(a), .y(y), .b(b));

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, test_tb);
    end

    initial begin
        a = '0;
        b = '0;
        #10;
        a = 4'd6;
        b = 4'd10;
        #10;

        $finish;
    end
endmodule