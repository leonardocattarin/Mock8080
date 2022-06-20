//jump directly to instructions
JMP PTR[INSTRUCTIONS]

//memory location of counter value and initial address for number writing
COUNTER = 0
NUMBERS_ADDR

#PRE_LOOP#
MVI B,PTR[COUNTER]
MOV H,B
MOV B, M[H]
MOV A, B
MVI 01
ADD B
MOV B,A
MOV M[H],B
MVI UPPER_LIMIT
CMP B
CHZ
JC PTR[AFTER_LOOP]

#INSTRUCTIONS#
//puts counter value in A
MVI B,PTR[COUNTER]
MOV H,B
MOV B, M[H]
MOV A,B

//calculates address to write counter value, put in H
MVI B,PTR[NUMBERS_ADDR]
ADD B
MOV B,A
MOV H,B

//re-load counter value in B and write it to memory
MOV B,A
MOV M[H],B
...
JMP [PRE_LOOP]

#AFTER_LOOP#
HLT

#NUMBERS_ADDR#
