*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
START_ADDRESS       EQU         $300 ; start address
END_ADDRESS         EQU         $308 ; end address
CR                  EQU         $0D ; Carrige return
LF                  EQU         $0A ; Linefeed
nibble2             EQU         $0F00
nibble3             EQU         $00F0
nibble4             EQU         $000F
dstmode             EQU         $10CA
dstmode_Bi                      EQU                 %0000000111000000   
srcmode             EQU         $0038
srcmode_Bi                      EQU                 %0000000000111000   
dstmode_low2        EQU         %0000000011000000 ; dest mode lower 2bits
srcmode_low2        EQU         %0000000000011000 ; source mode lower 2 bits
dstreg              EQU         $0E00 ; dest regs
srcreg              EQU         $0007 ; src regs

bufsize     EQU     64 ; 64 characters can be stored in buffer
right3      EQU 3
right4      EQU 4
right8      EQU 8
right16     EQU 16
right24     EQU 24

SAMPLE_ADDR         EQU         $00000400


    ORG    $1000
    
START:                  ; first instruction of program
    LEA     buffer,A2
    
    MOVE.L  #$E1798102,(A3) ; load test example instruction If you want to test, change this value
    MOVE.W  #$7890, 4(A3)
    

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
    ;MOVEM.L    D2/A6, -(SP)    ;  push D2(source_line#) and A6(end address)
    
    ; clear decoded_buf
    ;;JSR      OP_DATA_CLR
    ;;LEA       decoded_buf, A2 ;  A2 will be pointing to decoded_buf (completely cleared)
    
    ; print the address
    ;; MOVE.L   #$0003, D2      ;  D2 = data size (011 = long address)
    ;;  JSR     ITOA            ;  A5 converts into ascii
    ;; MOVE.B   #$9, (A2)+      ;  address' ' 
     
    LEA     OP_TABLE, A0        ; A0, points OP_TABLE
    CLR.L   D0                  ; Clears D0
    MOVE.W  (A3)+, D0           ; Load the current instruction word to D0
    MOVE.L  D0, D1              ; D1 = D0 
    MOVE.B  #12, D2             ; D2 = 12
    LSR.W   D2, D1              ; get and save the OP code to D1
    MULU    #6, D1              ; compute the opcode jump displacement
    JMP     0(A0, D1)           ; jump to the opcode table entry
    
OP_FINISH: 
    MOVE.B  #0,(A2)+
    LEA     buffer,A1
    MOVE.B  #13,D0
    TRAP    #15
    
    JMP     EXIT
    ;MOVEM.L    (SP)+, D2/A6,    ; pop D2(source line # ) and A6 (end address)
    ;RTS                        ; return to the main
    
*----------------------------------------------------------------------------   

OP_DATA_CLR:
    ;CLR.L  D3
    ;MOVE.B     #bufsize,   D3                     ; Buffsize = 64, and D3 as counter
    ;LEA        decoded_buf,    A2             ; for (int D3 = 64; D3 >0; D3--)
    
OP_DATA_CLR_LOOP:
    ;MOVE.B     #0, (A2)+       ; (A2)++     = $0
    ;SUBI       #1, D3  
    ;BGT        OP_DATA_CLR_LOOP
    ;RTS
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
    MOVE.L  #ea_bcc_flag,   D5  ; the flag in ea_type_branch
    
    MOVE.L  D0, D1              ; D1 = D0 (cur instruction word)
    ANDI.W  #$0F00, D1          ; get 2nd nibble in to D1     
    MOVE.B  #8, D2              ; D2 Shift Counter = 8
    LSR.W   D2,D1               ; move 2nd nibble to the last nibble
    MULU    #6, D1              
    LEA     OP_COND_TABLE, A0   ;  A0 points OP_COND_TABLE
    JMP     0(A0,D1)            ; jump to designated OP CODE
    
code0111:
    ;   MOVEQ   
    
    MOVE.B  #13, D0             ;task#13
    LEA     test_0111, A1
    TRAP    #15
    
    JMP     OP_MOVEQ            ;0111 only indicates MOVEQ
    
code1000:
    ;   DIVS     / DIVU      /OR.bwl

    ;MOVE.B  #13, D0             ;TASK 13
    ;LEA     test_1000, A1
    ;TRAP    #15
    
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
    
    ;MOVE.B  #13, D0             ;task #13
    ;LEA     test_1001,A1    
    ;TRAP    #15
    
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
    
    JMP     OP_INVALID
    
code1011:
    ;   CMP.bwl   / Not Supporting (CMPA.wl)    /EOR.bwl

    ;MOVE.B  #13, D0
    ;LEA     test_1011, A1
    ;TRAP    #15
    
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
    BLE     OP_EOR              ;   if srcmode <= 3
    JMP     OP_INVALID          ;       EOR
                                ;   else INVALID
    
code1100:
    ;   MULS      / MULU      /AND.bwl

    ;MOVE.B  #13, D0             ;task #13
    ;LEA     test_1100, A1
    ;TRAP    #15
    
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
    
    ;MOVE.B  #13, D0             ;task #13
    ;LEA     test_1101, A1
    ;TRAP    #15
    
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

    ;MOVE.B  #13, D0             ;task #13
    ;LEA     test_1110, A1
    ;TRAP    #15 
    
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
    ANDI.W  #5, D4              ;   bit 5
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
    CMP.B   #1,  D4
    BEQ     DIR_LEFT
    JMP     DIR_RIGHT

code1111:
    ;   (--unassigned--)
    
    MOVE.B  #13, D0             ;task #13
    LEA     test_1110, A1
    TRAP    #15 
    
    JMP     OP_INVALID
    
*----------------------------------------------------------------------------   
OP_0000_TABLE:
    JMP     OP_ORI              ; 0: ORI
    JMP     OP_UNSUPPORTED      ; 1: not supported for BTST, BCHG, BCLR, BSET, MOVEP with Dn
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
    JMP     OP_NOT              ; 6: NOT
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
    JMP     OP_HI               ; 2: BNI, DBNI, SHI
    JMP     OP_LS               ; 3: BLS, DBLS, SLS
    JMP     OP_CC               ; 4: BCC, DBCC, SCC
    JMP     OP_CS               ; 5: BCS, DBCS. SCS
    JMP     OP_NE               ; 6: BNE, DBNE, SNE
    JMP     OP_EQ               ; 7: BEQ, DBEQ, SEQ
    JMP     OP_VC               ; 8: BVC, DBVC, SVC
    JMP     OP_VS               ; 9: BVS, DBVS, SVS
    JMP     OP_PL               ; A: BPL, DBPL, SPL
    JMP     OP_MI               ; B: BMI, DBMI, SMI
    JMP     OP_GE               ; C: BGE, DBGE, SGE
    JMP     OP_LT               ; D: BLT, DBLT, SLT
    JMP     OP_GT               ; E: BGT, DBGT, SGT
    JMP     OP_LE               ; F: BLE, DBLE, SLE              

*----------------------------------------------------------------------------   

LEFT_SHIFT_TABLE:
    JMP     OP_ASL             ; ASL
    JMP     OP_LSL             ; LSL
    JMP     OP_ROXL            ; ROXL
    JMP     OP_ROL             ; ROL

*----------------------------------------------------------------------------   

RIGHT_SHIFT_TABLE:
    JMP     OP_ASR              ; ASR
    JMP     OP_LSR              ; LSR
    JMP     OP_ROXR             ; ROXR
    JMP     OP_ROR              ; ROR

*----------------------------------------------------------------------------   

; enter OP names in the buffer
*---- 0000 ------------------------------------------------------------------
OP_ORI:
    MOVE.B  #'O', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.B  #'I', (A2)+
    ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
OP_ANDI:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'N', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'I', (A2)+
    ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
OP_SUBI:
    MOVE.B  #'S', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #'B', (A2)+
    MOVE.B  #'I', (A2)+
    ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
OP_ADDI:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'I', (A2)+
    ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH   
    
OP_EORI:
    MOVE.B  #'E', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.B  #'I', (A2)+
    ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
OP_CMPI:
    MOVE.B  #'C', (A2)+
    MOVE.B  #'M', (A2)+
    MOVE.B  #'P', (A2)+
    MOVE.B  #'I', (A2)+
    ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
*---- 0001, 0011, 0010 ------------------------------------------------------
OP_MOVE:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'E', (A2)+
    ;JSR     EA_START
    JMP     OP_FINISH
    
OP_MOVEA:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'E', (A2)+
    MOVE.B  #'A', (A2)+
    ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH

*---- 0100 ------------------------------------------------------------------
OP_CLR:
    MOVE.B  #'C', (A2)+
    MOVE.B  #'L', (A2)+
    MOVE.B  #'R', (A2)+
    ;JSR     EA_START
    JMP     OP_FINISH

OP_NOT:
    MOVE.B  #'N', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'T', (A2)+
    ;JSR     EA_START
    JMP     OP_FINISH
    
OP_TRAP:
    MOVE.B  #'T', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.B  #'A', (A2)+
    MOVE.B  #'P', (A2)+
    ;JSR     EA_START
    JMP     OP_FINISH
    
* ??? ??? ?? -- 2/29/2020
    
OP_JNRST:               ;   (BGE OP_JMP_JSR)
    
    
    MOVE.W  D0, D1      ;   get instruction again
    ANDI.W  #$00F0, D1      ;   get 3rd nibble                               
    MOVE.B  #4, D2      ;   D2 as counter for shifting right D1
    LSR.W   D2, D1      ;   Checking the Nibble
    CMP.B   #4, D1      ;   if 3rd NIbble == 4
    BEQ     OP_TRAP     ;       TRAP       
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
    ;JSR     EA_START    
    JMP     OP_FINISH
    
OP_JMP:
    MOVE.B  #'J', (A2)+
    MOVE.B  #'M', (A2)+
    MOVE.B  #'P', (A2)+
    ;JSR     EA_START
    JMP     OP_FINISH    

    
OP_NOP_RTE_RTS_STOP:
    MOVE.L  D0,D1           ; D1 = D0 (current instruction word)
    ANDI.W  #$000F, D1          ; extract the 4th nibble in D1
    CMP.B   #$1, D1         ; if nibble4 == 0001   
    BEQ     OP_NOP
    CMP.B   #$2, D1         ; else if nibble4 == 0010
    BEQ     OP_STOP
    CMP.B   #$3, D1         ;else if nibble4 == 0011
    BEQ     OP_RTE
    CMP.B   #$5, D1         ; else if nibble4 ==  0101
    BEQ     OP_RTS
    JMP     OP_INVALID
    
OP_NOP:
    MOVE.B  #'N', (A2)+    
    MOVE.B  #'O', (A2)+
    MOVE.B  #'P', (A2)+
    JMP     OP_FINISH
      
OP_STOP:
    MOVE.B  #'S', (A2)+
    MOVE.B  #'T', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'P', (A2)+
    JMP     OP_FINISH
    
OP_RTE:
    MOVE.B  #'R', (A2)+
    MOVE.B  #'T', (A2)+
    MOVE.B  #'E', (A2)+
    JMP     OP_FINISH
    
OP_RTS:
    MOVE.B  #'R', (A2)+
    MOVE.B  #'T', (A2)+
    MOVE.B  #'S', (A2)+
    JMP     OP_FINISH
    
OP_EXT_MOVEM:
    MOVE.L  D0, D1          ; get current instruction into D1
    ANDI.W  #srcmode, D1    ; D1 Sourc mode into D1
    MOVE.B  #right3, d2     ; D2 Shift Counter = 3 
    LSR.W   D2, D1          
    CMP.B   #0, D1          ; if source Mode == 000
    BEQ     OP_EXT          ;   OP_EXT
    BRA     OP_MOVEM        ; else -> MOVEM 
 
OP_EXT:
    MOVE.B  #'E', (A2)+
    MOVE.B  #'X', (A2)+
    MOVE.B  #'T', (A2)+
    ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
OP_MOVEM:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'E', (A2)+
    MOVE.B  #'M', (A2)+
    ;JSR     EA_START
        ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
OP_LEA:
    MOVE.B  #'L', (A2)+
    MOVE.B  #'E', (A2)+
    MOVE.B  #'A', (A2)+
        ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
*---- 0101 ------------------------------------------------------------------
*----------------------------------------------------------------------------   
    ; 2/28/2020 2:17 PM
    ; - Testing OP_SUBQ_ADDQ - check
*---------------------------------------------------------------------------- 
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
       ;JMP EA_START
           ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
OP_SUBQ:
    MOVE.B  #'S', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #'B', (A2)+
    MOVE.B  #'Q', (A2)+
       ;JMP EA_START
           ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
       
*---- 0110 ------------------------------------------------------------------
ea_bcc_flag:
    ;   NEED Bcc calculation
    ;   Find the pattern,
    ;   CMP and let it jump to designated OP CODE

OP_RA:
    MOVE.B  #'R', (A2)+
    MOVE.B  #'A', (A2)+
    JMP OP_FINISH
        ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
OP_SR:
    MOVE.B  #'S', (A2)+
    MOVE.B  #'R', (A2)+
    JMP OP_FINISH
        ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
OP_HI:
    MOVE.B  #'H',   (A2)+
    MOVE.B  #'I',   (A2)+
    JMP OP_FINISH
        ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
OP_LS:
    MOVE.B  #'L',   (A2)+
    MOVE.B  #'S',   (A2)+  
    JMP OP_FINISH
        ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
OP_CC:
    MOVE.B  #'C', (A2)+
    MOVE.B  #'C', (A2)+
    JMP OP_FINISH
    ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
OP_CS:
    MOVE.B  #'C',   (A2)+
    MOVE.B  #'S',   (A2)+  
    JMP OP_FINISH
    ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
OP_NE:
    MOVE.B  #'N',   (A2)+
    MOVE.B  #'E',   (A2)+  
    JMP OP_FINISH
    ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
OP_EQ:
    MOVE.B  #'E',   (A2)+
    MOVE.B  #'Q',   (A2)+     
    JMP OP_FINISH
    ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
 
OP_VC:
    MOVE.B  #'V',   (A2)+
    MOVE.B  #'C',   (A2)+  
    JMP OP_FINISH
    ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
OP_VS:
    MOVE.B  #'V',   (A2)+
    MOVE.B  #'S',   (A2)+    
    JMP OP_FINISH
    ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
OP_PL:
    MOVE.B  #'P',   (A2)+
    MOVE.B  #'L',   (A2)+   
        JMP OP_FINISH
    ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
OP_MI:
        MOVE.B      #'M',   (A2)+   
        MOVE.B      #'I',   (A2)+       
    JMP OP_FINISH
    ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
OP_GE:
    MOVE.B  #'G',   (A2)+
    MOVE.B  #'E',   (A2)+  
    JMP OP_FINISH
    ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
OP_LT:
    MOVE.B  #'L',   (A2)+
    MOVE.B  #'T',   (A2)+      
    JMP OP_FINISH
    ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
OP_GT:
    MOVE.B  #'G',   (A2)+
    MOVE.B  #'T',   (A2)+  
    JMP OP_FINISH
    ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
OP_LE:
    MOVE.B  #'L',   (A2)+
    MOVE.B  #'E',   (A2)+  
    JMP OP_FINISH
    ; Load immediate type
    ;JSR     EA_START
    JMP     OP_FINISH
    
*---- 0111 ------------------------------------------------------------------
OP_MOVEQ:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'E', (A2)+
    MOVE.B  #'Q', (A2)+
    ;JSR     EA_START
     JMP OP_FINISH


*---- 1000 ------------------------------------------------------------------
OP_DIVU:
    MOVE.B  #'D', (A2)+
    MOVE.B  #'I', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'U', (A2)+
        ;JSR     EA_START
     JMP OP_FINISH
OP_DIVS:
    MOVE.B  #'D', (A2)+
    MOVE.B  #'I', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'S', (A2)+
        ;JSR     EA_START
     JMP OP_FINISH
    
OP_OR:
    MOVE.B  #'O', (A2)+
    MOVE.B  #'R', (A2)+
    ;JSR     EA_START
     JMP OP_FINISH    

*---- 1001 ------------------------------------------------------------------
OP_SUB:
    MOVE.B  #'S', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #'B', (A2)+
    ;JSR     EA_START
     JMP OP_FINISH    

*---- 1011 ------------------------------------------------------------------
OP_EOR:
    MOVE.B  #'E', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'R', (A2)+
    ;JSR     EA_START
     JMP OP_FINISH  
  
OP_CMP:
    MOVE.B  #'C', (A2)+
    MOVE.B  #'M', (A2)+
    MOVE.B  #'P', (A2)+
    ;JSR     EA_START
     JMP OP_FINISH    

*---- 1100 ------------------------------------------------------------------
OP_MULU:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #'L', (A2)+
    MOVE.B  #'U', (A2)+
    ;JSR     EA_START
     JMP OP_FINISH
    
OP_MULS:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #'L', (A2)+
    MOVE.B  #'S', (A2)+
    ;JSR     EA_START
     JMP OP_FINISH
    
OP_AND:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'N', (A2)+
    MOVE.B  #'D', (A2)+
    ;JSR     EA_START
     JMP OP_FINISH
     
*---- 1101 ------------------------------------------------------------------
OP_ADD:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'D', (A2)+
    ;JSR     EA_START
     JMP OP_FINISH
    
OP_ADDA:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'A', (A2)+
    ;JSR     EA_START
     JMP OP_FINISH
    

*---- 1110 ------------------------------------------------------------------
OP_ASL:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'S', (A2)+
    MOVE.B  #'L', (A2)+
    JMP     OP_FINISH
    
OP_ASR:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'S', (A2)+
    MOVE.B  #'R', (A2)+
    JMP     OP_FINISH
    
OP_LSL:
    MOVE.B  #'L', (A2)+
    MOVE.B  #'S', (A2)+
    MOVE.B  #'L', (A2)+
    JMP     OP_FINISH
    
OP_LSR:
    MOVE.B  #'L', (A2)+
    MOVE.B  #'S', (A2)+
    MOVE.B  #'R', (A2)+
    JMP     OP_FINISH

OP_ROXL:
    MOVE.B  #'R', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'X', (A2)+
    MOVE.B  #'L', (A2)+
    JMP     OP_FINISH  
    
OP_ROXR:
    MOVE.B  #'R', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'X', (A2)+
    MOVE.B  #'R', (A2)+
    JMP     OP_FINISH      
    
OP_ROL:
    MOVE.B  #'R', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'L', (A2)+
    JMP     OP_FINISH
    
OP_ROR:
    MOVE.B  #'R', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'R', (A2)+
    JMP     OP_FINISH
    
*--------------------------------------------------------------------------    
OP_UNSUPPORTED:
    MOVE.L  #3, D1         ; Error Code #3
    JSR     ERROR_HANDLER
    JMP     OP_FINISH

OP_INVALID:
    MOVE.L #4, D1          ; Error Code #4
    JSR    ERROR_HANDLER
    JMP   OP_FINISH


*--------------------------------------------------------------------------        
* ERROR_HANDLER
*-------------------------------------------------------------------------- 
ERROR_HANDLER:  
    MULU        #6, D1              ; FOR JUMPING TO DESIGNATED ERROR MSG
    LEA         ERROR_TABLE, A0
    JMP         0(A0, D1)
    ;JMP         USER_INPUT         ; To the beginning
    ;RTS    
    
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


errorMsg_0      DC.B            'Invalid start address', $0
errorMsg_1      DC.B            'Invalid end address', $0
errorMsg_2      DC.B            'Invalid address range', $0
errorMsg_3      DC.B            'OP CODE NOT SUPPORTED', $0
errorMsg_4      DC.B            'INVALID OP CODE', $0
errorMsg_5      DC.B            'WRONG SIZE', $0
errorMsg_6      DC.B            'WRONG EA MODE/REGISTER', $0
errorMsg_7      DC.B            'UNKNOWN ERROR', $0


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

buffer  DS.B    bufsize ; buffer 

EXIT:   
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
