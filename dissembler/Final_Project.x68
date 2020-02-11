*-----------------------------------------------------------
* Title      : 68k Disassembler
* Written by : Henry Park & Tae Kwon
* Date       : 02/10/2020
* Description: Disassembler for 68k assembly language 
*-----------------------------------------------------------

START_ADDRESS       EQU         $300 ; start address
END_ADDRESS         EQU         $308 ; end address
CR                  EQU         $0D ; Carrige return
LF                  EQU         $0A ; Linefeed


    ORG    $1000
START:                  ; first instruction of program
USER_INPUT:
    JSR     START_ADDR
    JSR     END_ADDR
    MOVE.L  END_ADDRESS,D0
    CMP     START_ADDRESS,D0 ; check if start address is smaller than end address
    BLE     ERROR
    BRA     DECODE_LOOP ; go to decode loop to process 

START_ADDR:
    LEA     INPUT_START,A1 ; load message on A1
    MOVE.B  #14,D0 ; read char at A1 until null
    TRAP    #15 ; excute command code at D0
    MOVE.B  #4,D0 ; read input num
    TRAP    #15 
    CMP     #0,D1 ; is ascii or negative int
    BLE     ERROR ; negative int 
    BTST    #0,D1 ; even or odd
    BNE     ERROR
    MOVE.L  D1,START_ADDRESS ; save start address to variable start_address
    RTS
    
END_ADDR:
    LEA     INPUT_END,A1 ; load message on A1
    MOVE.B  #14,D0 ; read char at A1 until null
    TRAP    #15 ; excute command code at D0
    MOVE.B  #4,D0 ; read input num
    TRAP    #15 
    CMP     #0,D1 ; is ascii or negative int
    BLE     ERROR ; negative int 
    BTST    #0,D1 ; even or odd
    BNE     ERROR
    MOVE.L  D1,END_ADDRESS ; save end address to variable end_address
    RTS     ; return to User input block

DECODE_LOOP:
    ; decode starts here
    LEA     START_ADDRESS,A1 ; print start address for testing
    MOVE.B  #3,D0
    TRAP    #15
    
    LEA     END_ADDRESS,A1 ; print end address for testing
    MOVE.B  #3,D0
    TRAP    #15
    
    BRA     REPEAT_OR_FINISH ; after decode process, ask user to continue or not

REPEAT_OR_FINISH:
    JMP     END ; end program

; TODO: convert int to HEX . Or user will input hex value? In second case, we need to develop a converter that does char to hex
ASCII_TO_HEX:


ERROR:
    LEA     ERROR_INPUT,A1 ; load error message
    MOVE.B  #14,D0 ; prompt error message to user
    TRAP    #15
    BRA     USER_INPUT ; go back to the begining of the program
    
* Put program code here
END:
    SIMHALT             ; halt simulator

* Put variables and constants here
INPUT_START   DC.B    'Enter start address: ',CR,LF,0
INPUT_END     DC.B    'Enter end address: ',CR,LF,0
ERROR_INPUT   DC.B    'Please check your input!',CR,LF,0
RESULT        DC.B    'Completed: ',CR,LF,0 

    END    START        ; last line of source


*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~
