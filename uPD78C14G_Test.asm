	cpu	78c10
	org 0000H
		JMP START
	org 0004H
		JMP NMI
	;org 0008H
	;	JMP INTT0	;INTT0/INTT1			
	org 0010H
		JMP INT
	;org 0018H
	;	JMP INTE0	;INTE0/INTE1
	;org 0020H
	;	JMP INTEIN	;INTEIN/INTAD	
	org 0028H		
		JMP RECV ; INTSR
	;org 0060H		
	;	JMP SOFTI ; SOFTI		
		;
		;NMI .................0004H
		;INTT0/INTT1 .........0008H
		;INT1/INT2 ...........0010H
		;INTE0/INTE1 .........0018H
		;INTEIN/INTAD ........0020H
		;INTSR/INTST .........0028H
		;SOFTI ...............0060H
		;	
	org 0080H
	STRING:
		DB 0AH
		DB 0DH
		DB 30H
		DB 31H
		DB 32H
		DB 33H
		DB 34H
		DB 35H
		DB 36H
		DB 37H
		DB 38H
		DB 39H
		DB 41H
		DB 42H
		DB 43H
		DB 44H
		DB 45H
		DB 46H
		DB 0AH
		DB 0DH
		DB 00H
		;
	org 0100H	
	START: 
        MVI A, 0CH ; 4K EXT ROM+RAM (0000-0FFF) and 256B INT RAM () 
        MOV MM,A
        LXI SP, 0000H
	;*****INT CONFIG
		MVI A, 0F7H ; 
		MOV MKL, A ; INT1 enable
	;*****SERIAL INTERFACE INITIALIZATION*******
		MVI SMH, 00H ; Internal serial clock (TO)
		MVI A, 0FEH ; ´ 16, even parity, 8 bit character, 2 stop bit <a>
		MOV SML, A ; Set serial mode
		MVI A, 03H ; 03H for 9600 bps or 83H for 110 bps
		MOV TM0, A ; Set timer register
		MVI A, 01H ; Baud rate 9600 bps <b> 01H or Baud rate 110 bps <b> 02H
		MOV TM1, A ;
		MVI TMM, 61H ; Set timer mode & start
		MVI A, 07H ; Set port C mode control
		MOV MCC, A ; TxD, RxD, /SCK available
		ORI PC, 80H ; PC7 output latch-1 <c>
		MVI A, 00H ; Initialize port C
		MOV MC, A ; Port C output mode
		ORI SMH, 04H ; Transmit enable

		CALL PWRON
		
	;*****RECEIVE ENABLE**********
	RVEN:
		LXI H, 0FF00H ; Set data pointer (DP=FF00H) <a>
		MVI C, 0FH ; Set data counter (DC=0FH) <b>
		EXX
		ANI MKH, 05H ; INTSR enable <c>
		ORI SMH, 08H ; Receive enable <d>
		ANI PC, 7FH ; /CTS=0 <e>		
		EI ; Enable interrupt

	;*****RECEIVE SERVICE*************
	RECV:
		EXA ; Save accumulator
		EXX ; Save register
		SKNIT ER ; Test ERflag, skip if ER=0
		JMP ERROR ; Jump ERROR routine
		MOV A, RXB ; Input received data
		STAX H+ ; Store received data to memory
		DCR C ; Skip if buffer full <c>		
		JR REC0 ;			
		ORI PC, 80H ; /CTS=1 <d>
		ANI SMH, 0F7H ; Receive disable <e>
		ORI MKH, 02H ; INTSR disable <f>
		CALL BFULL		
	REC0:
		EXX ; Recover register
		EXA ; Recover accumulator
		;CALL RT
		CALL PRINTM

		EI ; Enable interrupt	
		RETI ; Return from Interrupt		
		;DW    7783H
		;JMP START
		
		;LXI H, 080H ; Set data pointer (DP=FF00H) <a>
		;MVI C, 0FH ; Set data counter (DC=0FH) <b>
			
	RT: 
;*****TRANSMIT RECEIVE CHAR*************	
		LDAX H+
		SKIT FST ; Test FST, skip if FST=1
		JR RT ; Wait until FST=1
		MOV TXB, A ; Output transmit
		CALL LFCR
		JMP RT
		RET

	LFCR:
		;*****TRANSMIT LF and CR*************	
	LF:
		MVI A, 0AH ; "\n" in A
		SKIT FST ; Test FST, skip if FST=1
		JR LF ; Wait until FST=1
		MOV TXB, A ; Output transmit
	CR:
		MVI A, 0DH ; "\r" in A
		SKIT FST ; Test FST, skip if FST=1
		JR CR ; Wait until FST=1
		MOV TXB, A ; Output transmit	
		RET		
		
	PRINTM:	
		LXI H, RUSHANA
		CALL PRINT
		LXI H, MISHA	
		CALL PRINT
		LXI H, STRING
		CALL PRINT
		;JR PRINTM
		RET
	LOOP:
		JR LOOP
		
	ERROR:
		LXI H, PERROR
		CALL PRINT
		JMP START	
	
	BFULL:
		LXI H, PBFULL
		CALL PRINT
		RET	
		
	RUSHANA:
		DB 0AH, 0DH, "Rushana ",0AH, 0DH, 0

	MISHA:
		DB 0AH, 0DH, "Misha ",0AH, 0DH, 0
		
	PERROR:	
		DB 0AH, 0DH, "ERROR ",0AH, 0DH, 0
			
	PBFULL:
		DB 0AH, 0DH, "!!!!!!!!!!!!!!!!!!!! Buffer Full !!!!!!!!!!!!!!!!!!!! ",0AH, 0DH, 0
	
	PPWRON:
		DB 0AH, 0DH, 0AH, 0DH, 0AH, 0DH, 0AH, 0DH, "                              Power ON ",0AH, 0DH
		DB 0AH, 0DH, "                              uPD78C14G Test ",0AH, 0DH
		DB 0AH, 0DH, "                              14.12.2021 ",0AH, 0DH,0AH, 0DH, 0
		
	PRINT:
		LDAX H+
		NEI A, 000H
		RET
		EQI A, 000H
		CALL COUT
		JR PRINT

	COUT:
		SKIT FST ; Test FST, skip if FST=1
		JR COUT ; Wait until FST=1
		MOV TXB, A ; Output transmit
		RET
		
	NMI:
		EXA ; Save accumulator
		EXX ; Save register
		MVI A, 4EH ; "N" in A
		SKIT FST ; Test FST, skip if FST=1
		JR NMI ; Wait until FST=1
		MOV TXB, A ; Output transmit
	M:	
		MVI A, 4DH ; "M" in A
		SKIT FST ; Test FST, skip if FST=1
		JR M ; Wait until FST=1
		MOV TXB, A ; Output transmit
	I:	
		MVI A, 49H ; "I" in A
		SKIT FST ; Test FST, skip if FST=1
		JR I ; Wait until FST=1
		MOV TXB, A ; Output transmit
		CALL LFCR
		EXX ; Recover register
		EXA ; Recover accumulator
		EI
		RETI ; Return from Interrupt		
		
	INT:
		EXA ; Save accumulator
		EXX ; Save register
		MVI A, 49H ; "I" in A
		SKIT FST ; Test FST, skip if FST=1
		JR INT ; Wait until FST=1
		MOV TXB, A ; Output transmit
	N:
		MVI A, 4EH ; "N" in A
		SKIT FST ; Test FST, skip if FST=1
		JR N ; Wait until FST=1
		MOV TXB, A ; Output transmit
	T:	
		MVI A, 54H ; "T" in A
		SKIT FST ; Test FST, skip if FST=1
		JR T ; Wait until FST=1
		MOV TXB, A ; Output transmit
		CALL LFCR	
		EXX ; Recover register
		EXA ; Recover accumulator		
		EI
		RETI ; Return from Interrupt
		
	PWRON:
		LXI H, PPWRON
		CALL PRINT
		RET	

				
		

