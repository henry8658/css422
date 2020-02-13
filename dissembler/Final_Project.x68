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
    MOVE.L  END_ADDRESS,D0 ; move end address to D0 to compare two addresses
    CMP     START_ADDRESS,D0 ; check if start address is smaller than end address
    BLE     ERROR
    BRA     DECODE_LOOP ; go to decode loop to process 

START_ADDR:
    LEA     INPUT_START,A1 ; load message on A1
    MOVE.B  #14,D0 ; read char at A1 until null
    TRAP    #15 ; excute command code at D0
    MOVE.B  #2,D0 ; Read string from keyboard and store at (A1), NULL terminated, length retuned in D1.W (max 80)
    TRAP    #15 ; excute trap
    CMPI    #0,D1 ; check if there is char to process D1: length of string
    BEQ     ERROR   ; If user didn't type anything, prompt error and restart the program.
    CMPI    #8,D1 ; if there is more than 8 digits of hex. It is out of bound long address
    BGT     ERROR 
    JSR     ATOI
    BTST    #0,D1 ; check even or odd address
    BNE     ERROR
    MOVE.L  D2,START_ADDRESS ; save start address to variable start_address
    RTS
    
END_ADDR:
    LEA     INPUT_END,A1 ; load message on A1
    MOVE.B  #14,D0 ; read char at A1 until null
    TRAP    #15 ; excute command code at D0
    MOVE.B  #2,D0 ; Read string from keyboard and store at (A1), NULL terminated, length retuned in D1.W (max 80)
    TRAP    #15 ; excute trap
    CMP     #0,D1 ; is ascii or negative hex
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
ATOI:
    CMP     #0,D1 ; check if there is char to process D1: length of string
    
    MOVE.B  (A1)+,D0 ; load one char to D0 to process
    SUB     #1,D1 ; decrement length of char D1: lengh of string
    CMPI    #$46,D0 ; Check if the hex value of char is more than F ($46)
    BGT     ERROR ; if is bigger than $46 prompt error
    CMPI    #$41,D0 ; Check if the hex value of char is more or equal to A ($41)
    BGE     CONVERT_CHAR_TO_HEX ; Jump to convert A-F to Hex
    CMPI    #$39,D0 ; check if the hex value of char is less than 9 ($39)
    BGT     ERROR ; out of bound for char value 1-9
    CMPI    #$30,D0 ; check if the hex value of char is more than 0 ($30)
    
    
CONVERT_CHAR_TO_HEX:
    SUBI    #$37,D0 ; subtract hex 37 to convert A-F to hex
    BRA     ATOI


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
