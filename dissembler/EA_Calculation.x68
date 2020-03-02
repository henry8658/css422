*-----------------------------------------------------------
* Title      : EA_Calculator
* Written by : Henry Park
* Date       :
* Description: Calculating EA for given input
*-----------------------------------------------------------
example     EQU     %0011000000000000
bufsize     EQU     64 ; 64 characters can be stored in buffer
    ORG    $1000
START:                  ; first instruction of program
    
* Put program code here
; For EA calculation 
; Follwing Register was used

; D0: Current process insturction 
; D1: Address Mode / EA Type
; D2: Data Size
; D3: Used for Reg Num
; D5: Used for checking special condition
; D6: Used for value to give ITOA

EA_START:
    LEA     buffer,A2
    MOVE.W  #example,D0 ; save instruction in D0
    MOVE.W  #2,D1 ; Copy D0 to D1 for processing EA Type
    LEA     EA_TYPE_TABLE,A0
    MULU    #6,D1
    JMP     0(A0,D1) ; jump to ea table according to D1 value

EA_TYPE_TABLE:
    JMP     EA_IMMEDIATE 
    JMP     EA_MOVE
    JMP     EA_MOVEA
;    JMP     EA_LEA
;    JMP     EA_DST_ONLY
;    JMP     EA_EXT
;    JMP     EA_MOVEM
;    JMP     EA_TRAP
;    JMP     EA_QUICK ; ADDQ, SUBQ
;    JMP     EA_BRANCH

EA_MOVE:
    JSR     EA_MOVE_SIZE
    JSR     EA_CALCULATE_SRC
    MOVE.B  #',',(A2)+
    MOVE.B  #' ',(A2)+
    JSR     EA_CALCULATE_DST
    JMP     FINISH_EA

EA_MOVE_SIZE:
    MOVE.W  D0,D2 ; move instruction to read size D2: size
    ANDI.W  #$3000,D2 ; extracting size part
    MOVE.W  #12,D5 ; shifting 15 times save at D5
    LSR.W   D5,D2
    CMP.B   #%01,D2
    BEQ     INSERT_SIZE_B_TO_BUFFER
    CMP.B   #%11,D2
    BEQ     INSERT_SIZE_W_TO_BUFFER
    CMP.B   #%10,D2
    BEQ     INSERT_SIZE_L_TO_BUFFER
    BRA     ERROR  ; Throw Error here if size is 11 which is incorrect for this case
    
EA_MOVEA:
    JSR     EA_MOVEA_SIZE
    JSR     EA_CALCULATE_SRC
    MOVE.B  #',',(A2)+
    MOVE.B  #' ',(A2)+
    MOVE.B  #'A',(A2)+
    MOVE.W  D0,D3 ; reg num for dst
    ANDI.W  #%0000111000000000,D3 ;Extracting Dest reg num
    LSR.W   #8,D3 ; dst reg num
    MOVE.B  D3,D6 ; give reg num to ATOI to process
    MOVE.B  #00,D2 ; tell ITOA reg num size 
    ; ITOA
    JMP     FINISH_EA
    
EA_MOVEA_SIZE:
    MOVE.W  D0,D2 ; move instruction to read size D2: size
    ANDI.W  #$3000,D2 ; extracting size part
    MOVE.W  #12,D5 ; shifting 15 times save at D5
    LSR.W   D5,D2
    CMP.B   #%11,D2
    BEQ     INSERT_SIZE_W_TO_BUFFER
    CMP.B   #%10,D2
    BEQ     INSERT_SIZE_L_TO_BUFFER
    BRA     ERROR  ; Throw Error here if size is 11 which is incorrect for this case
    
EA_QUICK:
    MOVE.W  D0,D2
    ANDI.W  #%0000000011000000,D2 ; extracting size for quick instruction
    LSR.W   #6,D2
    JSR     EA_SIZE_EXTRACT
    MOVE.B  #'#',(A2)+
    MOVE.B  #'$',(A2)+
    MOVE.W  D0,D3 ; calculate immediate data
    ANDI.W  #%0000111000000000 ; filter data
    MOVE.B  #9,D5 ; save 9 to D5 to filter the data in 9th position 
    LSR.W   D5,D3 ; Data
    CMP     #0,D3 ; check if D3 is 0, then insert 8 
    BEQ     EA_QUICK_DATA ; check if D3 is 0, then insert 8
    MOVE.W  D0,D1 ; dst mode
    LSR.W   #2,D1
    CMP.B   #$F,D1 ; unsupported EA immediate addr mode
    BEQ     ERROR
    JSR     INSERT_REG_NUM ; insert immediate 1-8
    JSR     EA_CALCULATE_SRC
    JMP     FINISH_EA
    
EA_QUICK_DATA:
    

    
EA_IMMEDIATE:
    MOVE.W  D0,D2 ; copy insturction to D2 for process Data size
    ANDI.W  #$00C0,D2 ; extracting size part
    ROR.W   #6,D2 ; rotating D1 to calculate Size
    JSR EA_SIZE_EXTRACT ; after this process D1 will have information about Data Size
    ; generate immediate data
    MOVE.B  #'#',(A2)+
    MOVE.B  #'$',(A2)+
    ;JSR     ITOA
    ; generate dest EA address
    MOVE.B  #',',(A2)+
    MOVE.B  #' ',(A2)+
    JSR     EA_SRC_AS_DST
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
    BRA     ERROR  ; Throw Error here if size is 11 which is incorrect for this case

EA_SRC_AS_DST:
    MOVE.W  D0,D1 ; D0: save mode num
    MOVE.W  D0,D2 ; D2: save reg num 
    MOVE.W  D0,D5 ; D5: checking invalid address mode for mode 111
    LSR.L   #2,D5 ; extrating mode and reg num for checking invalid mode 111
    CMP.B   #$F,D5 ; not supported in this  Immedate data address mode 
    BEQ     FINISH_EA ; error -> Immediate data is not valid
    ANDI.W  #%0000000000111000, D1 ; Extracting Mode for Dest
    ANDI.W  #%0000000000000111, D2 ; Extracting Reg for Dest
    LSR.W   #6,D1 ; 
    CMP.B   #1,D1 ; filter invalid An address mode for op code 0000
    BEQ     FINISH_EA ; Error Throw error for invalid address mode
    LSR.W   #6,D2 ; D2: Reg num
    MULU    #6,D1 ; For address mode jump table 
    LEA     ADDRESS_MODE_TABLE, A0
    JMP     0(A0,D1)

; Calculate source EA for general case
EA_CALCULATE_SRC:
    MOVE.W  D0,D1 ; copy instruction to D1 to process src mode
    MOVE.W  D0,D3 ; copy insturction to D3 to process reg num
    ANDI.W  #%0000000000111000, D1 ; Extracting Mode for Source
    ANDI.W  #%0000000000000111, D3 ; Extracting Src Num
    LSR.W   #3,D1 ; normalize src mode num
    MULU    #6,D1
    LEA     ADDRESS_MODE_TABLE, A0
    JMP     0(A0, D1)

; Calculate dest EA for general case
EA_CALCULATE_DST:
    MOVE.W  D0,D1 ; copy instruction to D1 to process dst mode
    MOVE.W  D0,D3 ; copy insturction to D3 to process reg num
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
    BRA     ERROR

MODE_110:
    ; Not supported
    BRA     ERROR

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
    CMP.B  #3,D3 ; Immediate Data
    BEQ    REG_100
    BRA    ERROR ; If there is no match reg num

REG_000:
    MOVE.B  #'$',(A2)+
    ; ITOA insert word address
    RTS
    
REG_001:
    MOVE.B  #'$',(A2)+
    ; ITOA insert long address
    RTS
    
REG_100:
    MOVE.B  #'$',(A2)+
    MOVE.B  #'#',(A2)+
    ; ITOA insert immediate data
    RTS
    
;----------------------------------------------------------------------------
    
ERROR:
    JMP     END
    
FINISH_EA:
    ; testing address mode table jump
    MOVE.B  #0,(A2)+
    LEA     buffer,A1
    MOVE.B  #13,D0
    TRAP    #15
    
END:
    SIMHALT             ; halt simulator
* Put variables and constants here
buffer  DS.B    bufsize ; buffer 

    END    START        ; last line of source






*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~
