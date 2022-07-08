//jump directly to instructions
JMP PTR[LOOP]

//memory location of counter value and initial address for number writing
COUNTER = 0 
COUNTER_SUM = 0
UPPER_LIMIT = 0A
NUMBERS_ADDR = 35

//increment routine
#INCREMENT# 
//load in H counter address
MVI B,PTR[COUNTER] 
MOV H,B 
MOV B,M[H]
MOV A,B

//increase counter by 1, put it in B (and A)
MVI B, 01 
ADD B 
MOV B,A 
MOV C,A

//write counter to its memory position
MOV M[H],B  


/*************************************/
//Naturals summing section

//load in H cumulator address
MVI B,PTR[COUNTER_SUM] 
MOV H,B 
MOV B,M[H]

//sum current natural (counter) to previous ones (cumulator)
ADD B 
MOV B, A 

//write cumulator to its memory position
MOV M[H], B



//reload counter
MOV B,C
MOV A,B

/*************************************/

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

////////////////////////////

//puts sum_counter value in C
MVI B,PTR[COUNTER_SUM]
MOV H,B
MOV B, M[H]
MOV C,B

////////////////////////////7

//puts counter value in B, A 
MVI B,PTR[COUNTER]
MOV H,B
MOV B, M[H]
MOV A,B

//load initial address for writing
MVI B,PTR[NUMBERS_ADDR]
MOV H,B
MOV B,M[H]

//calculates address to write counter value, put in H
ADD B
MOV B,A
MOV H,B

//re-load sum value in B and A from C and write it to memory
MOV B,C
MOV M[H],B

//jump to increment routine
JMP [INCREMENT]

#AFTER_LOOP# 
HLT

#NUMBERS_ADDR#
