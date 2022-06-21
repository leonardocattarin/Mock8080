//jump directly to instructions
JMP PTR[LOOP]

//memory location of counter value and initial address for number writing
COUNTER = 0 
UPPER_LIMIT = 0A
NUMBERS_ADDR = 35

//increment routine
#INCREMENT# 
//load in H counter address
MVI B,PTR[COUNTER] 
MOV H,B 

//increase counter by 1, put it in B (and A)
MVI B, 01 
ADD B 
MOV B,A 

//write counter to its memory position
MOV M[H],B  

//load upper limit in B
MVI B,PTR[UPPER_LIMIT] 
MOV H,B 
MOV B,M[H] 

//compare A (counter) with B(upper limit)
CMP B 
//check if zero flag is 1 (A=B) and jump to end program if true
CHZ 
JC PTR[AFTER_LOOP]

#LOOP#
//puts counter value in B, A and C
MVI B,PTR[COUNTER]
MOV H,B
MOV B, M[H]
MOV A,B
MOV C,B

//load initial address for writing
MVI B,PTR[NUMBERS_ADDR]
MOV H,B
MOV B,M[H]

//calculates address to write counter value, put in H
ADD B
MOV B,A
MOV H,B

//re-load counter value in B and A from C and write it to memory
MOV B,C
MOV A,B
}MOV M[H],B

//jump to increment routine
JMP [INCREMENT]

#AFTER_LOOP# 
HLT

#NUMBERS_ADDR#
