*-----------------------------------------------------------
* Title      : 68k Disassembler
* Written by : Henry Park & Tae Kwon
* Date       : 02/10/2020
* Description: Disassembler for 68k assembly language 
*-----------------------------------------------------------

START_ADDRESS       EQU         $300 ; start address
END_ADDRESS         EQU         $308 ; end address
INPUT_VALUE         EQU         $316 ; user input value
CR                  EQU         $0D ; Carrige return
LF                  EQU         $0A ; Linefeed


    ORG    $1000
START:                  ; first instruction of program

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
    BRA     DECODE_LOOP ; go to decode loop to process 
    
DECODE_LOOP:
    ; decode starts here
    MOVE.L  START_ADDRESS,D1 ; print start address for testing
    MOVE.B  #16,D2
    MOVE.B  #15,D0
    TRAP    #15
    
    MOVE.L  END_ADDRESS,D1 ; print end address for testing
    MOVE.B  #16,D2
    MOVE.B  #15,D0
    TRAP    #15
    
    BRA     REPEAT_OR_FINISH ; after decode process, ask user to continue or not

REPEAT_OR_FINISH:
    JMP     END ; end program

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
END:
    SIMHALT             ; halt simulator

* Put variables and constants here
INPUT_START   DC.B    'Enter start address: ',CR,LF,0
INPUT_END     DC.B    'Enter end address: ',CR,LF,0
ERROR_INPUT   DC.B    'Please check your input!',CR,LF,0
RESULT        DC.B    'Completed: ',CR,LF,0 
WELCOME_MSG   DC.B    'Welcome!',CR,LF,0

    END    START        ; last line of source







*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~
