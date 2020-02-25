*-----------------------------------------------------------
* Title      : EA_Calculator
* Written by : Henry Park
* Date       :
* Description: Calculating EA for given input
*-----------------------------------------------------------
example     EQU     %0011011111000001
bufsize     EQU     64 ; 64 characters can be stored in buffer

    ORG    $1000
START:                  ; first instruction of program
    
* Put program code here
EA_CALCULATE_SRC:



EA_CALCULATE_DST:
    MOVE.L  #example,D0
   ANDI.L  #%0000000111000000, D0 ; Extracting Mode for Destination
    LSR.L   #6,D0
    MULU    #6,D0
    LEA     ADDRESS_MODE_TABLE, A0
    JMP     0(A0, D0)
  
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
    MOVE    #000,D1
    BRA     FINISH_EA
    

MODE_001:
    MOVE    #001,D1
    BRA     FINISH_EA
MODE_010:
    MOVE    #010,D1
    BRA     FINISH_EA
MODE_011:
    MOVE    #011,D1
    BRA     FINISH_EA
MODE_100:
    MOVE    #100,D1
    BRA     FINISH_EA
MODE_101:
    MOVE    #101,D1
    BRA     FINISH_EA
MODE_110:
    MOVE    #110,D1
    BRA     FINISH_EA
MODE_111:
    MOVE    #111,D1
    BRA     FINISH_EA
FILTER_SUB_MODE_111:
    ;JMP    REG_000 ; Absolute Word Address
    ;JMP    REG_001 ; Absolute Long Address
    ;JMP    REG_010 ; Not Supported
    ;JMP    REG_011 ; Not Supported
    ;JMP    REG_100 ; Immediate Data
    
FINISH_EA:
    ; testing address mode table jump
    MOVE.B  #15,D0
    MOVE.B  #10,D2
    TRAP    #15
    
    SIMHALT             ; halt simulator
* Put variables and constants here
buffer  DS.B    bufsize ; buffer 

    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~
