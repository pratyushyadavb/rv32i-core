`timescale 1ns/1ps

module tb_data_memory;

    localparam DATAWIDTH = 32;
    localparam RAMWIDTH  = 6;
    localparam CLK_PERIOD = 10;

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

    always #(CLK_PERIOD / 2) clock = ~clock;

    task clear_signals();
        write_enable = 1'b0;
        read_enable  = 1'b0;
        funct3       = 3'b000;
        addr         = 32'b0;
        wd           = 32'b0;
    endtask

    initial begin
        clock = 0;
        clear_signals();
        #(CLK_PERIOD);

        $display("\n==================================================");
        $display("   STARTING RV32I DATA MEMORY TESTBENCH           ");
        $display("==================================================\n");

        // ---------------------------------------------------------------------
        // TEST 1: STORE WORD (SW) & LOAD WORD (LW)
        // ---------------------------------------------------------------------
        $display("[TEST 1] Testing SW and LW...");
        
        // SW: Write 0xDEADBEEF to Word Index 0 (Byte Addr 0x00)
        @(posedge clock);
        write_enable = 1'b1;
        funct3       = 3'b010; // SW
        addr         = 32'h0000_0000;
        wd           = 32'hDEAD_BEEF;

        @(posedge clock);
        clear_signals();
        
        // LW: Read from Byte Addr 0x00 (Combinational Read)
        read_enable  = 1'b1;
        funct3       = 3'b010; // LW
        addr         = 32'h0000_0000;
        #1; // Wait for combinational propagation
        
        assert(rd === 32'hDEAD_BEEF) 
            else $error("[FAILED] LW: Expected 0xDEADBEEF, got 0x%h", rd);
        $display("  -> LW Read Result: 0x%h [PASS]", rd);


        // ---------------------------------------------------------------------
        // TEST 2: STORE BYTE (SB) across all 4 byte offsets
        // ---------------------------------------------------------------------
        $display("\n[TEST 2] Testing SB (Store Byte) at offsets 0, 1, 2, 3...");
        
        // Write byte 0x11 at Offset 0 (Addr 0x04)
        @(posedge clock);
        write_enable = 1'b1; funct3 = 3'b000; addr = 32'h0000_0004; wd = 32'h0000_0011;
        // Write byte 0x22 at Offset 1 (Addr 0x05)
        @(posedge clock);
        addr = 32'h0000_0005; wd = 32'h0000_0022;
        // Write byte 0x33 at Offset 2 (Addr 0x06)
        @(posedge clock);
        addr = 32'h0000_0006; wd = 32'h0000_0033;
        // Write byte 0x84 at Offset 3 (Addr 0x07) - Note: 0x84 has MSB=1 (negative)
        @(posedge clock);
        addr = 32'h0000_0007; wd = 32'h0000_0084;

        @(posedge clock);
        clear_signals();

        // Read entire Word back with LW to confirm byte alignment
        read_enable = 1'b1; funct3 = 3'b010; addr = 32'h0000_0004;
        #1;
        assert(rd === 32'h8433_2211) 
            else $error("[FAILED] SB alignment check: Expected 0x84332211, got 0x%h", rd);
        $display("  -> Combined Word Read (0x04): 0x%h [PASS]", rd);


        // ---------------------------------------------------------------------
        // TEST 3: LOAD BYTE SIGNED (LB) & UNSIGNED (LBU)
        // ---------------------------------------------------------------------
        $display("\n[TEST 3] Testing LB (Sign-Extended) vs LBU (Zero-Extended)...");

        // LB Offset 0: 0x11 (Positive) -> Expected: 0x00000011
        addr = 32'h0000_0004; funct3 = 3'b000; #1; // LB
        assert(rd === 32'h0000_0011) else $error("[FAILED] LB Positive");
        $display("  -> LB  Positive Byte (0x11): 0x%h [PASS]", rd);

        // LB Offset 3: 0x84 (Negative MSB=1) -> Expected: 0xFFFFFF84
        addr = 32'h0000_0007; funct3 = 3'b000; #1; // LB
        assert(rd === 32'hFFFFFF84) else $error("[FAILED] LB Negative Sign Extension");
        $display("  -> LB  Negative Byte (0x84): 0x%h [PASS]", rd);

        // LBU Offset 3: 0x84 (Negative Byte, Unsigned) -> Expected: 0x00000084
        addr = 32'h0000_0007; funct3 = 3'b100; #1; // LBU
        assert(rd === 32'h0000_0084) else $error("[FAILED] LBU Zero Extension");
        $display("  -> LBU Negative Byte (0x84): 0x%h [PASS]", rd);


        // ---------------------------------------------------------------------
        // TEST 4: STORE HALFWORD (SH), LOAD HALFWORD (LH / LHU)
        // ---------------------------------------------------------------------
        $display("\n[TEST 4] Testing SH, LH, and LHU...");

        // SH Lower Halfword (Addr 0x08): 0x9234 (MSB=1)
        @(posedge clock);
        write_enable = 1'b1; funct3 = 3'b001; addr = 32'h0000_0008; wd = 32'h0000_9234;
        
        // SH Upper Halfword (Addr 0x0A): 0x1234 (MSB=0)
        @(posedge clock);
        addr = 32'h0000_000A; wd = 32'h0000_1234;

        @(posedge clock);
        clear_signals();

        // LH Lower Halfword (Signed Extension check) -> Expected: 0xFFFF9234
        read_enable = 1'b1; funct3 = 3'b001; addr = 32'h0000_0008; #1; // LH
        assert(rd === 32'hFFFF_9234) else $error("[FAILED] LH Negative Sign Extension");
        $display("  -> LH  Lower Halfword (0x9234): 0x%h [PASS]", rd);

        // LHU Lower Halfword (Zero Extension check) -> Expected: 0x00009234
        funct3 = 3'b101; #1; // LHU
        assert(rd === 32'h0000_9234) else $error("[FAILED] LHU Zero Extension");
        $display("  -> LHU Lower Halfword (0x9234): 0x%h [PASS]", rd);

        // LH Upper Halfword -> Expected: 0x00001234
        funct3 = 3'b001; addr = 32'h0000_000A; #1; // LH
        assert(rd === 32'h0000_1234) else $error("[FAILED] LH Upper Halfword");
        $display("  -> LH  Upper Halfword (0x1234): 0x%h [PASS]", rd);


        // ---------------------------------------------------------------------
        // TEST 5: READ ENABLE DISABLE CHECK
        // ---------------------------------------------------------------------
        $display("\n[TEST 5] Testing read_enable = 0...");
        read_enable = 1'b0; #1;
        assert(rd === 32'b0) else $error("[FAILED] Output should be 0 when read_enable=0");
        $display("  -> rd is 0x00000000 when read_enable=0 [PASS]");

        $display("\n==================================================");
        $display("   ALL RV32I MEMORY TESTS PASSED SUCCESSFULLY!    ");
        $display("==================================================\n");
        $finish;
    end

endmodule