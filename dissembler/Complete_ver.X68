*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
START_ADDRESS       EQU $300 ; start address
END_ADDRESS         EQU $308 ; end address
INPUT_VALUE         EQU $316 ; user input value
CR                  EQU $0D ; Carrige return
LF                  EQU $0A ; Linefeed
nibble2             EQU $0F00
nibble3             EQU $00F0
nibble4             EQU $000F
dstmode             EQU $10CA
dstmode_Bi          EQU %0000000111000000   
srcmode             EQU $0038
srcmode_Bi          EQU %0000000000111000   
dstmode_low2        EQU %0000000011000000 ; dest mode lower 2bits
srcmode_low2        EQU %0000000000011000 ; source mode lower 2 bits
dstreg              EQU $0E00 ; dest regs
srcreg              EQU $0007 ; src regs

bufsize             EQU 64 ; 64 characters can be stored in buffer
right3              EQU 3
right4              EQU 4
right8              EQU 8
right16             EQU 16
right24             EQU 24
stack               EQU $A0000
SAMPLE_ADDR         EQU  $00000400


    ORG    $1000
    
START:                  ; first instruction of program
    LEA     stack, SP           ;   SP = stack ($A0000)
    
    ;MOVE.L  #$E1798102,(A3) ; load test example instruction If you want to test, change this value
    ;MOVE.W  #$7890, 4(A3)
WELCOME:
    LEA     WELCOME_MSG,A1
    MOVE.B  #13,D0
    TRAP    #15   
 
USER_INPUT:
    CLR.L   START_ADDRESS ; clean start address
    CLR.L   END_ADDRESS ; clean end address
    CLR.L   INPUT_VALUE ; clean user input
    CLR.L   D0 ; clean
    CLR.W   D3 ; clean flag for end address
    ;MOVEA.L #0,A1 ; clear A1
    LEA     INPUT_START,A1 ; load message on A1
    MOVE.B  #14,D0 ; read char at A1 until null
    TRAP    #15 ; excute command code at D0
    BRA     START_ADDR
    
START_ADDR:
    LEA     INPUT_VALUE,A1 ;
    MOVE.B  #2,D0 ; Read string from keyboard and store at (A1), NULL terminated, length retuned in D1.W (max 80)
    TRAP    #15 ; excute trap
    CMPI    #0,D1 ; check if there is char to process D1: length of string
    BEQ     ERROR   ; If user didn't type anything, prompt error and restart the program.
    CMPI    #8,D1 ; if there is more than 8 digits of hex. It is out of bound long address
    BGT     ERROR 
    LEA     START_ADDRESS,A3 ; A3 points to start_address for ATOI process
    BRA     ATOI ; jump to ATOI for converting ASCII to Int
    
END_ADDR:
    LEA     INPUT_END,A1 ; load message on A1
    MOVE.B  #14,D0 ; read char at A1 until null
    TRAP    #15 ; excute command code at D0
    LEA     INPUT_VALUE,A1 ;
    MOVE.B  #2,D0 ; Read string from keyboard and store at (A1), NULL terminated, length retuned in D1.W (max 80)
    TRAP    #15 ; excute trap
    CMPI    #0,D1 ; check if there is char to process D1: length of string
    BEQ     ERROR   ; If user didn't type anything, prompt error and restart the program.
    CMPI    #8,D1 ; if there is more than 8 digits of hex. It is out of bound long address
    BGT     ERROR 
    LEA     END_ADDRESS,A3 ; A3 points to end_address for ATOI process
    MOVE.B  #1,D3 ; True/False for reading end address at D3
    BRA     ATOI ; jump to ATOI for converting ASCII to Int
    
CHECK_ADDRESS:
    CLR     D3 ; clear D3 for next dissamble
    CLR.L   D2 ; clear D2 for next process
    MOVE.L  END_ADDRESS,D0 ; move end address to D0 to compare two addresses
    CMP.L   START_ADDRESS,D0 ; check if start address is smaller than end address
    BLE     ERROR
    MOVEA.L START_ADDRESS,A3    ;  *Loads the address saved in side of the START_ADDRESS @@@@@@@@@@@
                                ;  *Then A3 will be pointing at Starting Address @@@@@@@@@@@@@@@@
                                ;   @@ Needs to upload the address A3, before going into the Decode_Loop

    MOVE.L  A3, D7              ; LOAD THE CURRENT INSTRUCTION BEFORE THE LOOP BEGINS   
    BRA     DECODE_LOOP ; go to decode loop to process 
    
*----------------------------------------------------------------------------   
*   D5 = Loop Counter (Stack May needed) || We can save the counter value in untouchable memory
*   D4 = How many bytes to JUMP
*----------------------------------------------------------------------------   
DECODE_LOOP:
     ADDI.W  #1, D5 ; Loop Counter = 23 TIMES 
        
    LOOP: 
    *------------------------------------------------------------------------    
    ; Decode starts here  OP_DECODE -> EA_CALC  
                       
    JSR     OP_START            ; OP_DECODE -> EA_CALC
        
    CMPA.L  END_ADDRESS, A3     ; if START_ADDRESS >= END_ADDRESS
    BGE     END                 ;   END 
                                ; else -> continue                           
    *------------------------------------------------------------------------
    
    SUBI    #1, D5      ;   D--;
    CMP.B   #0, D5
    BEQ     REPEAT_OR_FINISH        
                
    JMP     LOOP ; after decode process, ask user to continue or not

; TODO: convert int to HEX . Or user will input hex value? In second case, we need to develop a converter that does char to hex
REPEAT_OR_FINISH:
    ; "Would you like to continue, type y for yes / type n for no"
    LEA     CONFIRM_MSG,A1 ; load message on A1
    MOVE.B  #14,D0 ; read char at A1 until null
    TRAP    #15 ; excute command code at D0 
    
    
    LEA     INPUT_VALUE,A1 ; Get user's input
    MOVE.B  #2,D0 ; Read string from keyboard and store at (A1), NULL terminated, length retuned in D1.W (max 80)
    TRAP    #15 ; excute trap
    
    
    ; Compare by ascii
    MOVEA   INPUT_VALUE, A1
    CMPA  #$7900, A1        ; if y($79) Y($59) -> JMP Yes
    BEQ     Yes
    CMPA  #$5900, A1 
    BEQ     Yes
    CMPA  #$4E00, A1        ; else if n($6E) N($4E) -> JMP No
    BEQ     No
    CMPA  #$6E00, A1
    BEQ     No
    
    ;  else it is wrong input
    CLR.L   INPUT_VALUE
    
    LEA     WARNING_MSG,A1 ; load message on A1
    MOVE.B  #14,D0 ; read char at A1 until null
    TRAP    #15 ; excute command code at D0;  
    JMP     REPEAT_OR_FINISH  
    
    Yes:
    CLR.L   INPUT_VALUE
    JMP     DECODE_LOOP
      
    No:
    JMP END 

; TODO: convert int to HEX . Or user will input hex value? In second case, we need to develop a converter that does char to hex
ATOI:
    CMP     #0,D1 ; check if there is char to process D1: length of string
    BEQ     FINISH_ADDR ; finish processing address
    MOVE.B  (A1),D0 ; load one char to D0 to process
    CLR.B   (A1)+ ; clear one char in memory after read one char
    SUB     #1,D1 ; decrement length of char D1: lengh of string
    CMPI    #$66,D0 ; check lowercase ascii f ($66)
    BGT     ERROR   ; throw error if it's larger than $66
    CMPI    #$61,D0 ; check lowervase ascii a ($61)
    BGE     CONVERT_LOWERCHAR_TO_HEX ; jump to convert a-f to Hex
    CMPI    #$46,D0 ; Check if the hex value of char is more than F ($46)
    BGT     ERROR ; if is bigger than $46 prompt error
    CMPI    #$41,D0 ; Check if the hex value of char is more or equal to A ($41)
    BGE     CONVERT_UPPERCHAR_TO_HEX ; Jump to convert A-F to Hex
    CMPI    #$39,D0 ; check if the hex value of char is less than 9 ($39)
    BGT     ERROR ; out of bound for char value 1-9
    CMPI    #$30,D0 ; check if the hex value of char is more than 0 ($30)
    BGE     CONVERT_NUM_TO_HEX
    BRA     ERROR ; otherwise error
    
CONVERT_LOWERCHAR_TO_HEX:
    LSL.L   #4,D2 
    SUBI    #87,D0
    ADD.B   D0,D2
    BRA     ATOI
    
CONVERT_UPPERCHAR_TO_HEX:
    LSL.L   #4,D2 ; shift 4 bits to append new hex
    SUBI    #$37,D0 ; subtract hex 37 to convert A-F to hex
    ADD.B   D0,D2 ; load hex to D2 by adding
    BRA     ATOI

CONVERT_NUM_TO_HEX: ; 
    LSL.L   #4,D2 ; shift 4 bits to append new hex
    SUBI    #$30,D0 ; subtract hex 30 to convert 1-9 to hex
    ADD.B   D0,D2 ; load hex to D2 by adding
    BRA     ATOI

FINISH_ADDR:
    BTST    #0,D2 ; check even or odd address
    BNE     ERROR
    MOVE.L  D2,(A3) ; save start address to variable start_address
    CLR.L   D2 ; clear D2 for next process
    CMP     #1,D3 ; check if D3 is true
    BEQ     CHECK_ADDRESS ; jump to check the correctness of start and end address
    BRA     END_ADDR

ERROR:
    CLR.L   D2 ; clear D2 for next process
    LEA     ERROR_INPUT,A1 ; load error message
    MOVE.B  #14,D0 ; prompt error message to user
    TRAP    #15
    jmp     START ; back to the begining of the program
    
* Put program code here
   
*----------------------------------------------------------------------------   
*
*   Param A5 current address
*   op_start (  A5  ) {
*   D0 = the current instruction (in word)
*   D1 = 1st ~ 4th nibble as well as 1st ~ 2ND bytes
*   D2 = data size, shift counts
*   D3 = loop counter
*   D4 = 0:right, non 0: left in shift or rotate
*   D5 = 0:Bcc, 1: DBcc, 2:Scc
*   A0 = OP_TABLE, OP_0000_TABLE
*   A1 = a pointer to a message to print out
*   A2 = a pointer to decded_buf
*   A5 = a pointeer to current instruction
*   }
*----------------------------------------------------------------------------   
OP_START:    
    MOVEM.L    D5, -(SP)    ;  push D5(LOOP COUNTER)
    
    ; clear decoded_buf
    JSR         OP_DATA_CLR
    LEA         buffer, A2 ;  A2 will be pointing to decoded_buf (completely cleared)
    
    ; print the address
    MOVE.L      #$0003, D2      ;  D2 = data size (011 = long address)
    MOVE.L      A3, D7
    MOVE.L      D7, (A5)
    JSR         ITOA            ;  A5 converts into ascii

     
    MOVE.B      #' ', (A2)+      ;  address' ' 
    
 
    LEA         OP_TABLE, A0        ; A0, points OP_TABLE
    CLR.L       D0                  ; Clears D0
    MOVE.W      (A3), D0           ; Load the current instruction word to D0
    MOVE.L      D0, D1              ; D1 = D0 
    MOVE.B      #12, D2             ; D2 = 12
    LSR.W       D2, D1              ; get and save the OP code to D1
    MULU        #6, D1              ; compute the opcode jump displacement
    JMP         0(A0, D1)           ; jump to the opcode table entry
    
OP_FINISH: 
  
    MOVEM.L    (SP)+, D5,    ; pop D5(LOOP COUNTER)
    RTS                        ; return to the main
    
*----------------------------------------------------------------------------   

OP_DATA_CLR:
    CLR.L      D3
    MOVE.B     #bufsize,   D3                     ; Buffsize = 64, and D3 as counter
    LEA        buffer,    A2             ; for (int D3 = 64; D3 >0; D3--)
    
OP_DATA_CLR_LOOP:
    MOVE.B     #0, (A2)+       ; (A2)++     = $0
    SUBI       #1, D3  
    BGT        OP_DATA_CLR_LOOP
    RTS
*----------------------------------------------------------------------------      
 
OP_TABLE:
    JMP     code0000            ; ADDI.bwl / ANDI.bwl / CMPI.bwl / EORI.bwl / ORI.bwl / SUBI.bwl
    JMP     code0001            ; MOVE.b
    JMP     code0010            ; MOVE.l / MOVEA.l
    JMP     code0011            ; MOVE.w / MOVEA.w
    JMP     code0100            ; CLR.bwl  /JMP    /JSR    /LEA    /MOVEM.wl/EXT /NOP   /NOT.bwl/RTS/STOP/TRAP   
    JMP     code0101            ; ADDQ.bwl / SUBQ.bwl  (Scc/DBcc)  
    JMP     code0110            ; BRA.bw   / BSR.bw    /Bcc.bw  
    JMP     code0111            ; MOVEQ   
    JMP     code1000            ; DIVS     / DIVU      /OR.bwl  
    JMP     code1001            ; SUB.bwl  /  SUBA.wl  
    JMP     code1010            ;   (--unassigned--)  
    JMP     code1011            ; CMP.bwl   /CMPA.wl    /EOR.bwl
    JMP     code1100            ; MULS      / MULU      /AND.bwl
    JMP     code1101            ; ADD.bwl   /  ADDA.wl  /(ADDX.bwl)     
    JMP     code1110            ; ASL.bwl   /   ASR.bwl / LSL.bwl / LSR.bwl /ROL.bwl / ROR.bwl  
    JMP     code1111            ;   (--unassigned--)
  
*----------------------------------------------------------------------------   

code0000: 
    ; ADDI.bwl / ANDI.bwl / CMPI.bwl / EORI.bwl / ORI.bwl / SUBI.bwl
    ;   These OP codes are depended on 2nd nibble   
    
    MOVE.L  D0, D1              ; D1 = D0 (current instruction word)
    ANDI.W  #$0F00, D1          ; 2nd NIBBLE
    MOVE.B  #8, D2              ; D2 Shift Counter = 8
    LSR.W   D2, D1              ; 2nd nibble move to the last nibble
    MULU    #6, D1              ; compute the op_0000_table jump displacement
    LEA     OP_0000_TABLE, A0   ; A0 pointing OP_0000_Table
    JMP     0(A0, D1)
    
code0001:      
    BRA     OP_MOVE             ; Only Move      
     
code0010:
    ; MOVE.l / MOVEA.l
    
    MOVE.L  D0, D1              ; D1 = D0 (current instruction word)
    ANDI.W  #dstmode_Bi, D1        ; destination mode (Dn vs An)
    MOVE.B  #6, D2              ; D2 Shift Counter= 6
    LSR.W   D2, D1              ; get the 2nd nibble in D1
    CMP.B   #1, D1              ; if the 2nd nibble is 001
    BEQ     OP_MOVEA            ;     MOVEA.L
    BRA     OP_MOVE             ; else -> MOVE.L
    
code0011:
    ; MOVE.w / MOVEA.w
    
    MOVE.L  D0, D1              ; D1 = D0 (current instruction word)
    ANDI.W  #dstmode_Bi, D1              ; destination mode (Dn vs An)
    MOVE.B  #6, D2              ; D2 Shift Counter = 6
    LSR.W   D2, D1              ; get the 2nd nibble in D1
    CMP.B   #1, D1              ; if Destination mode is 001
    BEQ     OP_MOVEA            ;     MOVEA.W
    BRA     OP_MOVE             ; else -> MOVE.W
    
code0100:
    ;   CLR.bwl  /JMP    /JSR    /LEA    /MOVEM.wl/EXT /NOP   /NOT.bwl/RTS/STOP/TRAP   
    ;   These OP Codes are depended on 2ND Nibble 
  
    MOVE.L  D0, D1              ; D1 = D0 (current instruction word)
    ANDI.W  #$0F00, D1          ; get the 2nd nibble in D1
    MOVE.B  #8, D2              ; D2 Shift Counter = 8
    LSR.W   D2, D1              ; Move the 2nd nibble to the last nibble in D1
    MULU    #6, D1              
    LEA     OP_0100_TABLE, A0   ; A0 pointing OP_0100_Table
    JMP     0(A0, D1)           ;   Jump to the designated OP_CODE
    
code0101:
    ;   ADDQ.bwl / SUBQ.bwl
    
    MOVE.L  D0, D1              ; D1 = D0 (current instruction word)
    ANDI.W  #$00F0, D1          ; 3RD NIBBLE
    MOVE.B  #4, D2              ; D2 = 4
    LSR.W   D2, D1              ; get the 2nd nibble in D1
    CMP.B   #$B, D1             ; if nibble 3<= 1011
    BLE     OP_ADDQ_SUBQ        ;   ADDQ or SUBQ
    CMP.B   #$C, D1             ; else if it == 1100
    BEQ     OP_UNSUPPORTED      ;  No Support OP_DBCC            
    JMP     OP_UNSUPPORTED      ;     No Support OP_SCC              

code0110:
    ;   BRA.bw   / BSR.bw    /Bcc.bw
    
    MOVE.B  #'B', (A2)+         ;Bcc   
    MOVE.L  D0, D1              ; D1 = D0 (cur instruction word)
    ANDI.W  #$0F00, D1          ; get 2nd nibble in to D1     
    MOVE.B  #8, D2              ; D2 Shift Counter = 8
    LSR.W   D2,D1               ; move 2nd nibble to the last nibble
    MULU    #6, D1              
    LEA     OP_COND_TABLE, A0   ;  A0 points OP_COND_TABLE
    JMP     0(A0,D1)            ; jump to designated OP CODE
    
code0111:
    ;   MOVEQ     
    JMP     OP_MOVEQ            ;0111 only indicates MOVEQ
    
code1000:
    ;   DIVS     / DIVU      /OR.bwl
    
    MOVE.L  D0, D1              ; copy current instrunction into D1
    ANDI.W  #dstmode_Bi, D1        ; get the destination mode
    MOVE.B  #6, D2              ; D2 Shift Counter = 6
    LSR.W   D2, D1              ; Getting destination mode in D1
    CMP.B   #$3, D1             ; if destination mode == 011
    BEQ     OP_DIVU             ;   DIVU
    CMP.B   #$7, D1             ; else if == 111
    BEQ     OP_DIVS             ;   DIVS
    CMP.B   #$4, D1             ; else if == 100
    BEQ     OP_SBCD_OR          ;   no sppt (SBCD) || OR
    JMP     OP_OR               ; else -> OR

OP_SBCD_OR:
    MOVE.L  D0, D1              ; copy current instruction into D1
    ANDI.W  #srcmode_Bi, D1        ; get the source mode
    MOVE.B  #3, D2              ; D2 Shift Counter = 3
    LSR.W   D2, D1              ; get src mode in D1
    CMP.B   #$1, D1             ; if srcmode <= 001
    BLE     OP_UNSUPPORTED      ;   (NO SUPPORT OP_SBCD)             
    JMP     OP_OR               ; else OR
    
code1001:
    ;   SUB.bwl  /  SUBA.wl 
   
    MOVE.L  D0, D1              ; copy instruction code       
    ANDI.W  #dstmode_Bi, D1        ; get the destination mode into D1
    MOVE.B  #6, D2              ; D2 Shift Counter = 6
    LSR.W   D2, D1              ; get the destination mode to First Nibble for comparison
    CMP.B   #$3, D1             ; if destmode == 011 
    BEQ     OP_INVALID          ; NOT SUPPORTED OP_SUBA ************************************************************************
    CMP.B   #$7, D1             ; if destmode == 111
    BEQ     OP_UNSUPPORTED      ;    NOT SUPPORTED OP_SUBA ***********************************************************************
    CMP.B   #$4, D1             ; else if destmode = 100, 101, or 110 (4,5,6)
    BGE     OP_SUBX_SUB         ; SUBX or SUB
    JMP     OP_SUB              ; else SUB
OP_SUBX_SUB:
    MOVE.L  D0, D1              ; copy instruction code
    ANDI.W  #srcmode_Bi, D1        ; get the source mode into D1
    MOVE.B  #3, D2              ;  D2 Shift Counter = 3
    LSR.W   D2, D1              ;  get src mode in D1
    CMP.B   #$1, D1             ; if srcmode <= 001
    BLE     OP_INVALID             ; NOT SUPPORTED  SUBX ***********************************************************************
    JMP     OP_SUB              ; else SUB

code1010:
    ;   (--unassigned--)
    
    MOVE.B  #13, D0
    LEA     test_1010, A1
    TRAP    #15
    
    ;   message needed
    JMP     OP_INVALID
    
code1011:
    ;   CMP.bwl   / Not Supporting (CMPA.wl)    /EOR.bwl
    
    MOVE.L  D0, D1              ; get the current instruction into D1
    ANDI.W  #$00F0, D1          ; get 3rd nibble in D1  
    MOVE.B  #4, D2              ;  D2 Shift Counter = 4
    LSR.W   D2, D1              ; move 3rd nibble to last nibble
    CMP.B   #$C, D1             ; if 3rd nibble >= 1100
    BGE     OP_INVALID          ; CMPA NOT SUPPROTED *********************************************
    
    MOVE.L  D0, D1              ; get current instruction again
    ANDI.W  #$0F00, D1          ; get 2nd nibble 
    MOVE.B  #9, D2              ; D2 Shift Counter = 9  
    LSR.W   D2, D1              
    BCC     OP_CMP              ; if 2nd nibble %2 == 0
                                ; CMP
    
    MOVE.L  D0, D1              ; get the current instruction into D1
    ANDI.W  #srcmode_Bi, D1        ; get the source mode into D1
    MOVE.B  #3, D2              ;  D2 Shift Counter = 3
    LSR.W   D2, D1              ; bring the source mode to last nibble
    CMP.B   #1, D1              ;   if srcmode == 1
    BEQ     OP_INVALID          ; CMPM NOT SUPPORTED *********************************************
    BLE     OP_UNSUPPORTED              ;   if srcmode <= 3
    JMP     OP_INVALID          ;       EOR
                                ;   else INVALID
    
code1100:
    ;   MULS      / MULU      /AND.bwl
    
    MOVE.L  D0, D1              ; get current instruction again
    ANDI.W  #dstmode_Bi, D1        ; get the destination mode into D1
    MOVE.B  #6, D2              ; D2 Shift Counter = 6
    LSR.W   D2, D1
    CMP.B   #3, D1              ; if dstmode == 011
    BEQ     OP_MULU                ;   MULU
    CMP.B   #7, D1              ; if dstmode == 111
    BEQ     OP_MULS                ;   MULS
    CMP.B   #4, D1              ; if dstmode == 100
    BEQ     OP_POSSIBLE_AND      
    CMP.B   #5, D1              ; if dstmode == 101, 110, 111
    BGE     OP_POSSIBLE_AND     
    
OP_POSSIBLE_AND:
    MOVE.L  D0, D1              ; get current instruction
    ANDI.W  #srcmode_Bi, D1        ; get the source mode in to D1
    MOVE.B  #3, D2              ; D2 Shift Counter = 3
    LSR.W   D2, D1              ; 
    CMP.B   #1, D1              ;  if source mode <= 1
    BEQ     OP_UNSUPPORTED      ;    An can't be src
    JMP     OP_AND              ;  else -> AND     
    
code1101:
    ; ADD.bwl   /  ADDA.wl  /(ADDX.bwl)

    MOVE.L  D0, D1              ; get the current instruction into D1
    ANDI.W  #dstmode_Bi, D1        ; get the destination mode into D1
    MOVE.B  #6, D2              ; D2 Shift Counter = 6
    LSR.W   D2, D1              ; get dest mode to D1
    CMP.B   #$3, D1             ; if dest mode == 011 or 111
    BEQ     OP_ADDA             ; ADDA
    CMP.B   #$7, D1
    BEQ     OP_ADDA             ; ADDA
    
    MOVE.B  #3, D2              ; check the 1st bit of dest mode
    LSR.W   D2, D1              ; if bit == 1
    BCS     OP_POSSIBLE_ADD     ;   could be ADDX
    JMP     OP_ADD              ; else ADD
OP_POSSIBLE_ADD:
    MOVE.L  D0,D1               ; get the current instruction into D1
    ANDI.W  #srcmode, D1        ; get the source mode into D1
    MOVE.B  #3, D2              ; D2 Shift Counter = 3
    LSR.W   D2, D1
    CMP.B   #01, D1             ;  if source mode <= 001    
    BLE     OP_UNSUPPORTED      ;   Not Suppporting ADDX
    JMP     OP_ADD              ;  else -> ADD

code1110:
    ;   ASL.bwl   /   ASR.bwl / LSL.bwl / LSR.bwl /ROL.bwl / ROR.bwl  

    MOVE.L  D0, D1              ; get current instruction into D1   
    ANDI.W  #dstmode_low2, D1   ; get 6th and 7th bit
    MOVE.B  #6, D2              ; D2 Shift Counter = 6  
    LSR.W   D2, D1              ; shift right 6 times
    CMP.B   #$3, D1             ;  if 6/7 bit == 011
    BEQ     MEM_SHIFT           ;   LSL,LSR,ASL,ASR
    JMP     REG_SHIFT           ; else -> ROL,ROR
MEM_SHIFT:
    MOVE.L  D0, D1              ; get current instruction into D1   
    ANDI.W  #dstreg, D1         ; 9,10,11th bit
    MOVE.B  #9, D2              ; D2 Shift Counter = 9
    LSR.W   D2, D1              ; 
    MULU    #6, D1                  
    
    MOVE.L  D0, D4              ; get current instruction to D4
    ANDI.W  #%0000000100000000, D4  ; get direction
    LSR.W   #8, D4
    CMP.B   #0, D4
    BEQ     DIR_RIGHT
                                ; Else DIR_LEFT
DIR_LEFT:                           
    LEA     LEFT_SHIFT_TABLE, A0
    JMP     0(A0,D1)

DIR_RIGHT:
    LEA     RIGHT_SHIFT_TABLE, A0
    JMP     0(A0, D1)
    
REG_SHIFT:
    MOVE.L  D0, D1              ; get current instruction into D1
    ANDI.W  #srcmode_low2, D1   
    MOVE.B  #right3, D2         ; D2 Shift Counter = 3
    LSR.W   D2, D1              ; 
    MULU    #6, D1              ;
    
    MOVE.L  D0, D4              ;  get current instruction into D4
    ANDI.W  #%0000000100000000, D4  ; get direction
    LSR.W   #8, D4
    CMP.B   #1, D4
    BEQ     DIR_LEFT
    JMP     DIR_RIGHT

code1111:
    ;   (--unassigned--)
    
    MOVE.B  #13, D0             ;task #13
    LEA     test_1110, A1
    TRAP    #15 
    
    ; message needed
    JMP     OP_INVALID
    
*----------------------------------------------------------------------------   
OP_0000_TABLE:
    JMP     OP_ORI              ; 0: ORI
    JMP     OP_ANDI      ; 1: not supported for BTST, BCHG, BCLR, BSET, MOVEP with Dn
    JMP     OP_UNSUPPORTED     ; 2: ANDI
    JMP     OP_UNSUPPORTED      ; 3: not supported for BTST, BCHG, BCLR, BSET, MOVEP with Dn
    JMP     OP_SUBI             ; 4: SUBI
    JMP     OP_UNSUPPORTED      ; 5: not supported for BTST, BCHG, BCLR, BSET, MOVEP with Dn
    JMP     OP_ADDI             ; 6: ADDI
    JMP     OP_UNSUPPORTED      ; 7: not supported for BTST, BCHG, BCLR, BSET, MOVEP with Dn
    JMP     OP_UNSUPPORTED      ; 8: not supported for BTST, BCHG, BCLR, BSET, MOVEP with Dn
    JMP     OP_UNSUPPORTED      ; 9: not supported for BTST, BCHG, BCLR, BSET, MOVEP with Dn
    JMP     OP_EORI             ; A: EORI
    JMP     OP_UNSUPPORTED      ; B: not supported for BTST, BCHG, BCLR, BSET, MOVEP with Dn
    JMP     OP_CMPI             ; C: not supported for BTST, BCHG, BCLR, BSET, MOVEP with Dn
    JMP     OP_UNSUPPORTED      ; D: not supported for BTST, BCHG, BCLR, BSET, MOVEP with Dn
    JMP     OP_INVALID          ; E: INVALID
    JMP     OP_UNSUPPORTED      ; F: not supported for BTST, BCHG, BCLR, BSET, MOVEP with Dn
    
*----------------------------------------------------------------------------   

OP_0100_TABLE:
    JMP     OP_UNSUPPORTED      ; 0: not supported for MOVE from SR
    JMP     OP_LEA              ; 1: LEA An 1
    JMP     OP_CLR              ; 2: CLR
    JMP     OP_LEA              ; 3: LEA An 1
    JMP     OP_UNSUPPORTED      ; 4: not supported for MOVE from CCR
    JMP     OP_LEA              ; 5: LEA An 1
    JMP     OP_UNSUPPORTED      ; 6: NOT
    JMP     OP_LEA              ; 7: LEA An 1
    JMP     OP_EXT_MOVEM        ; 8: EXT, MOVEM
    JMP     OP_LEA              ; 9: LEA An 1
    JMP     OP_UNSUPPORTED      ; A: not supported for ILLEGAL, TAS, TST
    JMP     OP_LEA              ; B: LEA An 1
    JMP     OP_MOVEM            ; C: MOVEM
    JMP     OP_LEA              ; D: LEA An 1
    JMP     OP_JNRST            ; E: JMP, JSR, NOP, RTE, RTS, STOP,TRAP
    JMP     OP_LEA              ; F: LEA An 1

*----------------------------------------------------------------------------   

OP_COND_TABLE:
    JMP     OP_RA               ; 0: BRA
    JMP     OP_SR               ; 1: BSR
    JMP     OP_HI               ; 2: BNI
    JMP     OP_LS               ; 3: BLS
    JMP     OP_CC               ; 4: BCC
    JMP     OP_CS               ; 5: BCS
    JMP     OP_NE               ; 6: BNE
    JMP     OP_EQ               ; 7: BEQ
    JMP     OP_VC               ; 8: BVC
    JMP     OP_VS               ; 9: BVS
    JMP     OP_PL               ; A: BPL
    JMP     OP_MI               ; B: BMI
    JMP     OP_GE               ; C: BGE
    JMP     OP_LT               ; D: BLT
    JMP     OP_GT               ; E: BGT
    JMP     OP_LE               ; F: BLE            

*----------------------------------------------------------------------------   

LEFT_SHIFT_TABLE:
    JMP     OP_ASL             ; ASL
    JMP     OP_LSL             ; LSL
    JMP     OP_UNSUPPORTED     ; ROXL
    JMP     OP_ROL             ; ROL

*----------------------------------------------------------------------------   

RIGHT_SHIFT_TABLE:
    JMP     OP_ASR              ; ASR
    JMP     OP_LSR              ; LSR
    JMP     OP_UNSUPPORTED      ; ROXR
    JMP     OP_ROR              ; ROR

*----------------------------------------------------------------------------   

; enter OP names in the buffer
*---- 0000 ------------------------------------------------------------------
OP_ORI:
    MOVE.B  #'O', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.B  #'I', (A2)+
    MOVE.B  #0, D0
    JSR     EA_START
    JMP     OP_FINISH
    
OP_ANDI:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'N', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'I', (A2)+
    ; Load immediate type
    MOVE.B  #0, D0
    JSR     EA_START
    JMP     OP_FINISH
    
OP_SUBI:
    MOVE.B  #'S', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #'B', (A2)+
    MOVE.B  #'I', (A2)+
    ; Load immediate type
    MOVE.B  #0, D0
    JSR     EA_START
    JMP     OP_FINISH
    
OP_ADDI:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'I', (A2)+
    ; Load immediate type
    MOVE.B  #0, D0
    JSR     EA_START
    JMP     OP_FINISH   
    
OP_EORI:
    MOVE.B  #'E', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.B  #'I', (A2)+
    ; Load immediate type
    MOVE.B  #0, D0
    JSR     EA_START
    JMP     OP_FINISH
    
OP_CMPI:
    MOVE.B  #'C', (A2)+
    MOVE.B  #'M', (A2)+
    MOVE.B  #'P', (A2)+
    MOVE.B  #'I', (A2)+
    ; Load immediate type
    MOVE.B  #0, D0
    JSR     EA_START
    JMP     OP_FINISH
    
*---- 0001, 0011, 0010 ------------------------------------------------------
OP_MOVE:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'E', (A2)+
    ; Load immediate type
    MOVE.B  #1, D0
    JSR     EA_START
    JMP     OP_FINISH
    
OP_MOVEA:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'E', (A2)+
    MOVE.B  #'A', (A2)+
    ; Load immediate type
    MOVE.B  #2, D0
    JSR     EA_START
    JMP     OP_FINISH

*---- 0100 ------------------------------------------------------------------
OP_CLR:
    MOVE.B  #'C', (A2)+
    MOVE.B  #'L', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.B  #4, D0
    JSR     EA_START
    JMP     OP_FINISH
    
OP_JNRST:               ;   (BGE OP_JMP_JSR)
    
    
    MOVE.W  D0, D1      ;   get instruction again
    ANDI.W  #$00F0, D1      ;   get 3rd nibble                               
    MOVE.B  #4, D2      ;   D2 as counter for shifting right D1
    LSR.W   D2, D1      ;   Checking the Nibble
    CMP.B   #4, D1      ;   if 3rd NIbble == 4
    BEQ     OP_UNSUPPORTED     ;       TRAP       
    CMP.B   #7, D1      ;   else if 3rd Nibble == 7 
    BEQ     OP_NOP_RTE_RTS_STOP ; NOP||RTE||RTS||STOP         
                        
                        ;   else check for JSR and JMP  
                        
    ANDI.W  #0100, D1   ;   Checking 6th bit
    MOVE.B  #2, D2      
    LSR.W   D2, D1      ;   Getting 6th bit for testing
    CMP.B   #1, D1      ;   if 6th Bit = 1
    BEQ     OP_JMP      ;       OP_JMP
                        ;   else
                        ;       Flow to OP_JSR
OP_JSR:
    MOVE.B  #'J', (A2)+
    MOVE.B  #'S', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.B  #' ', (A2)+
    MOVE.B  #13,D0
    JSR     EA_START    
    JMP     OP_FINISH
    
OP_JMP:
    MOVE.B  #'J', (A2)+
    MOVE.B  #'M', (A2)+
    MOVE.B  #'P', (A2)+
    MOVE.B  #' ', (A2)+
    MOVE.B  #13,D0
    JSR     EA_START
    JMP     OP_FINISH    

    
OP_NOP_RTE_RTS_STOP:
    MOVE.L  D0,D1           ; D1 = D0 (current instruction word)
    ANDI.W  #$000F, D1          ; extract the 4th nibble in D1
    CMP.B   #$1, D1         ; if nibble4 == 0001   
    BEQ     OP_NOP
    CMP.B   #$2, D1         ; else if nibble4 == 0010
    BEQ     OP_UNSUPPORTED        ;OP_STOP
    CMP.B   #$3, D1         ;else if nibble4 == 0011
    BEQ     OP_UNSUPPORTED          ;RTE
    CMP.B   #$5, D1         ; else if nibble4 ==  0101
    BEQ     OP_RTS
    JMP     OP_INVALID
    
OP_NOP:
    MOVE.B  #'N', (A2)+    
    MOVE.B  #'O', (A2)+
    MOVE.B  #'P', (A2)+
    ;Need additional line to move to the next Word
    ADDI    #2, D4  
    JSR     FINISH_EA   
    JMP     OP_FINISH
      
OP_RTS:
    MOVE.B  #'R', (A2)+
    MOVE.B  #'T', (A2)+
    MOVE.B  #'S', (A2)+
    ADDI    #2, D4  
    JSR     FINISH_EA
    JMP     OP_FINISH
    
OP_EXT_MOVEM:
    MOVE.L  D0, D1          ; get current instruction into D1
    ANDI.W  #srcmode, D1    ; D1 Sourc mode into D1
    MOVE.B  #right3, d2     ; D2 Shift Counter = 3 
    LSR.W   D2, D1          
    CMP.B   #0, D1          ; if source Mode == 000
    BEQ     OP_UNSUPPORTED  ;   OP_EXT
    BRA     OP_MOVEM        ; else -> MOVEM 
    
OP_MOVEM:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'E', (A2)+
    MOVE.B  #'M', (A2)+
    ; Load immediate type
    MOVE.B  #5,D0
    JSR     EA_START
    JMP     OP_FINISH
    
OP_LEA:
    MOVE.B  #'L', (A2)+
    MOVE.B  #'E', (A2)+
    MOVE.B  #'A', (A2)+
    MOVE.B  #' ', (A2)+
    ; Load immediate type
    MOVE.B  #3,D0
    JSR     EA_START
    JMP     OP_FINISH
    
*---- 0101 ------------------------------------------------------------------
OP_ADDQ_SUBQ:
    MOVE.W  D0, D1      ;   get current instruction again
    ANDI.W  #$0F00, D1  ;   check 2nd nibble
    MOVE.B  #8, D2      ;   
    LSR.W   D2,D1       ;   
    ANDI.W  #0001, D1   ; Checking first bit
    CMP.B   #1, D1      ; if 01
    BEQ     OP_SUBQ        ;    jump to SUBQ
                        ; else
                        ;    let it flow to ADDQ 
                      
OP_ADDQ:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'Q', (A2)+
     ; Load immediate type
    MOVE.B  #6,D0
    JSR     EA_START
    JMP     OP_FINISH
    
OP_SUBQ:
    MOVE.B  #'S', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #'B', (A2)+
    MOVE.B  #'Q', (A2)+
    ; Load immediate type
    MOVE.B  #6,D0
    JSR     EA_START
    JMP     OP_FINISH
       
*---- 0110 ------------------------------------------------------------------


OP_RA:
    MOVE.B  #'R', (A2)+
    MOVE.B  #'A', (A2)+
    MOVE.B  #' ', (A2)+ 
        ; Load immediate type
    MOVE.B  #7,D0
    JSR     EA_START
    JMP     OP_FINISH
    
OP_SR:
    MOVE.B  #'S', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.B  #' ', (A2)+ 
    ; Load immediate type
    MOVE.B  #7,D0
    JSR     EA_START
    JMP     OP_FINISH
    
OP_HI:
    MOVE.B  #'H',   (A2)+
    MOVE.B  #'I',   (A2)+
    MOVE.B  #' ', (A2)+
    ; Load immediate type
    MOVE.B  #7,D0
    JSR     EA_START
    JMP     OP_FINISH
    
OP_LS:
    MOVE.B  #'L',   (A2)+
    MOVE.B  #'S',   (A2)+  
    MOVE.B  #' ', (A2)+
        ; Load immediate type
    MOVE.B  #7,D0
    JSR     EA_START
    JMP     OP_FINISH
    
OP_CC:
    MOVE.B  #'C', (A2)+
    MOVE.B  #'C', (A2)+
    MOVE.B  #' ', (A2)+
    ; Load immediate type
    MOVE.B  #7,D0
    JSR     EA_START
    JMP     OP_FINISH
    
OP_CS:
    MOVE.B  #'C',   (A2)+
    MOVE.B  #'S',   (A2)+ 
    MOVE.B  #' ', (A2)+ 
    ; Load immediate type
    MOVE.B  #7,D0
    JSR     EA_START
    JMP     OP_FINISH
    
OP_NE:
    MOVE.B  #'N',   (A2)+
    MOVE.B  #'E',   (A2)+
    MOVE.B  #' ', (A2)+  
    ; Load immediate type
    MOVE.B  #7,D0
    JSR     EA_START
    JMP     OP_FINISH
    
OP_EQ:
    MOVE.B  #'E',   (A2)+
    MOVE.B  #'Q',   (A2)+
    MOVE.B  #' ', (A2)+     
    ; Load immediate type
    MOVE.B  #7,D0
    JSR     EA_START
    JMP     OP_FINISH
 
OP_VC:
    MOVE.B  #'V',   (A2)+
    MOVE.B  #'C',   (A2)+
    MOVE.B  #' ', (A2)+  
    ; Load immediate type
    MOVE.B  #7,D0
    JSR     EA_START
    JMP     OP_FINISH
    
OP_VS:
    MOVE.B  #'V',   (A2)+
    MOVE.B  #'S',   (A2)+
    MOVE.B  #' ', (A2)+    
    ; Load immediate type
    MOVE.B  #7,D0
    JSR     EA_START
    JMP     OP_FINISH
    
OP_PL:
    MOVE.B  #'P',   (A2)+
    MOVE.B  #'L',   (A2)+ 
    MOVE.B  #' ', (A2)+  
    ; Load immediate type
    MOVE.B  #7,D0
    JSR     EA_START
    JMP     OP_FINISH
    
OP_MI:
    MOVE.B      #'M',   (A2)+   
    MOVE.B      #'I',   (A2)+
    MOVE.B  #' ', (A2)+       
    ; Load immediate type
    MOVE.B  #7,D0
    JSR     EA_START
    JMP     OP_FINISH
    
OP_GE:
    MOVE.B  #'G',   (A2)+
    MOVE.B  #'E',   (A2)+ 
    MOVE.B  #' ', (A2)+ 
    ; Load immediate type
    MOVE.B  #7,D0
    JSR     EA_START
    JMP     OP_FINISH
    
OP_LT:
    MOVE.B  #'L',   (A2)+
    MOVE.B  #'T',   (A2)+ 
    MOVE.B  #' ', (A2)+     
    ; Load immediate type
    MOVE.B  #7,D0
    JSR     EA_START
    JMP     OP_FINISH
    
OP_GT:
    MOVE.B  #'G',   (A2)+
    MOVE.B  #'T',   (A2)+
    MOVE.B  #' ', (A2)+  
    ; Load immediate type
    MOVE.B  #7,D0
    JSR     EA_START
    JMP     OP_FINISH
    
OP_LE:
    MOVE.B  #'L',   (A2)+
    MOVE.B  #'E',   (A2)+ 
    MOVE.B  #' ', (A2)+ 
    ; Load immediate type
    MOVE.B  #7,D0
    JSR     EA_START
    JMP     OP_FINISH
    
*---- 0111 ------------------------------------------------------------------
OP_MOVEQ:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'E', (A2)+
    MOVE.B  #'Q', (A2)+
    MOVE.B  #' ', (A2)+ 
    MOVE.B  #11,D0
    JSR     EA_START
    JMP OP_FINISH


*---- 1000 ------------------------------------------------------------------
OP_DIVU:
    MOVE.B  #'D', (A2)+
    MOVE.B  #'I', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #' ', (A2)+
    
    MOVE.B  #10,D0
    JSR     EA_START
    JMP OP_FINISH
OP_DIVS:
    MOVE.B  #'D', (A2)+
    MOVE.B  #'I', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'S', (A2)+
    MOVE.B  #' ', (A2)+
    MOVE.B  #10,D0
    JSR     EA_START
    JMP OP_FINISH
    
OP_OR:
    MOVE.B  #'O', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.B  #9,D0
    JSR     EA_START
    JMP OP_FINISH    

*---- 1001 ------------------------------------------------------------------
OP_SUB:
    MOVE.B  #'S', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #'B', (A2)+
    MOVE.B  #9,D0
    JSR     EA_START
    JMP OP_FINISH    

*---- 1011 ------------------------------------------------------------------
OP_CMP:
    MOVE.B  #'C', (A2)+
    MOVE.B  #'M', (A2)+
    MOVE.B  #'P', (A2)+
    MOVE.B  #9,D0
    JSR     EA_START
    JMP OP_FINISH    

*---- 1100 ------------------------------------------------------------------
OP_MULU:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #'L', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #' ', (A2)+
    MOVE.B  #10,D0
    JSR     EA_START
    JMP OP_FINISH
    
OP_MULS:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #'L', (A2)+
    MOVE.B  #'S', (A2)+
    MOVE.B  #' ', (A2)+
    MOVE.B  #10,D0
    JSR     EA_START
    JMP OP_FINISH
    
OP_AND:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'N', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #9,D0
    JSR     EA_START
    JMP OP_FINISH
     
*---- 1101 ------------------------------------------------------------------
OP_ADD:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #9,D0
    JSR     EA_START
    JMP OP_FINISH
    
OP_ADDA:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'A', (A2)+
    MOVE.B  #12,D0
    JSR     EA_START
    JMP OP_FINISH
    

*---- 1110 ------------------------------------------------------------------
OP_ASL:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'S', (A2)+
    MOVE.B  #'L', (A2)+
    MOVE.B  #' ', (A2)+ 
    MOVE.B  #8,D0
    CLR     D4
    JSR     EA_START
    JMP     OP_FINISH
    
OP_ASR:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'S', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.B  #' ', (A2)+
    MOVE.B  #8,D0
    CLR     D4
    JSR     EA_START
    JMP     OP_FINISH
    
OP_LSL:
    MOVE.B  #'L', (A2)+
    MOVE.B  #'S', (A2)+
    MOVE.B  #'L', (A2)+
    MOVE.B  #' ', (A2)+
    MOVE.B  #8,D0
    CLR     D4
    JSR     EA_START
    JMP     OP_FINISH
    
OP_LSR:
    MOVE.B  #'L', (A2)+
    MOVE.B  #'S', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.B  #' ', (A2)+
    MOVE.B  #8,D0
    CLR     D4
    JSR     EA_START
    JMP     OP_FINISH
    
OP_ROL:
    MOVE.B  #'R', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'L', (A2)+
    MOVE.B  #' ', (A2)+
    MOVE.B  #8,D0
    CLR     D4
    JSR     EA_START
    JMP     OP_FINISH
    
OP_ROR:
    MOVE.B  #'R', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.B  #' ', (A2)+
    MOVE.B  #8,D0
    CLR     D4
    JSR     EA_START
    JMP     OP_FINISH
    
*--------------------------------------------------------------------------    
OP_UNSUPPORTED:
    MOVE.L  #3, D1         ; Error Code #3
    JSR     ERROR_HANDLER
    MOVE.B  #14, D0 
    TRAP    #15 
    CLR     D0             ;   For the ATOI
    CLR     D1              
    CLR      D2
    CLR     D5  
    CLR     (SP)           ; Clear the Stack Pointer
    JMP     WELCOME

OP_INVALID:
    MOVE.L  #4, D1          ; Error Code #4
    JSR     ERROR_HANDLER
    MOVE.B  #14, D0 
    TRAP    #15 
    CLR     D0             ;   For the ATOI
    CLR     D1              
    CLR      D2  
    CLR     D5             ; Clear the loop counter
    CLR     (SP)           ; Clear the Stack Pointer
    JMP     WELCOME
*--------------------------------------------------------------------------    

EA_START:
; push some data here for Op calculation ex) D3: loop counter 
    MOVE.B  D0,D1 ; save EA TYPE in D0
    LEA     EA_TYPE_TABLE,A0
    MULU    #6,D1
    JMP     0(A0,D1) ; jump to ea table according to D1 value

EA_TYPE_TABLE:
    JMP     EA_IMMEDIATE ; EA_TYPE 0  ORI, ANDI, SUBI, ADDI, EORI, CMPI
    JMP     EA_MOVE ;1 MOVE
    JMP     EA_MOVEA ;2 MOVEA
    JMP     EA_LEA ;3 LEA
    JMP     EA_CLR ;4 
    JMP     EA_MOVEM ;5
    JMP     EA_QUICK ; ADDQ, SUBQ ; 6
    JMP     EA_BRANCH ;7 Bcc, BRA, BSR
    JMP     EA_SHIFT ; 8 ASL, ASR, LSL, LSR, ROL, ROR
    JMP     EA_EXTRA ; 9 SUB, ADD, OR, AND, CMP
    JMP     EA_MUL_DIV ; 10 MULU, MULS, DIVU, DIVS ; size is fixed for this opcode always WORD
    JMP     EA_MOVEQ ; 11 MOVEQ
    JMP     EA_ADDA ; 12 ADDA
    JMP     EA_JJ   ; 12 JMP, JSR  

EA_JJ:
    MOVE.W  (A3), D1                  ; Move instruction to D1 for mode
    ANDI.W  #%0000000000111000,D1   ; get mode
    LSR.W   #$3, D1
    
    MOVE.W  (A3), D2                  ; Move instruction to D3 for reg
    ANDI.W  #%0000000000000111,D2   ; get reg
    
    CMP.B   #7, D1                  ; if src mode == 010 || 111
    BEQ     EA_JJ_111
                                    ;   LEA_SUCCESS
    CMP.B   #2, D1
    BEQ     EA_JJ_010
                                    ; else
    BRA     EA_ERROR                   ;   ERROR
        
EA_JJ_010:   
    MOVE.W  (A3), D5                ; CHECKING MODE 111'S REG EDGE CASE
    ANDI.W  #$000F, D5          
    CMP.B   #$A, D5                 ; IF REG is not 000 || 001
    BGE     EA_ERROR                   ;  ERROR
                                    ; ELSE
                                                         
    ADDI    #2,D4 ; instruction word displacement
    JSR     EA_SRC_AS_DST           ;  process

    JMP     FINISH_EA   

EA_JJ_111:
    MOVE.B  #' ', (A2)+
    MOVE.B  #'$', (A2)+     ; Absolute Value
    ADDI    #2, D4          ;  To read extended address
    ADDI    #1, D2          ; ABSOLUTE SIZE + 1
    CMP.B   #0, D3          ;IF ABSOLUTE SIZE 0
    BEQ     JJ_000          ;   SKIP ABSOLUTE SIZE ++ 
    CMP.B   #2, D3  
    BGE     EA_ERROR   
    ADDI    #1, D2          ; BECAUSE #%10 IS FOR LONG   
    
JJ_000:
    JSR     EA_EXTENDED
    JSR     START_ITOA
    JMP     FINISH_EA

EA_CLR:
    ADDI    #2, D4          ;  To read extended address
    MOVE.W  (A3), D2                
    ANDI.W  #%0000000011000000,D2   ; Extract EA size
    LSR.W   #6, D2
    JSR     EA_SIZE_EXTRACT         ;  Getting .B / .W / .L

    MOVE.W  (A3), D1
    ANDI.W  #%0000000000111000, D1  ; get mode
    LSR.W   #3, D1
    
    MOVE.W  (A3), D3                ; Move instruction to D3 for reg
    ANDI.W  #%0000000000000111,D3   ; get reg
    
    CMP.B   #$1, D1                 ; 001 An not supported
    BEQ     EA_ERROR
    
    CMP.B   #7, D1                  ; if src mode == 111
    BEQ     EA_CLR_111
    
    JSR     EA_CALCULATE_SRC
    
    JMP     FINISH_EA
    
EA_CLR_111:
    CLR     D2              ; In case (CLR.B $12341234)
    MOVE.B  #' ', (A2)+
    MOVE.B  #'$', (A2)+     ; Absolute Value
    CMP.B   #0, D3          ;IF ABSOLUTE SIZE 0
    BEQ     CLR_000          ;   SKIP ABSOLUTE SIZE ++ 
    CMP.B   #2, D3  
    BGE     EA_ERROR   
    ADDI    #1, D2          ; D2 = 0 + 1, BECAUSE #%10 IS FOR LONG AND #%01 FOR WORD
    CLR_000:
    ADDI    #1, D2          ; IF LONG ADDRESS D2 = 1 + 1 
    JSR     EA_EXTENDED
    JSR     START_ITOA
    JMP     FINISH_EA



EA_ADDA:
    ADDI    #2,D4
    JSR     EA_ADDA_SIZE
    JSR     EA_CALCULATE_SRC
    MOVE.B  #',',(A2)+
    MOVE.B  #' ',(A2)+
    MOVE.B  #'A',(A2)+
    MOVE.W  (A3),D3
    ANDI.W  #%0000000111000000,D3
    ASR.W   #6,D3
    JSR     INSERT_REG_NUM
    JMP     FINISH_EA
    
EA_ADDA_SIZE:
    MOVE.W  (A3),D2
    ANDI.W  #%0000000111000000,D2
    ASR.W   #6,D2
    CMP     #3,D2
    BEQ     INSERT_SIZE_W_TO_BUFFER
    CMP     #7,D2
    BEQ     INSERT_SIZE_L_TO_BUFFER
    BRA     EA_ERROR
      
EA_MOVEQ:
    ADDI    #2, D4
    MOVE.W  (A3), D6 ; extract immediate data
    ANDI.W  #%0000000011111111, D6
    MOVE.W  D6, (A5) ; give this value to ITOA
    MOVE.B   #%00, D2
    MOVE.B  #'#', (A2)+
    MOVE.B  #'$', (A2)+
    JSR     ITOA
    MOVE.B  #',', (A2)+
    MOVE.B  #' ', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.W  (A3), D3 ; reg num
    ANDI.W  #%0000111000000000, D3
    MOVE.B  #9, D5 
    ASR.W   D5, D3
    JSR     INSERT_REG_NUM
    JMP     FINISH_EA
      
EA_MOVEM:
    ADDI    #4, D4 ; insturction long displacement
    MOVE.W  (A3),D2 ; Size check
    JSR     EA_MOVEM_SIZE
    MOVE.L  #15, D5 ; save masking bit place num
    MOVE.W  (A3),D3 ;
    MOVE.L  #0, D6 ; counter for slash
    BTST    #10,D3 ; check if reg to mem or mem to reg
    BEQ     EA_MOVEM_REG_TO_MEM_CHOOSE
    MOVE.W  (A3), D1
    ANDI.W  #%0000000000111000,D1 ; mode 3 check (An)+ 
    ASR.W   #3,D1 ;
    CMP     #4,D1 ; checking invalid address mode
    BEQ     ERROR
    JSR     EA_SRC_AS_DST
    MOVE.B  #',', (A2)+
    MOVE.B  #' ', (A2)+
    MOVE.W  #15, D5 ; save masking bit place num
    MOVE.L  #0, D6 ; counter for slash
    BRA     EA_MOVEM_MEM_TO_REG
      ; for predecrement mode -> reverse masking bit 
EA_MOVEM_REG_TO_MEM_DEC:
    MOVE.W  2(A3),D3 ; extracting masking bit
    MOVE.L  D5, D1 ; temp
    EORI.B  #%1111, D1 ; extracting reg num
    ANDI.B  #%0111, D1 ; filter reg num
    BTST    D5, D3    
    BNE     EA_INSERT_REG_TO_MEM_DEC
    CMP     #0, D5 ; check if checking masking bit is finished
    BEQ     EA_MOVEM_FINISH
    SUBI.B  #1, D5 ; check next mask bit
    BRA     EA_MOVEM_REG_TO_MEM_DEC

EA_INSERT_REG_TO_MEM_DEC:
    JSR     EA_INSERT_SLASH
    MOVE.W  D1, D3 ; move the reg num from D1
    MOVE.L  D5, D1
    EORI.B  #%1000,D1
    ASR.B   #3,D1
    MULU    #6,D1
    LEA     ADDRESS_MODE_TABLE, A0
    JSR     0(A0, D1)
    CMP     #0, D5 ; check if checking masking bit is finished
    BEQ     EA_MOVEM_FINISH
    SUBI.B  #1, D5 ; check next mask bit
    ADDI.B  #1, D6 ; counting for slash
    BRA     EA_MOVEM_REG_TO_MEM_DEC
    EA_MOVEM_SIZE:
   BTST    #6,D2
    BEQ     INSERT_SIZE_W_TO_BUFFER
    BRA     INSERT_SIZE_L_TO_BUFFER
   
EA_MOVEM_REG_TO_MEM_CHOOSE:
    MOVE.W  (A3),D1 ; check if it predecrement mode
    ANDI.W  #%0000000000111000, D1 ; check mode if mode 3 -(An)
    ASR.L   #3,D1 
    CMP     #4,D1
    BEQ     EA_MOVEM_REG_TO_MEM_DEC
; use bit test to check the masking
EA_MOVEM_REG_TO_MEM:
    MOVE.W  2(A3),D3 ; extracting masking bit
    MOVE.L  D5, D1 ; temp
    EORI.B  #%0000, D1 ; extracting reg num
    ANDI.B  #%0111, D1 ; filter reg num
    BTST    D5, D3    
    BNE     EA_INSERT_REG_TO_MEM
    CMP     #0, D5 ; check if checking masking bit is finished
    BEQ     EA_MOVEM_FINISH
    SUBI.B  #1, D5 ; check next mask bit
    BRA     EA_MOVEM_REG_TO_MEM

EA_INSERT_REG_TO_MEM:
    JSR     EA_INSERT_SLASH
    MOVE.W  D1, D3 ; move the reg num from D1
    MOVE.L  D5, D1
    EORI.B  #%0000,D1
    ASR.B   #3,D1
    MULU    #6,D1
    LEA     ADDRESS_MODE_TABLE, A0
    JSR     0(A0, D1)
    CMP     #0, D5 ; check if checking masking bit is finished
    BEQ     EA_MOVEM_FINISH
    SUBI.B  #1, D5 ; check next mask bit
    ADDI.B  #1, D6 ; counting for slash
    BRA     EA_MOVEM_REG_TO_MEM
    
EA_INSERT_SLASH:
    CMP.B   #0,D6
    BNE     PUT_SLASH
    RTS
    
PUT_SLASH:
    MOVE.B  #'/',(A2)+
    RTS

EA_MOVEM_MEM_TO_REG:
    MOVE.W  2(A3),D3 ; extracting masking bit
    MOVE.L  D5, D1 ; temp
    EORI.B  #%0000, D1 ; extracting reg num
    ANDI.B  #%0111, D1 ; filter reg num
    BTST    D5, D3    
    BNE     EA_INSERT_MEM_TO_REG
    CMP     #0, D5 ; check if checking masking bit is finished
    BEQ     FINISH_EA
    SUBI.B  #1, D5 ; check next mask bit
    BRA     EA_MOVEM_MEM_TO_REG
      
EA_INSERT_MEM_TO_REG:
    JSR     EA_INSERT_SLASH
    MOVE.L  D1, D3 ; move the reg num from D1
    MOVE.L  D5, D1
    EORI.B  #%0000,D1
    ASR.B   #3,D1
    MULU    #6,D1
    LEA     ADDRESS_MODE_TABLE, A0
    JSR     0(A0, D1)
    CMP     #0, D5 ; check if checking masking bit is finished
    BEQ     FINISH_EA
    ADDI.B  #1, D6 ; counting for slash
    SUBI.B  #1, D5 ; check next mask bit
    BRA     EA_MOVEM_MEM_TO_REG
      
EA_MOVEM_FINISH:
    MOVE.B  #',',(A2)+
    MOVE.B  #' ',(A2)+
    MOVE.W  (A3), D1
    ANDI.W  #%000000000111000,D1 ; mode 3 check (An)+ 
    ASR.W   #3,D1 ;
    CMP     #3,D1 ; checking invalid address mode
    BEQ     ERROR
    JSR     EA_SRC_AS_DST
    JMP     FINISH_EA
    
EA_MUL_DIV:
    ADDI    #2, D4 ; insturction word displacement
    MOVE.W  (A3),D1
    ANDI.W  #%0000000000111000,D1
    ASR.W   #3,D1
    CMP     #1,D1 ; Check Invalid Address Mode 
    BEQ     EA_ERROR   ; Invalid Address Mode An (001)
    MOVE.B  #$01,D2 ; Size is always Word only
    JSR     EA_CALCULATE_SRC
    MOVE.B  #',',(A2)+
    MOVE.B  #' ',(A2)+
    MOVE.B  #'D',(A2)+
    MOVE.W  (A3),D3 ; read the opcode for reg num
    ANDI.W  #%0000111000000000,D3 ; register number for data register
    MOVE.B  #9,D5
    ASR.W   D5,D3
    JSR     INSERT_REG_NUM
    JMP     FINISH_EA
      
EA_EXTRA:
    MOVE.W  (A3),D2
    MOVE.W  (A3),D5
    ADDI    #2,D4 ; insturction word displacement
    ANDI.W  #%0000000011000000,D2 extracting size to 
    ASR.W   #6,D2
    JSR     EA_SIZE_EXTRACT
    ANDI.W  #%0000000100000000,D5 ; check if the data register is src
    ASR.W   #8,D5 
    CMP     #0,D5 
    BEQ     EA_OPMODE_FIRST
    BRA     EA_OPMODE_SECOND
    
EA_OPMODE_FIRST:
    JSR     EA_CALCULATE_SRC
    MOVE.B  #',',(A2)+
    MOVE.B  #' ',(A2)+
    MOVE.B  #'D',(A2)+
    MOVE.W  (A3),D3
    ANDI.W  #%0000111000000000,D3
    MOVE.B  #9,D5
    ASR.W   D5,D3
    JSR     INSERT_REG_NUM
    JMP     FINISH_EA

EA_OPMODE_SECOND:
    MOVE.B  #'D',(A2)+
    ANDI.W  #%0000111000000000,D3
    MOVE.B  #9,D5
    ASR.W   D5,D3
    JSR     INSERT_REG_NUM
    MOVE.B  #',',(A2)+
    MOVE.B  #' ',(A2)+
    MOVE.W  (A3),D5 ; check if the mode i
    ANDI    #%0000000000111000,D5
    ASR.W   #3,D5
    CMP     #0,D5 ; check invalid address mode Data Register
    BEQ     EA_ERROR
    JSR     EA_SRC_AS_DST
    JMP     FINISH_EA

EA_MOVE:
    JSR     EA_MOVE_SIZE
    ADDI    #2,D4 ; instruction word displacement
    JSR     EA_CALCULATE_SRC
    MOVE.B  #',',(A2)+
    MOVE.B  #' ',(A2)+
    JSR     EA_CALCULATE_DST
    JMP     FINISH_EA

EA_MOVE_SIZE:
    MOVE.W  (A3),D2 ; move instruction to read size D2: size
    ANDI.W  #$3000,D2 ; extracting size part
    MOVE.W  #12,D5 ; shifting 15 times save at D5
    LSR.W   D5,D2
    CMP.B   #%01,D2
    BEQ     INSERT_SIZE_B_TO_BUFFER
    CMP.B   #%11,D2
    BEQ     INSERT_SIZE_W_TO_BUFFER
    CMP.B   #%10,D2
    BEQ     INSERT_SIZE_L_TO_BUFFER
    BRA     EA_ERROR  ; Throw Error here if size is 11 which is incorrect for this case
    
EA_MOVEA:
    JSR     EA_MOVEA_SIZE
    ADDI    #2,D4 ; instruction word displacement
    JSR     EA_CALCULATE_SRC
    MOVE.B  #',',(A2)+
    MOVE.B  #' ',(A2)+
    MOVE.B  #'A',(A2)+
    MOVE.W  (A3),D3 ; reg num for dst
    ANDI.W  #%0000111000000000,D3 ;Extracting Dest reg num
    MOVE.B  #9,D5 
    LSR.W   D5,D3 ; dst reg num
    JSR     INSERT_REG_NUM
    JMP     FINISH_EA
    
EA_MOVEA_SIZE:
    MOVE.W  (A3),D2 ; move instruction to read size D2: size
    ANDI.W  #$3000,D2 ; extracting size part
    MOVE.W  #12,D5 ; shifting 15 times save at D5
    LSR.W   D5,D2
    CMP.B   #%11,D2
    BEQ     INSERT_SIZE_W_TO_BUFFER
    CMP.B   #%10,D2
    BEQ     INSERT_SIZE_L_TO_BUFFER
    BRA     EA_ERROR  ; Throw Error here if size is 11 which is incorrect for this case
    
EA_LEA:
    MOVE.W  (A3), D1                  ; Move instruction to D1 for mode
    ANDI.W  #%0000000000111000,D1   ; get mode
    LSR.W   #$3, D1
    
    MOVE.W  (A3), D3                  ; Move instruction to D3 for reg
    ANDI.W  #%0000000000000111,D3   ; get reg
    
    CMP.B   #7, D1                  ; if src mode == 010 || 111
    BEQ     LEA_SUCCESS         
                                    ;   LEA_SUCCESS
    CMP.B   #2, D1
    BEQ     LEA_SUCCESS         
                                    ; else
    BRA     EA_ERROR                   ;   ERROR
        
LEA_SUCCESS:
    MOVE.W  (A3), D5                  ; CHECKING MODE 111'S REG EDGE CASE
    ANDI.W  #$000F, D5          
    CMP.B   #$A, D5                 ; IF REG is not 000 || 001
    BGE     EA_ERROR                   ;  ERROR
                                    ; ELSE
                          
    ADDI    #2,D4 ; instruction word displacement
    JSR     EA_SRC_AS_DST           ;  process
    
    MOVE.B  #',',(A2)+
    MOVE.B  #' ',(A2)+
    
    MOVE.W  (A3), D3                  ; Move instruction to D3 for reg
    ANDI.W  #%0000111000000000,D3   ; get reg
    MOVE.B  #$9, D5                 ; D5 Shift Counter = 9
    LSR.W   D5, D3
    
    JSR     MODE_001            

    JMP     FINISH_EA
    
EA_QUICK:
    MOVE.W  (A3),D2
    ANDI.W  #%0000000011000000,D2 ; extracting size for quick instruction
    LSR.W   #6,D2
    ADDI    #2,D4 ; instruction word displacement
    JSR     EA_SIZE_EXTRACT
    MOVE.B  #'#',(A2)+
    MOVE.B  #'$',(A2)+
    MOVE.W  (A3),D1 ; dst mode
    LSR.W   #2,D1
    CMP.B   #$F,D1 ; unsupported EA immediate addr mode
    BEQ     EA_ERROR
    MOVE.W  (A3),D3 ; calculate immediate data
    ANDI.W  #%0000111000000000,D3 ; filter data
    MOVE.B  #9,D5 ; save 9 to D5 to filter the data in 9th position 
    LSR.W   D5,D3 ; Data
    CMP     #0,D3 ; check if D3 is 0, then insert 8 
    BEQ     EA_QUICK_DATA ; check if D3 is 0, then insert 8
    JSR     INSERT_REG_NUM ; insert immediate 1-8
    MOVE.B  #' ',(A2)+
    MOVE.B  #',',(A2)+
    JSR     EA_CALCULATE_SRC ;
    JMP     FINISH_EA
    
EA_QUICK_DATA:
    MOVE.B  #8,D3
    JSR     INSERT_REG_NUM ; insert 8
    MOVE.B  #' ',(A2)+
    MOVE.B  #',',(A2)+
    JSR     EA_CALCULATE_SRC
    JMP     FINISH_EA
    
EA_BRANCH:
    ADDI    #2,D4
    MOVE.B  #'$',(A2)+
    MOVE.W  (A3), D3    ;   NEED TO CHECK [ANDI.W #$00FF]
    ANDI.W  #$FF, D3    ;   If 00 || FF 
    CMP.B   #$FF, D3    ; 
    BEQ     Bcc_Extend  ;       FF = Long
    CMP.B   #$00, D3    
    BEQ     Bcc_Extend  ;       00 = W
    MOVE.W  (A3), D5    ;   Special Case where it needs to move up
    ANDI.W  #%0000000010000000, D5  ;   8th bit 
    LSR.W   #7,D5   
    CMP.B   #1,D5               ; IF 8TH BIT == 1
    BEQ     EA_BRANCH_NEG 
    
    ;   else Byte size   
    ADDI.L  #$2, D3 ;      
    ADD.L   D7,  D3      ;
    MOVE    D3, (A5)      ;   D3 = PC + (DISPLACEMENT + 2)
    MOVE    #%01, D2 ; tell ITOA it is Word data
    JSR     START_ITOA
    JMP     FINISH_EA
   
    EA_BRANCH_NEG:
    ;   else Byte size, Move Up  
    EOR.B   #%11111111, D3  ; converting two's complement
    SUBI    #1, D3          ; converting two's complement       
    MOVE.L  D7, D5          ; Copy current PC to D5             
    SUB       D3, D5          ;  
    MOVE.L  D5, (A5)        ;   D5= PC - DISPLACEMENT - 2
    
    ; D2 = size 
    MOVE.W  #$3, D2     ; Update Size for ITOA
    JSR     START_ITOA
      
    JMP     FINISH_EA
   
Bcc_Extend:    
    MOVE.W  (A3), D2        ;   GET DATA SIZE
    ANDI.W  #%0000000000000111,D2   
    
    JSR     EA_Bcc_EXTENDED ; displacement calc done
    
    MOVE.W  (A5),D3 ; Copy negative displacement
    BTST    #%1000000000000000, D3
    BEQ     Bcc_Extend_NEG
    
    ADDI.L  #2,(A5) ; add word size 2 to D6 which is displacement
    ADD     D7,(A5)         ;   (A5 == DISPLACEMENT) += (PC + 2)
    JSR     START_ITOA
    JMP     FINISH_EA
    
Bcc_Extend_NEG:
    EOR.W   #%1111111111111111, D3  ; converting two's complement
    SUBI    #1, D3                  ; converting two's complement
    MOVE.L  D7, D5  ; Copy current PC to D5
    SUB       D3, D5   
    MOVE.W  D5, (A5)
    JSR     START_ITOA
    JMP     FINISH_EA    
        
EA_IMMEDIATE:
    MOVE.W  (A3),D2 ; copy insturction to D2 for process Data size
    ANDI.W  #$00C0,D2 ; extracting size part
    ROR.W   #6,D2 ; rotating D1 to calculate Size
    ADDI    #2,D4 ; instruction word displacement
    JSR     EA_SIZE_EXTRACT ; after this process D1 will have information about Data Size
    MOVE.B  #'#',(A2)+
    MOVE.B  #'$',(A2)+
    JSR     EA_EXTENDED ; to process immediate data
    JSR     ITOA
    ; generate dest EA address
    MOVE.B  #',',(A2)+
    MOVE.B  #' ',(A2)+
    JSR     EA_SRC_AS_DST
    JMP     FINISH_EA
    
EA_PUT_0AS8:
    MOVE.B  #8,D3
    JSR     INSERT_REG_NUM ; insert 8
    MOVE.B  #' ',(A2)+
    MOVE.B  #',',(A2)+
    JSR     EA_CALCULATE_SRC
    JMP     FINISH_EA
    
EA_SHIFT:
    MOVE.W  (A3), D5 ; Check if one or two operand
    ANDI.W  #%0000111011000000, D5
    LSR.W   #6,D5
    CMP     #3,D5
    BEQ     EA_SHIFT_ONE_OPERAND
    BRA     EA_SHIFT_TWO_OPERAND
    
EA_SHIFT_ONE_OPERAND:
    MOVE.W  (A3), D2 ; Check if it has invalid address mode Dn
    ANDI.W  #%0000000000111000,D2
    LSR.W   #3,D2
    CMP     #0,D2 ; if it is Dn
    BEQ     EA_ERROR ; throw error
    ADDI    #2,D4
    JSR     EA_SRC_AS_DST ; calculate destination 
    JMP     FINISH_EA 
   
EA_SHIFT_TWO_OPERAND:
    ADDI    #2,D4 ; instruction word displacement
    MOVE.W  (A3), D2 ; Check size D2
    ANDI.W  #%0000000011000000,D2 
    LSR.W   #6,D2
    MOVE.W  (A3), D1 ; Check the register num D3
    ANDI.W  #%0000000000000111, D1
    JSR     EA_SIZE_EXTRACT
    MOVE.W  (A3), D3 ; save count num at D3
    ANDI.W  #%0000111000000000, D3
    MOVE.B  #9,D5
    LSR.W   D5,D3
    MOVE.W  (A3), D5 ; Check if the first operand is Data register
    ANDI.W  #%0000000000100000, D5 
    LSR.W   #5,D5
    CMP     #1,D5
    BEQ     EA_SHIFT_INSERT_DATA_REG
    CMP     #0,D3
    BEQ     EA_SHIFT_PUT_0AS8
    MOVE.B  #'#',(A2)+
    MOVE.B  #'$',(A2)+
    JSR     INSERT_REG_NUM
    MOVE.B  #',',(A2)+
    MOVE.B  #' ',(A2)+
    MOVE.B  #'D',(A2)+
    MOVE.B  D1,D3
    JSR     INSERT_REG_NUM
    JMP     FINISH_EA
    
EA_SHIFT_INSERT_DATA_REG:
    MOVE.B  #'D',(A2)+
    JSR     INSERT_REG_NUM
    MOVE.B  #',',(A2)+
    MOVE.B  #' ',(A2)+
    MOVE.B  #'D',(A2)+
    MOVE.B  D1,D3
    JSR     INSERT_REG_NUM
    JMP     FINISH_EA
    
EA_SHIFT_PUT_0AS8:
    MOVE.B  #'#',(A2)+
    MOVE.B  #'$',(A2)+
    MOVE.B  #8,D3
    JSR     INSERT_REG_NUM
    MOVE.B  #',',(A2)+
    MOVE.B  #' ',(A2)+
    MOVE.B  #'D',(A2)+
    MOVE.B  D1,D3
    JSR     INSERT_REG_NUM
    JMP     FINISH_EA
    
INSERT_SIZE_B_TO_BUFFER:
    MOVE.B  #'.',(A2)+
    MOVE.B  #'B',(A2)+
    MOVE.B  #' ',(A2)+
    RTS
    
INSERT_SIZE_W_TO_BUFFER:
    MOVE.B  #'.',(A2)+
    MOVE.B  #'W',(A2)+
    MOVE.B  #' ',(A2)+
    RTS

INSERT_SIZE_L_TO_BUFFER:
    MOVE.B  #'.',(A2)+
    MOVE.B  #'L',(A2)+
    MOVE.B  #' ',(A2)+
    RTS
    
EA_SIZE_EXTRACT: ; extracting size for immediate data
    CMP.B   #%00,D2
    BEQ     INSERT_SIZE_B_TO_BUFFER
    CMP.B   #%01,D2
    BEQ     INSERT_SIZE_W_TO_BUFFER
    CMP.B   #%10,D2
    BEQ     INSERT_SIZE_L_TO_BUFFER
    BRA     EA_ERROR  ; Throw Error here if size is 11 which is incorrect for this case

EA_SRC_AS_DST:
    MOVE.W  (A3),D1 ; D1: save mode num
    MOVE.W  (A3),D3 ; D3: save reg num 
    MOVE.W  (A3),D5 ; D5: checking invalid address mode for mode 111
    LSR.L   #2,D5 ; extrating mode and reg num for checking invalid mode 111
    CMP.B   #$F,D5 ; not supported in this  Immedate data address mode 
    BEQ     FINISH_EA ; error -> Immediate data is not valid
    ANDI.W  #%0000000000111000, D1 ; Extracting Mode for Dest
    ANDI.W  #%0000000000000111, D3 ; Extracting Reg for Dest
    LSR.W   #3,D1 ; 
    CMP.B   #1,D1 ; filter invalid An address mode for op code 0000
    BEQ     EA_ERROR ; Error Throw error for invalid address mode
    MULU    #6,D1 ; For address mode jump table 
    LEA     ADDRESS_MODE_TABLE, A0
    JMP     0(A0,D1)

; Calculate source EA for general case
EA_CALCULATE_SRC:
    MOVE.W  (A3),D1 ; copy instruction to D1 to process src mode
    MOVE.W  (A3),D3 ; copy insturction to D3 to process reg num
    ANDI.W  #%0000000000111000, D1 ; Extracting Mode for Source
    ANDI.W  #%0000000000000111, D3 ; Extracting Src Num
    LSR.W   #3,D1 ; normalize src mode num
    MULU    #6,D1
    LEA     ADDRESS_MODE_TABLE, A0
    JMP     0(A0, D1)

; Calculate dest EA for general case
EA_CALCULATE_DST:
    MOVE.W  (A3),D1 ; copy instruction to D1 to process dst mode
    MOVE.W  (A3),D3 ; copy insturction to D3 to process reg num
    ANDI.W  #%0000111000000000, D3 ; Extracting Reg num for Destination
    ANDI.W  #%0000000111000000, D1 ; Extracting Mode for Destination
    MOVE.B  #9,D5
    LSR.W   D5,D3 ; normalize reg num
    LSR.W   #6,D1 ; normalize mode num
    MULU    #6,D1
    LEA     ADDRESS_MODE_TABLE, A0
    JMP     0(A0, D1)
  
INSERT_REG_NUM:
    ADD     #$30, D3 ; add hex 30 to convert D3 to ascii char
    MOVE.B  D3,(A2)+
    RTS
    
EA_EXTENDED:
    CMP.B     #%10,D2 ; check if it's word or long size immediate data
    BEQ       EA_LONG_DATA
    BRA       EA_WORD_DATA
    
EA_Bcc_EXTENDED:
    CMP.B     #$00,D2 ; check if it's word or long size 
    BEQ       EA_WORD_BCC
    BRA       EA_LONG_BCC
    
EA_WORD_BCC:
    MOVE.W   (A3,D4),D6 ; move A3 word and read word data
    ADDI      #2,D4 ; pc displacement = 2 
    MOVE.W   D6, (A5) ; Insert word data ; It has to be word data read here
    MOVE.B   #%01,D2 ; tell ITOA this is word data
    RTS ; return to EA Calculate
    
EA_LONG_BCC:
    MOVE.L   (A3,D4),D6 ; move A3 word and read long data
    ADDI      #4,D4 ; pc displacement = 4
    MOVE.L   D6, (A5) ; Insert long data
    MOVE.B   #%10,D2 ; tell ITOA this is word data
    RTS ; return to EA Calculate
    
    
EA_WORD_DATA:
    MOVE.W   (A3,D4),D6 ; move A3 word and read word data
    ADDI      #2,D4 ; pc displacement = 2 
    MOVE.W   D6, (A5) ; Insert word data ; It has to be word data read here
    RTS ; return to EA Calculate
    
EA_LONG_DATA:
    MOVE.L   (A3,D4),D6 ; move A3 word and read long data
    ADDI      #4,D4 ; pc displacement = 4
    MOVE.L   D6, (A5) ; Insert long data
    RTS ; return to EA Calculate
  
;------------------------ADDRESS MODE TABLE----------------------------------------------
  
ADDRESS_MODE_TABLE:
    JMP     MODE_000 ; Data Register Direct (mode 0)
    JMP     MODE_001 ; Address Register Direct (mode 1)
    JMP     MODE_010 ; Address Register Indirect (mode 2)
    JMP     MODE_011 ; Address Register Indirect with Post Increment (mode 3)
    JMP     MODE_100 ; Address Register Indirect with Pre Decrement (mode 4)
    JMP     MODE_101 ; Not Supported
    JMP     MODE_110 ; Not Supported
    JMP     MODE_111 ; Absolute Word/Long Address or Immediate Data (mode 7)
    
    
MODE_000:
    ; If there is an error, while calculating EA, then branch to Error handling and clear buffer and other variables.
    ; For the error case, consider what is next data to read.
    ; Do I have to check validity of Register Number?
    MOVE.B  #'D',(A2)+
    JSR     INSERT_REG_NUM ; add register number
    RTS
    
MODE_001:
    MOVE.B  #'A',(A2)+
    JSR     INSERT_REG_NUM ; add register number
    RTS ; I have to jump back on upper subroutin where this subrotuine gets called

MODE_010:
    
    MOVE.B  #'(',(A2)+
    MOVE.B  #'A',(A2)+
    JSR     INSERT_REG_NUM ; add register number
    MOVE.B  #')',(A2)+
    RTS
    
MODE_011:
    MOVE.B  #'(',(A2)+
    MOVE.B  #'A',(A2)+
    JSR     INSERT_REG_NUM ; add register number
    MOVE.B  #')',(A2)+
    MOVE.B  #'+',(A2)+
    RTS

MODE_100:
    MOVE.B  #'-',(A2)+
    MOVE.B  #'(',(A2)+
    MOVE.B  #'A',(A2)+
    JSR     INSERT_REG_NUM ; add register number
    MOVE.B  #')',(A2)+
    RTS
    
MODE_101:
    ; Not supported
    BRA     EA_ERROR

MODE_110:
    ; Not supported
    BRA     EA_ERROR

MODE_111:
    BRA     FILTER_SUB_MODE_111     
    RTS
;-----------------------------------------------------------------------------


;----FILTER MODE 111----------------------------------------------------

FILTER_SUB_MODE_111:
    CMP.B  #0,D3 ; Absolute Word Address
    BEQ    REG_000
    CMP.B  #1,D3 ; Absolute Long Address
    BEQ    REG_001
    CMP.B  #4,D3 ; Immediate Data
    BEQ    REG_100
    BRA    EA_ERROR ; If there is no match reg num

REG_000:
    MOVE.B  #'$',(A2)+
    MOVE.B  #%01,D2 ; Process Word Address in ITOA
    JSR     EA_EXTENDED
    JSR     ITOA
    RTS
    
REG_001:
    MOVE.B  #'$',(A2)+
    MOVE.B  #%10,D2 ; Process Long Address in ITOA
    JSR     EA_EXTENDED
    JSR     ITOA
    RTS
    
REG_100:
    MOVE.B  #'#',(A2)+
    MOVE.B  #'$',(A2)+
    JSR     EA_EXTENDED
    JSR     START_ITOA
    RTS
    
;----------------------------------------------------------------------------
    
;-------------------------------ITOA-----------------------------------------

; There is error in ITOA. If Long Immediate data has to be write in buffer, it doesn't work.

START_ITOA:
    CMP.B    #1,D0 ; check if the EA is MOVE
    BEQ      ITOA_MOVE
    CMP.B    #2,D0 ; check if the EA is MOVE
    BEQ      ITOA_MOVE
    BRA      ITOA
    
ITOA:
	MOVEM.L	    D0/D1/D7, -(SP)		; push EA_****	funtion's D1 (EA_TYPE)
	
	CMP.B	    #%00, D2		    ; BYTE
	BEQ	        ITOA_BYTE		
	CMP.B	    #%01, D2		    ; WORD
	BEQ	        ITOA_WORD	
	CMP.B	    #%10, D2		    ; LONG
	BEQ	        ITOA_LONG
	JMP	        ITOA_LONGADDR		; LONG ADDRESS

ITOA_MOVE:
	MOVEM.L	    D0/D1/D7, -(SP)		; push EA_**** (EA_TYPE)
	
	CMP.B	    #%01, D2		    ; BYTE
	BEQ	        ITOA_BYTE		
	CMP.B	    #%11, D2		    ; WORD
	BEQ	        ITOA_WORD	
	CMP.B	    #%10, D2		    ; LONG
	BEQ	        ITOA_LONG
	JMP	        ITOA_LONGADDR		; LONG ADDRESS

ITOA_BYTE:
	MOVE.W	    (A5)+, D7		    ; D7 = #A5++;
	JSR	        ITOA_BYTE_CONVERT	; itoa_lower (D7)
	JMP	        ITOA_DONE

ITOA_WORD:
	MOVE.W	    (A5), D7		    ; D7 = *A5;
	MOVE.B      #right8, D1		
	LSR.W	    D1, D7
	JSR	        ITOA_BYTE_CONVERT	; itoa_upper (D7)
	MOVE.W	    (A5)+, D7
	JSR	        ITOA_BYTE_CONVERT	; itoa_lower (D7)
	JMP	        ITOA_DONE

ITOA_LONG:
	MOVE.W	    (A5), D7		    ; D7 = *A5;
	MOVE.B	    #right8, D1
	LSR.W	    D1,D7
	JSR  ITOA_BYTE_CONVERT	; itoa_upper(D7)
	MOVE.W	    (A5)+, D7
	JSR 	    ITOA_BYTE_CONVERT	; itoa_lower(D7)
	
	MOVE.W      (A5), D7            ; D7 = *A5;
	MOVE.B      #right8, D1
	LSR.W       D1,D7
	JSR         ITOA_BYTE_CONVERT   ; itoa_upper (D7)
	MOVE.W      (A5)+, D7
	JSR         ITOA_BYTE_CONVERT   ; itoa_lower (D7)
	JMP         ITOA_DONE

ITOA_LONGADDR:
	MOVE.w	    (A5), D7			    ; D7= A5;
	MOVE.B	    #right24, D1
	LSR.W 	    D1, D7
	JSR	        ITOA_BYTE_CONVERT 	; itoa_upper (D7 >>24);
	MOVE.w      (A5)+, D7			    ; D7 = A5
	MOVE.B	    #right16,  D1
	LSR.W 	    D1, D7
	JSR	        ITOA_BYTE_CONVERT	; itoa_lower (D7 >> 16);
	MOVE.w	    (A5), D7			    ; D7 = A5
	MOVE.B	    #right8, D1
	LSR.W	    D1,D7
	JSR	        ITOA_BYTE_CONVERT	; itoa_upper (D7 >> 8);
	MOVE.w	    (A5)+, D7
	JSR	        ITOA_BYTE_CONVERT	; itoa_lower (D7);
	JMP	        ITOA_DONE

ITOA_BYTE_CONVERT:
	MOVE.W	    D7, D0
	ANDI.W	    #$F0, D0	        ; D0 = D0 & 0xF0
	MOVE.B	    #right4, D1
	LSR.W	    D1,D0		        ; D0 = D0 >> 0;
	JSR 	    ITOA_NIBBLE_CONVERT ; ITOA_CONVERT D0
	
	MOVE.W	    D7, D0
	ANDI.W      #$0F, D0		    ; D0 = D7 & 0x0F
	JSR	        ITOA_NIBBLE_CONVERT ; ITOA_CONVERT(D0)
    RTS
    
ITOA_NIBBLE_CONVERT:
	CMP.B	    #9, D0
	BGT	        ITOA_CONVERT_A2F
	ADD.B	    #$30, D0	        ; D0 += '0'
	MOVE.B	    D0, (A2)+	        ; PRINT D0 IN HEX TO *A2
	RTS
	
ITOA_CONVERT_A2F:
	SUBI.B	    #10, D0
	ADDI.B      #$41, D0
	MOVE.B	    D0, (A2)+
	RTS

ITOA_DONE:
	MOVEM.L	    (SP)+, D0/D1/D7 	    ; POP D1 (EA_TYPE)
	RTS

;----------------------------------------------------------
   
EA_ERROR:
    JMP     EXIT
    
FINISH_EA:
    ; testing address mode table jump
    ADD.L   D4, D7      ; add displacement for next instruction read 
    MOVE.L  D7, A3          
    CLR     D4
    MOVE.B  #0,(A2)+
    LEA     buffer,A1
    MOVE.B  #13,D0
    TRAP    #15
    RTS
    
*--------------------------------------------------------------------------        
* ERROR_HANDLER
*-------------------------------------------------------------------------- 
ERROR_HANDLER:  
    MULU        #6, D1              ; FOR JUMPING TO DESIGNATED ERROR MSG
    LEA         ERROR_TABLE, A0
    JMP         0(A0, D1)
    ;JMP         USER_INPUT         ; To the beginning
    ;RTS    
    JMP         WELCOME

ERROR_TABLE:
    JMP         ERROR_0     
    JMP         ERROR_1    
    JMP         ERROR_2    
    JMP         ERROR_3    
    JMP         ERROR_4    
    JMP         ERROR_5    
    JMP         ERROR_6    
    JMP         ERROR_7    
  

ERROR_0:
    MOVE        #13, D0         
    LEA         errorMsg_0, A1      ;Invalid start address
    RTS 

ERROR_1:
    MOVE        #13, D0
    LEA         errorMsg_1, A1      ; Invalid end address
    RTS

ERROR_2:
    MOVE        #13, D0
    LEA         errorMsg_2, A1      ;Invalid address range
    RTS

ERROR_3:
    MOVE        #13, D0
    LEA         errorMsg_3, A1      ; OP CODE NOT SUPPORTED
    RTS

ERROR_4:
    MOVE        #13, D0
    LEA         errorMsg_4, A1      ; INVALID OP CODE
    RTS

ERROR_5:
    MOVE        #13, D0
    LEA         errorMsg_5, A1      ; WRONG SIZE
    RTS

ERROR_6:
    MOVE        #13, D0
    LEA         errorMsg_6, A1      ; WRONG EA MODE/REGISTER
    RTS

ERROR_7:
    MOVE        #13, D0
    LEA         errorMsg_7, A1      ;UNKNOWN ERROR 
    RTS
*--------------------------------------------------------------------------        
* Variables
*--------------------------------------------------------------------------    


errorMsg_0      DC.B            'Invalid start address', CR,LF,$0
errorMsg_1      DC.B            'Invalid end address', CR,LF,$0
errorMsg_2      DC.B            'Invalid address range', CR,LF,$0
errorMsg_3      DC.B            'OP CODE NOT SUPPORTED', CR,LF,$0
errorMsg_4      DC.B            'INVALID OP CODE', CR,LF,$0
errorMsg_5      DC.B            'WRONG SIZE', CR,LF,$0
errorMsg_6      DC.B            'WRONG EA MODE/REGISTER', CR,LF,$0
errorMsg_7      DC.B            'UNKNOWN ERROR', CR,LF,$0

test_0000       DC.B            'code 0000', $0 
test_0001       DC.B            'code 0001', $0 
test_0010       DC.B            'code 0010', $0 
test_0011       DC.B            'code 0011', $0 
test_0100       DC.B            'code 0100', $0 
test_0101       DC.B            'code 0101', $0 
test_0110       DC.B            'code 0110', $0 
test_0111       DC.B            'code 0111', $0 
test_1000       DC.B            'code 1000', $0 
test_1001       DC.B            'code 1001', $0 
test_1010       DC.B            'code 1010', $0 
test_1011       DC.B            'code 1011', $0 
test_1100       DC.B            'code 1100', $0 
test_1101       DC.B            'code 1101', $0 
test_1110       DC.B            'code 1110', $0 
test_1111       DC.B            'code 1111', $0 

INPUT_START   DC.B    'Enter start address: ',CR,LF,0
INPUT_END     DC.B    'Enter end address: ',CR,LF,0
CONFIRM_MSG   DC.B    'Would you like to continue, type y for yes / type n for no', CR,LF,0
WARNING_MSG   DC.B    'Wrong Input, Please Type Again', CR,LF,0
ERROR_INPUT   DC.B    'Please check your input!',CR,LF,0
RESULT        DC.B    'Completed: ',CR,LF,0 
WELCOME_MSG   DC.B    'Welcome!',CR,LF,0

buffer  DS.B    bufsize ; buffer 

EXIT:  
END: 
    SIMHALT             ; halt simulator
    END    START        ; last line of source










*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
