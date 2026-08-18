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