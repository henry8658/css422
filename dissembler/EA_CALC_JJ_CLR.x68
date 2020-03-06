*-----------------------------------------------------------
* Title      : EA_Calculator
* Written by : Henry Park
* Date       :
* Description: Calculating EA for given input
*-----------------------------------------------------------
*EA_DST_ONLY changed to EA_CLR
*EA_JJ covers JMP AND JSR

*Created****************

*EA_CLR:
*EA_CLR_111:
*-----------------
*EA_JJ:
*EA_JJ_010:
*EA_JJ_111: 
*-----------------------------------------------------------


bufsize     EQU     64 ; 64 characters can be stored in buffer
right4      EQU 4
right8      EQU 8
right16     EQU 16
right24     EQU 24

    ORG    $1000
START:                  ; first instruction of program
    
* Put program code here
; For EA calculation 
; Follwing Register was used

; D0: EA Type (IT DOES NOT CHANGE IN EA)
; D1: Address Mode / EA TYPE PROCESS
; D2: Data Size
; D3: Used for Reg Num
; D4: PC Counter displacement for next insturction read (Don't modify it)
; D5: Used for checking special condition ex) checking invalid address mode
; D6: Used for value to give ITOA
; D7: PC COUNTER (DO NOT CHANGE)
; A3: Pointing Current Address of the Instruction 
; A5: buffer for ITOA

; we might have to combine logic in ATOI

EA_START:
    MOVE.L  #$1000, D7
    
    LEA     buffer,A2
    MOVEA   #$500,A3 ; testing example start address
    MOVE.L  #$42901234,(A3) ; load test example instruction If you want to test, change this value!
    MOVE.W  #$1234, 4(A3)
    MOVE.B  #4,D1 ; D1 for processing EA Type
    MOVE.B  D1,D0 ; save EA TYPE in D0
    LEA     EA_TYPE_TABLE,A0
    MULU    #6,D1
    JMP     0(A0,D1) ; jump to ea table according to D1 value

EA_TYPE_TABLE:
    JMP     EA_IMMEDIATE ; EA_TYPE 0  ORI, ANDI, SUBI, ADDI, EORI, CMPI
    JMP     EA_MOVE ;1 MOVE
    JMP     EA_MOVEA ;2 MOVEA
    JMP     EA_LEA ;3 LEA
    JMP     EA_CLR ;4 CLR  
;    JMP     EA_EXT ;5
;    JMP     EA_MOVEM ;6
;    JMP     EA_TRAP ;7 TRAP
    JMP     EA_QUICK ; ADDQ, SUBQ ;8
    JMP     EA_BRANCH ;9 Bcc, BRA, BSR
    JMP     EA_SHIFT ; 10 ASL, ASR, LSL, LSR, ROL, ROR
    JMP     EA_EXTRA ; 11 SUB, ADD
    JMP     EA_JJ   ; 12 JMP, JSR  
      
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
    BEQ     ERROR
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
    BRA     ERROR  ; Throw Error here if size is 11 which is incorrect for this case
    
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
    BRA     ERROR  ; Throw Error here if size is 11 which is incorrect for this case
    
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
    BRA     ERROR                   ;   ERROR
        
LEA_SUCCESS:
    MOVE.W  (A3), D5                  ; CHECKING MODE 111'S REG EDGE CASE
    ANDI.W  #$000F, D5          
    CMP.B   #$A, D5                 ; IF REG is not 000 || 001
    BGE     ERROR                   ;  ERROR
                                    ; ELSE
                          
    ADDI    #2,D4                   ; instruction word displacement
    JSR     EA_SRC_AS_DST           ;  process
    
    MOVE.B  #',',(A2)+
    MOVE.B  #' ',(A2)+
    
    MOVE.W  (A3), D3                  ; Move instruction to D3 for reg
    ANDI.W  #%0000111000000000,D3   ; get reg
    MOVE.B  #$9, D5                 ; D5 Shift Counter = 9
    LSR.W   D5, D3
    
    JSR     MODE_001            

    JMP     FINISH_EA

EA_CLR:
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
    BEQ     ERROR
    
    CMP.B   #7, D1                  ; if src mode == 111
    BEQ     EA_CLR_111
    
    JSR     EA_CALCULATE_SRC
    
    JMP     FINISH_EA
    
EA_CLR_111:
    CLR     D2              ; In case (CLR.B $12341234)
    MOVE.B  #' ', (A2)+
    MOVE.B  #'$', (A2)+     ; Absolute Value
    ADDI    #2, D4          ;  To read extended address
    CMP.B   #0, D3          ;IF ABSOLUTE SIZE 0
    BEQ     CLR_000          ;   SKIP ABSOLUTE SIZE ++ 
    CMP.B   #2, D3  
    BGE     ERROR   
    ADDI    #1, D2          ; D2 = 0 + 1, BECAUSE #%10 IS FOR LONG AND #%01 FOR WORD
    CLR_000:
    ADDI    #1, D2          ; IF LONG ADDRESS D2 = 1 + 1 
    JSR     EA_EXTENDED
    JSR     START_ITOA
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
    BEQ     ERROR
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
    MOVE.W  (A3), D2      ;   NEED TO CHECK [ANDI.W #$00FF]
    ANDI.W  #$00FF, D2  ;   If 00 || FF 
    CMP.B   #$FF, D2    ; 
    BEQ     Bcc_Extend  ;       FF = Long
    CMP.B   #$00, D2    
    BEQ     Bcc_Extend  ;       00 = W
        
    ;   else Byte size   
    ADDI.w  #$2, D2     
    ADD.L   D7, D2      ;
    MOVE.L  D2, (A5)      ;   D6 = PC + (DISPLACEMENT + 2)
    
    ; D2 = size 
    MOVE.W  #$3, D2     ; Update Size for ITOA
    ADDI.W  #2, D4      ; TO UPDATE START ADDRESs, after converting 
    JSR     START_ITOA
      
    JMP     FINISH_EA
    
    
Bcc_Extend:    
    JSR     EA_Bcc_EXTENDED ; displacement calc done
    
    ADDI.L  #$2, (A5)     
    ADD.L   D7, (A5)         ;   (A5 == DISPLACEMENT) += (PC + 2)
    MOVE.B   #$3, D2          ; Considering all the start address is in Long address
    
    JSR     START_ITOA
    
    JMP     FINISH_EA

EA_JJ:
    MOVE.W  (A3), D1                  ; Move instruction to D1 for mode
    ANDI.W  #%0000000000111000,D1   ; get mode
    LSR.W   #$3, D1
    
    MOVE.W  (A3), D3                  ; Move instruction to D3 for reg
    ANDI.W  #%0000000000000111,D3   ; get reg
    
    CMP.B   #7, D1                  ; if src mode == 010 || 111
    BEQ     EA_JJ_111
                                    ;   LEA_SUCCESS
    CMP.B   #2, D1
    BEQ     EA_JJ_010
                                    ; else
    BRA     ERROR                   ;   ERROR
        
EA_JJ_010:   
    MOVE.W  (A3), D5                  ; CHECKING MODE 111'S REG EDGE CASE
    ANDI.W  #$000F, D5          
    CMP.B   #$A, D5                 ; IF REG is not 000 || 001
    BGE     ERROR                   ;  ERROR
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
    BGE     ERROR   
    ADDI    #1, D2          ; BECAUSE #%10 IS FOR LONG   
    JJ_000:
    JSR     EA_EXTENDED
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
    BEQ     ERROR ; throw error
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
    BRA     ERROR  ; Throw Error here if size is 11 which is incorrect for this case

EA_SRC_AS_DST:
    MOVE.W  (A3),D1 ; D1: save mode num
    MOVE.W  (A3),D3 ; D2: save reg num 
    MOVE.W  (A3),D5 ; D5: checking invalid address mode for mode 111
    LSR.L   #2,D5 ; extrating mode and reg num for checking invalid mode 111
    CMP.B   #$F,D5 ; not supported in this  Immedate data address mode 
    BEQ     FINISH_EA ; error -> Immediate data is not valid
    ANDI.W  #%0000000000111000, D1 ; Extracting Mode for Dest
    ANDI.W  #%0000000000000111, D3 ; Extracting Reg for Dest
    LSR.W   #3,D1 ; 
    CMP.B   #1,D1 ; filter invalid An address mode for op code 0000
    BEQ     ERROR ; Error Throw error for invalid address mode
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
    ADDI      #2,D4 ; pc displacement = 2
    CMP.B     #$00,D2 ; check if it's word or long size 
    BEQ       EA_WORD_DATA
    ADDI      #2,D4 ; pc displacement = 4
    BRA       EA_LONG_DATA
    
    
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
    CMP.B  #4,D3 ; Immediate Data
    BEQ    REG_100
    BRA    ERROR ; If there is no match reg num

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
    ;MOVE.L   D6,(A5) ; This one has to be LONG instead of WORD but if I changed to LONG, it ITOA does not work
    ; This issue has taken care at EA_EXTENDED
    CMP.B    #1,D0 ; check if the EA is MOVE
    BEQ      ITOA_MOVE
    CMP.B    #2,D0 ; check if the EA is MOVE
    BEQ      ITOA_MOVE
    BRA      ITOA
    
ITOA:
	MOVEM.L	    D0-D1, -(SP)		; push EA_****	funtion's D1 (EA_TYPE)
	
	CMP.B	    #%00, D2		    ; BYTE
	BEQ	        ITOA_BYTE		
	CMP.B	    #%01, D2		    ; WORD
	BEQ	        ITOA_WORD	
	CMP.B	    #%10, D2		    ; LONG
	BEQ	        ITOA_LONG
	JMP	        ITOA_LONGADDR		; LONG ADDRESS

ITOA_MOVE:
	MOVEM.L	    D0-D1, -(SP)		; push EA_**** (EA_TYPE)
	
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
	MOVEM.L	    (SP)+, D0-D1 	    ; POP D1 (EA_TYPE)
	RTS

;----------------------------------------------------------
    
    
    
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






*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~

*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~

*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~
