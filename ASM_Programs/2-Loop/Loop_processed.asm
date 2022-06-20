//jump directly to instructions
{00 01}JMP PTR[LOOP] (2) [C3 16]

//memory location of counter value and initial address for number writing
{02}COUNTER = 0 (1) [00]
{03}UPPER_LIMIT (1) [0A]
{04}NUMBERS_ADDR (1) [27]

//increment routine
#INCREMENT# {05}
//load in H counter address
{05 06}MVI B,PTR[COUNTER] (2) [06 02]
{07}MOV H,B (1) [60]

//increase counter by 1
{08 09} MVI B, 01 (2) [06 01]
{0A} ADD B (1) [80]
{0B} MOV B,A (1) [47]

//write counter to its memory position
{0C}MOV M[H],B (1) [70]

//load upper limit in B
{0D 0E}MVI B,PTR[UPPER_LIMIT] (2) [06 03]
{0F}MOV H,B (1) [60]
{10}MOV B,M[H] (1) [46]

//compare A (counter) with B(upper limit)
{11}CMP B (1) [B8]
//check if zero flag is 1 (A=B) and jump to end program if true
{12}CHZ (1) [CC]
{13 14}JC PTR[AFTER_LOOP] (2) [DA 24]

#LOOP# {15}
//puts counter value in A
{15 16}MVI B,PTR[COUNTER] (2) [06 02]
{17}MOV H,B (1) [60]
{18}MOV B, M[H] (1) [46]
{19}MOV A,B (1) [78]

//calculates address to write counter value, put in H
{1A 1B}MVI B,PTR[NUMBERS_ADDR] (2) [06 04]
{1C}ADD B (1) [80]
{1D}MOV B,A (1) [47]
{1E}MOV H,B (1) [60]

//re-load counter value in B and write it to memory
{1F}MOV B,A (1) [47]
{20}MOV M[H],B (1) [70]

//jump to increment routine
{21 22}JMP [INCREMENT] (2) [C3 05]

#AFTER_LOOP# {23}
{23}HLT (1) [76]

#NUMBERS_ADDR#{27}
