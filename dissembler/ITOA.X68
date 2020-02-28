*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
right4      EQU 4
right8      EQU 8
right16     EQU 16
right24     EQU 24
bufsize     EQU 64    

    ORG    $1000
START:                  ; first instruction of program

   
    MOVE.W      #12, D6
    MOVE.W      D6, (A5)
    LEA       decoded_buf, A2
    JSR         ITOA
    MOVE.B      #1, D3
    
LOOP:
    
    MOVE.B  -(A2), D1
       
    move.b  #6,D0       ; trap task #6, display single ASCII character in D1.B
    trap    #15
    SUB.B   #$01, D3
    CMP.b   #$00, D3
    BNE     LOOP

  
       
    
* Put program code here
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
	JSR	        ITOA_BYTE_CONVERT	; itoa_upper(D7)
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
	MOVE.W	    A5, D7			    ; D7= A5;
	MOVE.B	    #right24, D1
	LSR.W 	    D1, D7
	JSR	        ITOA_BYTE_CONVERT 	; itoa_upper (D7 >>24);
	MOVE.W      A5, D7			    ; D7 = A5
	MOVE.B	    #right16,  D1
	LSR.W 	    D1, D7
	JSR	        ITOA_BYTE_CONVERT	; itoa_lower (D7 >> 16);
	MOVE.W	    A5, D7			    ; D7 = A5
	MOVE.B	    #right8, D1
	LSR.W	    D1,D7
	JSR	        ITOA_BYTE_CONVERT	; itoa_upper (D7 >> 8);
	MOVE.W	    A5, D7
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




    SIMHALT             ; halt simulator

* Put variables and constants here
decoded_buf      DS.B        bufsize

    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
