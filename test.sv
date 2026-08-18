module test(
    input logic [3:0] a,
    output logic [3:0] y
);
    logic [3:0] ram [0:15];

    assign ram[0] = 4'b0101;
    assign ram[1] = 4'b1100;
  	assign ram[6] = 4'b0111;

    assign y = ram[a];
endmodule

module test_tb;
    logic [3:0] a;
  	logic [3:0] y;

    test dut(.a(a), .y(y));

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, test_tb);
    end

    initial begin
        a = '0;
        #10;
        a = 4'd6;
        #10;
        a = 4'd1;
        #10;
    end
endmodule