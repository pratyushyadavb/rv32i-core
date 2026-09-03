module test1(
    input logic [3:0] a,
    input logic enable, reset, clock,
    output logic [3:0] y
);
    always_ff @ (posedge clock, posedge reset) begin
        if (reset) y <= 0;
        else if (enable) y <= a;
    end
endmodule

module test1_tb;
    logic [3:0] a, y;
    logic clock, reset, enable;

    test1 dut (
        .clock(clock),
        .reset(reset),
        .enable(enable),
        .a(a),
        .y(y)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, test1_tb);
    end

    always #5 clock = ~clock;

    initial begin
        a = '0;
        reset = '1;
        clock = '0;
        enable = '0;
        #10;
        reset = '0;
        enable = '1;
        a = 4'd5;
        #10;
        a = 4'd2;
        #10;
        enable = '0;
        a = 4'd7;
        #10;
        a = 4'd10;
        #10
        $finish;
    end
endmodule