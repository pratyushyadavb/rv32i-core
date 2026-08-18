#include <stdio.h>
//lw = 0
int main() {
    int instruction_code = 0;
    int opcode[7];
    for(int i = 0; i < 7; i++) {
        opcode[i] = 0;
    }
    if(instruction_code == 0) {
        opcode[6] = opcode[7] = 1;
    }
    for(int i = 0; i < 7; i++) {
        printf("%d", opcode[i]);
    }
    return 0;
}