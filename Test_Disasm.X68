*-----------------------------------------------------------
* Title      : Disassmbler Test Program
* Written by : Munehiro Fukuda
* Date       : 3/5/2020
*-----------------------------------------------------------
    ORG     $400
START:

*-----------------------------------------------------------
* Op Code: 25pts
*
* CPU Instructions..........................................
* 0.7pts each * 30 instructions = 21pts
*
* 0000: SUBI, ADDI
* 0001: MOVEA
* 0011: MOVE
* 0010:
* 0100: CLR, NOP, RTS, JSR, MOVEM, LEA
* 0101: ADDQ
* 0110: BRA, BSR, Bcc
* 0111: MOVEQ
* 1000: DIVU, OR
* 1001: SUB
* 1011: CMP
* 1100: MULU, MULS, AND
* 1101: ADD, ADDA
* 1110: ASL, ASR, LSL, LSR, ROL, and ROR
*

    LEA       $300, A1
    LEA       ($1234).L, A2
    LEA       $F, A3
    LEA       $1234,A4 
    LEA       $5555,A5
    LEA       $F001,A6
    LEA       $F001,A7
    
    CLR.B     D1
    CLR.B     D2
    CLR.B     D3
    CLR.B     D4
    CLR.B     D5
    CLR.B     D7
    CLR.W     D1
    CLR.W     D2
    CLR.W     D3
    CLR.W     D4
    CLR.W     D5
    CLR.W     D7
    CLR.L     D1
    CLR.L     D2
    CLR.L     D3
    CLR.L     D4
    CLR.L     D5
    CLR.L     D7
    
    
    CLR.B     (A1)
    CLR.B     (A2)
    CLR.B     (A3)
    CLR.B     (A4)
    CLR.B     (A5)
    CLR.B     (A6)
    CLR.W     (A7)
    CLR.W     (A1)
    CLR.W     (A2)
    CLR.W     (A3)
    CLR.W     (A4)
    CLR.W     (A5)
    CLR.W     (A6)
    CLR.W     (A7)
    CLR.L     (A1)
    CLR.L     (A2)
    CLR.L     (A3)
    CLR.L     (A4)
    CLR.L     (A5)
    CLR.L     (A6)
    CLR.L     (A7)
    
    
      ORI       #1, $1234     
      ORI       #13, $12341234
      ORI       #$FFFF, $FFFFFFFF
      ORI       #$F, ($0000).L  
      ORI       #$00001111, ($0000).L
      
      ANDI       #1, $1234     
      ANDI       #13, $12341234
      ANDI       #$FFFF, $FFFFFFFF
      ANDI       #$F, ($0000).L  
      ANDI       #$00001111, ($0000).L
      
      SUBI       #1, ($00001234)    
      SUBI       #13, $12341234
      SUBI       #$FFFF, $FFFFFFFF
      SUBI       #$F, ($0000).L  
      SUBI       #$00001111, ($0000).L
      
      EORI       #1, $1234     
      EORI       #13, $12341234
      EORI       #$FFFF, $FFFFFFFF
      EORI       #$F, ($0000).L  
      EORI       #$00001111, ($0000).L
      
      CMPI       #1, $1234     
      CMPI       #13, $12341234
      CMPI       #$FFFF, $FFFFFFFF
      CMPI       #$F, ($0000).L  
      CMPI       #$00001111, ($0000).L

  
      ASL	    $ABCD         ; mode 7 subclass 0 
      MOVE.L	D4, ($ABCDEF12).L ; mode 7 subclass 1
      ASR	    ($ABCDEF12).L	  ; mode 7 subclass 1
      MOVE.L	#$12345678, D5	  ; mode 7 subclass 4
      SUBI.W	#$ABCD, D0
      ADDI.W	#$ABCD, D1
      MOVEA.W	D2, A3
      MOVE.W	D4, D5
      CLR.W     D6
      NOP
      RTS
      JSR	    (A7)		
      MOVEM.W	D0, (A1)
      LEA	    (A2), A3
      ADDQ.W	#$7, D4 
      BRA   	$1234		; 16bit (word) displacement
      BSR   	$1234		; 16bit (word) displacement
      BHI   	$1234		; 16bit (word) displacement
      MOVEQ	    #$AB, D5
      DIVU	    D6, D7
      OR.W	    D0, D1
      SUB.W	    D2, D3
      CMP.W	    D4, D5
      MULU	    D6, D7	
      MULS	    D0, D1
      AND.W	    D2, D3
      ADD.W	    D4, D5
      ADDA.W	D6, A7
      ASL.W	    #1, D0
      ASR.W	    D2, D1
      LSL.W	    #3, D2
      LSR.W	    D4, D3
      ROL.W	    #5, D4
      ROR.W	    D6, D5

* Data size distinction.....................................
* .B: 2pts
* .W: 1pt
* .L: 1pt
      SUBI.B	#$AB, D0
      MOVE.B	D1, D2
      CLR.B     D3
      ADDQ.B	#$6, D4
      BRA    	START		; 8bit (byte) displacement
      OR.B      D5, D6
      SUB.B     D7, D0
      CMP.B     D1, D2
      AND.B     D3, D4
      ADD.B     D4, D5
      ASL.B     #4, D4
      ASR.B     D5, D5

      SUBI.L	#$ABCDEF12, D0
      MOVEA.L	D1, A2
      MOVE.L	D3, D4
      CLR.L     D5
      MOVEM.L	(A0), D6
      ADDQ.L	#$5, D7
      OR.L      D0, D1
      SUB.L     D2, D3
      CMP.L     D4, D5
      AND.L     D6, D7
      ADD.L     D0, D1
      ADDA.L	D2, A3
      LSL.L     #4, D4
      LSR.L     D5, D5

*-----------------------------------------------------------
* Effective Address: 35pts
* Data Register Direct (mode 0).......................... 4
* Address Register Direct (mode 1)....................... 4
* Address Register Indirect (mode 2)..................... 4
* Address Register Indirect with Post Increment (mode 3). 5
* Address Register Indirect with Pre Decrement (mode 4).. 5
* Absolute Word Address (mode 7 subclass 0).............. 4
* Absolute Long Address (moe 7 subclass 1)............... 5
* Immediate Data (mode 7 subclass 4)..................... 4

      MOVE.L	A0, D1 	 	  ; mode 0 and mode 1
      MOVEA.L	D2, A3		  ; mode 0 and mode 1
      MOVE.L	(A4), D5	  ; mode 2
      MOVE.L	D6, (A6)	  ; mode 2
      MOVEM.L	(A7)+, D0/A7  ; mode 3
      MOVEM.L	D1/A6, -(A2)  ; mode 4
      MOVE.L	$ABCD, D3	  ; mode 7 subclass 0
      ASL	    $ABCD         ; mode 7 subclass 0 
      MOVE.L	D4, ($ABCDEF12).L ; mode 7 subclass 1
      ASR	    ($ABCDEF12).L	  ; mode 7 subclass 1
      MOVE.L	#$12345678, D5	  ; mode 7 subclass 4
      MOVE.L    #$12345678, ($ABCDEF12).L ; mode 7 subclass 1 and 4

*-----------------------------------------------------------
* Extra Credits: 2pts
* 0.5pts .. one of ORI, ANDI, EORI, CMPI, NOT, EXT, TRAP, 
*                  STOP, RTE, JMP, SUBQ, EOR, and Bcc
* Need 4 instructions to get 2pts in total

      ORI.W     #$ABCD, D0
      ANDI.W    #$ABCD, D1
      EORI.W    #$ABCD, D2
      CMPI.W    #$ABCD, D3
      NOT.W	    D4
      EXT.W	    D5
      TRAP	    #15
      STOP      #$AB
      RTE
      JMP	    (A6)
      SUBQ.W    #$4, D7
      EOR.W	    D0, D1

      BLS	    $600
      BCC	    $600
      BCS	    $600
      BNE	    $600
      BEQ	    $600
      BVC	    $600
      BVS	    $600
      BPL	    $600
      BMI	    $600
      BGE	    $600
      BLT	    $600
      BGT	    $600
      BLE	    $600

      END   START






*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
