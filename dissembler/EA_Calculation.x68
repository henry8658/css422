*-----------------------------------------------------------
* Title      : EA_Calculator
* Written by : Henry Park
* Date       :
* Description: Calculating EA for given input
*-----------------------------------------------------------
example     EQU     %0000000001000000
bufsize     EQU     64 ; 64 characters can be stored in buffer
    ORG    $1000
START:                  ; first instruction of program
    
* Put program code here

EA_START:
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
;    JMP     EA_QUICK
;    JMP     EA_BRANCH

EA_MOVE:
    MOVE.W  #example,D1  
    JSR     EA_MOVE_SIZE
    JSR     EA_CALCULATE_SRC
    MOVE.B  #' ',(A2)+
    JSR     EA_CALCULATE_DST
    JMP     FINISH_EA

EA_MOVE_SIZE:
    ANDI.W  #$00C0,D1 ; extracting size part
    ROR.W   #6,D1 ; rotating D1 to calculate Size
    CMP.B   #%00,D1
    BEQ     INSERT_SIZE_B_TO_BUFFER
    CMP.B   #%01,D1
    BEQ     INSERT_SIZE_W_TO_BUFFER
    CMP.B   #%10,D1
    BEQ     INSERT_SIZE_L_TO_BUFFER
    BRA     ERROR  ; Throw Error here if size is 11 which is incorrect for this case
    
EA_MOVEA:


EA_MOVEA_SIZE:

EA_IMMEDIATE:
    MOVE.W  #example,D1
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
    ANDI.W  #$00C0,D1 ; extracting size part
    ROR.W   #6,D1 ; rotating D1 to calculate Size
    CMP.B   #%00,D1
    BEQ     INSERT_SIZE_B_TO_BUFFER
    CMP.B   #%01,D1
    BEQ     INSERT_SIZE_W_TO_BUFFER
    CMP.B   #%10,D1
    BEQ     INSERT_SIZE_L_TO_BUFFER
    BRA     ERROR  ; Throw Error here if size is 11 which is incorrect for this case

EA_SRC_AS_DST:
    MOVE.L  #example,D0 ; D0: save mode num
    MOVE.L  #example,D2 ; D2: save reg num 
    MOVE.L  #example,D6 ; D6: checking invalid address mode for mode 111
    LSR.L   #2,D6 ; extrating mode and reg num for checking invalid mode 111
    CMP.B   #$F,D6 ; not supported in this  Immedate data address mode 
    BEQ     FINISH_EA ; error -> Immediate data is not valid
    ANDI.W  #%0000000000111000, D0 ; Extracting Mode for Dest
    ANDI.W  #%0000000000000111, D2 ; Extracting Reg for Dest
    LSR.W   #6,D0 ; 
    CMP.B   #1,D0 ; filter invalid An address mode for op code 0000
    BEQ     FINISH_EA ; Error Throw error for invalid address mode
    LSR.W   #6,D2 ; D2: Reg num
    MULU    #6,D0 ; For address mode jump table 
    LEA     ADDRESS_MODE_TABLE, A0
    JMP     0(A0,D0)

EA_CALCULATE_SRC:

EA_CALCULATE_DST:
    MOVE.L  #example,D0

    ANDI.W  #%0000000111000000, D0 ; Extracting Mode for Destination
    LSR.W   #6,D0
    MULU    #6,D0
    LEA     ADDRESS_MODE_TABLE, A0
    JMP     0(A0, D0)
  
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
    MOVE.B  #00,D4 ; Tell ITOA to process Byte size data
    ; ITOA ; ITOA will insert Reg num , ITOA will insert D2 value in Buffer
    RTS
    
MODE_001:
    MOVE.B  #'A',(A2)+
    MOVE.B  #00,D4 ; Tell ITOA to process Byte size data
    ; ITOA ; ITOA will insert Reg num , ITOA will insert D2 value in Buffer
    RTS ; I have to jump back on upper subroutin where this subrotuine gets called

MODE_010:    
    MOVE.B  #'(',(A2)+
    MOVE.B  #'A',(A2)+
    MOVE.B  #00,D4 ; Tell ITOA to process Byte size data
    ; ITOA ; ITOA will insert Reg num , ITOA will insert D2 value in Buffer
    MOVE.B  #')',(A2)+
    RTS
    
MODE_011:
    MOVE.B  #'(',(A2)+
    MOVE.B  #'A',(A2)+
    MOVE.B  #00,D4 ; Tell ITOA to process Byte size data
    ; ITOA ; ITOA will insert Reg num , ITOA will insert D2 value in Buffer
    MOVE.B  #')',(A2)+
    MOVE.B  #'+',(A2)+
    RTS

MODE_100:
    MOVE.B  #'-',(A2)+
    MOVE.B  #'(',(A2)+
    MOVE.B  #'A',(A2)+
    MOVE.B  #00,D4 ; Tell ITOA to process Byte size data
    ; ITOA ; ITOA will insert Reg num , ITOA will insert D2 value in Buffer
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
       CMP.B  #0,D2 ; Absolute Word Address
    BEQ    REG_000
    CMP.B  #1,D2 ; Absolute Long Address
    BEQ    REG_001
    CMP.B  #3,D2 ; Immediate Data
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
    MOVE.B  #15,D0
    MOVE.B  #10,D2
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
