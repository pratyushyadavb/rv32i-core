typedef enum logic [4:0] {
    S0, S1, S2, S3, S4, S5, S6, S7, 
    S8, S9, S10, S11, S12, S13, S14, S15, S16
} state_t;

module main_fsm(
    input logic clock, reset, branch,
    input logic [6:0] opcode,
    output logic we, re, iord, pcwrite, funct3ctrl, instrEnable, we3, oldpcenable, alump, pc_read,
    output logic [1:0] srca, srcb, wd3ctrl,
    output logic [1:0] aluop,
    output logic [2:0] immctrl,
    output state_t state, nextstate
);

    always_ff @ (posedge clock, posedge reset) begin
        if (reset) state <= S0;
        else state <= nextstate;
    end

    always_comb begin
        we = '0; re = '0; iord = '0; pcwrite = '0; funct3ctrl = '0;
        instrEnable = '0; we3 = '0; oldpcenable = '0; alump = '0;
        srca = '0; srcb = '0; wd3ctrl = '0;
        aluop = '0; immctrl = '0; pc_read = '0;
        case (state)
        S0 : begin
            oldpcenable = '1;
            alump = '0;
            srcb = 2'b01;
            aluop = 2'b00;
            srca = 2'b00;
            instrEnable = '1;
            pc_read = '1;
            pcwrite = '1;
        end
        S1 : begin
            srca = 2'b01;
            srcb = 2'b11;
            immctrl = 3'b010;
            aluop = '0;
        end
        S2 : begin
            srca = 2'b01;
            srcb = 2'b11;
            immctrl = 3'b000;
            aluop = '0;
        end
        S3 : begin
            iord = '1;
            alump = '1;
            re = '1;
        end
        S4 : begin
            wd3ctrl = 3'b000;
            we3 = '1;
        end
        S5 : begin
            srca = 2'b10;
            srcb = 2'b11;
            immctrl = 3'b001;
            aluop = 2'b00;
        end
        S6 : begin
            // alump = '1;
            iord = '1;
            we = '1;
        end
        S7 : begin
            srca = 2'b10;
            srcb = '0;
            aluop = 2'b10;
        end
        S8 : begin
            alump = '1;
            wd3ctrl = 3'b001;
            we3 = '1;
        end
        S9 : begin
            srca = 2'b10;
            srcb = 2'b11;
            aluop = 2'b10;
            immctrl = 3'b000;
        end
        S16 : begin
            alump = '1;
            wd3ctrl = 2'b01;
            we3 = '1;
        end
        S10 : begin
            immctrl = 3'b011;
            wd3ctrl = 2'b11;
            we3 = '1;
        end
        S11 : begin
            srca = 2'b10;
            srcb = 2'b00;
            aluop = 2'b01;
            alump = '1;
            pcwrite = branch;
        end
        S12 : begin
            immctrl = 3'b011;
            aluop = '0;
            srca = 2'b01;
            srcb = 2'b11;
            alump = '0;
            wd3ctrl = 2'b01;
            we3 = '1;
        end
        S13 : begin
            wd3ctrl = 2'b10;
            we3 = '1;
            srca = 2'b01;
            srcb = 2'b11;
            immctrl = 3'b100;
            alump = '0;
            pcwrite = '1;
        end
        S14 : begin
            srca = 2'b10;
            srcb = 2'b11;
            immctrl = 3'd0;
            aluop = '0;
            alump = '0;
            we3 = '1;
            wd3ctrl = 2'b10;
            pcwrite = '1;
        end
        endcase
    end

    always_comb begin
        case (state)
        S0 : nextstate = S1;
        S1 : begin
            case (opcode)
            7'b0000011 : nextstate = S2;
            7'b0100011 : nextstate = S5;
            7'b0110011 : nextstate = S7;
            7'b0010011 : nextstate = S9;
            7'b1100011 : nextstate = S11;
            7'b0110111 : nextstate = S10;
            7'b0010111 : nextstate = S12;
            7'b1101111 : nextstate = S13;
            7'b1100111 : nextstate = S14;
            default : nextstate = S0;
            endcase
        end
        S2 : nextstate = S3;
        S3 : nextstate = S4;
        S4 : nextstate = S0;
        S5 : nextstate = S6;
        S6 : nextstate = S0;
        S7 : nextstate = S8;
        S8 : nextstate = S0;
        S9 : nextstate = S16;
        S10 : nextstate = S0;
        S11 : nextstate = S0;
        S12 : nextstate = S0;
        S13 : nextstate = S0;
        S14 : nextstate = S0;
        S16 : nextstate = S0;
        endcase
    end
endmodule