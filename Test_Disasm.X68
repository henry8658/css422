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
