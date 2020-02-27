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
srcmode             EQU         $0038
dstmode_low2        EQU         $00C0 ; dest mode lower 2bits
srcmode_low2        EQU         $0018 ; source mode lower 2 bits
dstreg              EQU         $0E00 ; dest regs
srcreg              EQU         $0007 ; src regs

bufsize             EQU         64    ; decoded bufsize

SAMPLE_ADDR         EQU         $00000400


    ORG    $1000
    
START:                  ; first instruction of program
    
    
    LEA     $600, A5    ; Setting user input for start address as 600
    
    
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
*   }
*----------------------------------------------------------------------------   
OP_START:    
    ;MOVEM.L    D2/A6, -(SP)    ;  push D2(source_line#) and A6(end address)
    
    ; clear decoded_buf
    ;;JSR      OP_DATA_CLR
    LEA       decoded_buf, A2 ;  A2 will be pointing to decoded_buf (completely cleared)
    
    ; print the address
    ;; MOVE.L   #$0003, D2      ;  D2 = data size (011 = long address)
    ;;  JSR     ITOA            ;  A5 converts into ascii
    ;; MOVE.B   #$9, (A2)+      ;  address' ' 
     
    LEA     OP_TABLE, A0        ; A0, points OP_TABLE
    CLR.L   D0                  ; Clears D0
    MOVE.W  (A5)+, D0           ; Load the current instruction word to D0
    MOVE.L  D0, D1              ; D1 = D0 
    MOVE.B  #12, D2             ; D2 = 12
    LSR.W   D2, D1              ; get and save the OP code to D1
    MULU    #6, D1              ; compute the opcode jump displacement
    JMP     0(A0, D1)           ; jump to the opcode table entry
    
OP_FINISH:  
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
    ;JMP     code0100            ; CLR.bwl  /JMP    /JSR    /LEA    /MOVEM.wl/NOP   /NOT.bwl/RTS/STOP/TRAP   
    ;JMP     code0101            ; ADDQ.bwl / SUBQ.bwl  /Scc     /DBcc  
    ;JMP     code0110            ; BRA.bw   / BSR.bw    /Bcc.bw  
    ;JMP     code0111            ; MOVEQ   
    ;JMP     code1000            ; DIVS     / DIVU      /OR.bwl  
    ;JMP     code1001            ; SUB.bwl  /  SUBA.wl  
    ;JMP     code1010            ;   (--unassigned--)  
    ;JMP     code1011            ; CMP.bwl   /CMPA.wl    /EOR.bwl
    ;JMP     code1100            ; MULS      / MULU      /AND.bwl
    ;JMP     code1101            ; ADD.bwl   /  ADDA.wl  /ADDX.bwl     
    ;JMP     code1110            ; ASL.bwl   /   ASR.bwl / LSL.bwl / LSR.bwl /ROL.bwl / ROR.bwl  
    ;JMP     code1111            ;   (--unassigned--)
  
*----------------------------------------------------------------------------   

code0000:  
    MOVE.L  D0, D1              ; D1 = D0 (current instruction word)
    ANDI.W  #$0F00, D1              ; 2nd NIBBLE
    MOVE.B  #8, D2              ; D2 = 8
    LSR.W   D2, D1              ; get the 2nd nibble in D1
    MULU    $6, D1              ; compute the op_0000_table jump displacement
    LEA     OP_0000_TABLE, A0   ; A0 pointing OP_0000_Table
    JMP     0(A0, D1)
    
code0001:      
    ;BRA     OP_MOVE             ; Only Move      
     
code0010:
    MOVE.L  D0, D1              ; D1 = D0 (current instruction word)
    ANDI.W  #dstmode, D1        ; destination mode (Dn vs An)
    MOVE.B  #6, D2              ; D2 = 6
    LSR.W   D2, D1              ; get the 2nd nibble in D1
    CMP.B   #1, D1              ; if the 2nd nibble is 001
    BEQ     OP_MOVEA            ;     MOVEA.L
    BRA     OP_MOVE             ; else -> MOVE.L
    
code0011:
    MOVE.L  D0, D1              ; D1 = D0 (current instruction word)
    ANDI.W  #dstmode, D1              ; destination mode (Dn vs An)
    MOVE.B  #6, D2              ; D2 = 6
    LSR.W   D2, D1              ; get the 2nd nibble in D1
    CMP.B   #1, D1              ; if the 2nd nibble is 001
    BEQ     OP_MOVEA            ;     MOVEA.W
    BRA     OP_MOVE             ; else -> MOVE.W
    
   
*----------------------------------------------------------------------------   
OP_0000_TABLE:
    JMP     OP_ORI              ; 0: ORI
    JMP     OP_UNSUPPORTED      ; 1: not supported for BTST, BCHG, BCLR, BSET, MOVEP with Dn
    JMP     OP_ANDI             ; 2: ANDI
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
    JMP     OP_RA              ; 0: BRA
    JMP     OP_SR              ; 1: BSR
    ;JMP     OP_HI              ; 2: BNI, DBNI, SHI
    ;JMP     OP_LS              ; 3: BLS, DBLS, SLS
    JMP     OP_CC                   ; 4: BCC, DBCC, SCC
    ;JMP     OP_CS              ; 5: BCS, DBCS. SCS
    ;JMP     OP_NE              ; 6: BNE, DBNE, SNE
    ;JMP     OP_EQ              ; 7: BEQ, DBEQ, SEQ
    ;JMP     OP_VC              ; 8: BVC, DBVC, SVC
    ;JMP     OP_VS              ; 9: BVS, DBVS, SVS
    ;JMP     OP_PL              ; A: BPL, DBPL, SPL
    ;JMP     OP_HI              ; B: BMI, DBMI, SMI
    ;JMP     OP_GE              ; C: BGE, DBGE, SGE
    ;JMP     OP_LT              ; D: BLT, DBLT, SLT
    ;JMP     OP_GT              ; E: BGT, DBGT, SGT
    ;JMP     OP_LE              ; F: BLE, DBLE, SLE              

*----------------------------------------------------------------------------   

LEFT_SHIFT_TABLE:
    JMP     OP_ASL             ; ASL
    JMP     OP_LSL             ; LSL
    JMP     OP_ROXL            ; ROXL
    JMP     OP_ROL             ; ROL

*----------------------------------------------------------------------------   

RIGHT_SHIFT_TABLE:
    JMP     OP_ASL              ; ASR
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
    
OP_NOT:
    MOVE.B  #'N', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'T', (A2)+
    
OP_EXT_MOVEM:
    ; NEED LOGIC TO VERIFY BETWEEN EXT AND MOVEM
    
OP_TRAP:
    MOVE.B  #'T', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.B  #'A', (A2)+
    MOVE.B  #'P', (A2)+
    
OP_NOP_RTE_RTS_STOP:
    MOVE.L  D0,D1           ; D1 = D0 (current instruction word)
    ANDI.W  #nibble4, D1          ; extract the 4th nibble in D1
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
    
OP_JNRST:
                            ;(BGE OP_JMP_JSR)
OP_JSR:
    MOVE.B  #'J', (A2)+
    MOVE.B  #'S', (A2)+
    MOVE.B  #'R', (A2)+
    JMP     OP_FINISH
    
OP_JMP:
    MOVE.B  #'J', (A2)+
    MOVE.B  #'M', (A2)+
    MOVE.B  #'P', (A2)+
    JMP     OP_FINISH
    
OP_EXT:
   ;JMP OP_UNSUPPORTED
OP_MOVEM:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'E', (A2)+
    MOVE.B  #'M', (A2)+
    
OP_LEA:
    MOVE.B  #'L', (A2)+
    MOVE.B  #'E', (A2)+
    MOVE.B  #'A', (A2)+
    

*---- 0101 ------------------------------------------------------------------
OP_ADDQ_SUBQ:
    ; DETERMINE ADDQ OR SUBQ

OP_ADDQ:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'Q', (A2)+
    
OP_SUBQ:
    MOVE.B  #'S', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #'B', (A2)+
    MOVE.B  #'Q', (A2)+
    
*---- 0110 ------------------------------------------------------------------
OP_RA:
    MOVE.B  #'R', (A2)+
    MOVE.B  #'A', (A2)+
    
OP_SR:
    MOVE.B  #'S', (A2)+
    MOVE.B  #'R', (A2)+
    
OP_cc:
    MOVE.B  #'C', (A2)+
    MOVE.B  #'C', (A2)+
    
    
*---- 0111 ------------------------------------------------------------------
OP_MOVEQ:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'E', (A2)+
    MOVE.B  #'Q', (A2)+
    

*---- 1000 ------------------------------------------------------------------
OP_DIVU:
    MOVE.B  #'D', (A2)+
    MOVE.B  #'I', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'U', (A2)+
    
OP_DIVS:
    MOVE.B  #'D', (A2)+
    MOVE.B  #'I', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'S', (A2)+
    
    
OP_OR:
    MOVE.B  #'O', (A2)+
    MOVE.B  #'R', (A2)+
    

*---- 1001 ------------------------------------------------------------------
OP_SUB:
    MOVE.B  #'S', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #'B', (A2)+
    

*---- 1011 ------------------------------------------------------------------
OP_EOR:
    MOVE.B  #'E', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'R', (A2)+
    
OP_CMP:
    MOVE.B  #'C', (A2)+
    MOVE.B  #'M', (A2)+
    MOVE.B  #'P', (A2)+
    

*---- 1100 ------------------------------------------------------------------
OP_MULU:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #'L', (A2)+
    MOVE.B  #'U', (A2)+
    
OP_MULS:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #'L', (A2)+
    MOVE.B  #'S', (A2)+
    
OP_AND:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'N', (A2)+
    MOVE.B  #'D', (A2)+

*---- 1101 ------------------------------------------------------------------
OP_ADD:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'D', (A2)+
    
OP_ADDA:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'A', (A2)+
    

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
    ;MOVE.L  #3, D1         ; Error Code #3
    ;JSR     ERROR_HANLDER
    ;JMP     OP_FINISH

OP_INVALID:
    ;MOVE.L #4, D1          ; Error Code #4
    ;JSR    ERROR_HANDLER
    ;JMP   OP_FINISH

    
* Put program code here

    SIMHALT             ; halt simulator

* Put variables and constants here
    
decoded_buf      DS.B        bufsize    
    
    END    START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
