JMP PTR[INSTRUCTIONS]

COUNTER = 0
NUMBERS_ADDR

#PRE_LOOP#
MVI PTR[COUNTER]
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
MVI PTR[COUNTER]
MOV H,B
MOV B, M[H]
MOV A,B

MVI PTR[NUMBERS_ADDR]
ADD B
MOV B,A
MOV H,B

MOV B,C
MOV M[H],B
...
JMP [PRE_LOOP]

#AFTER_LOOP#
HLT

#NUMBERS_ADDR#