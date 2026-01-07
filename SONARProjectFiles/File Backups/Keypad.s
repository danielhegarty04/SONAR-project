#include <xc.inc>
    
global  Keypad_Setup, Keypad_Read, Keypad_delay_ms

psect	udata_acs   ; reserve data space in access ram
read_bit_1: ds    1	    ; reserve 1 byte for the first measurement
read_bit_2: ds	  1	    ; second measurement 
read_nmbr:  ds	  1	    ; byte that holds the keypad number
Keypad_cnt_l: ds  1
Keypad_cnt_h: ds  1
Keypad_cnt_ms: ds 1	    ; Vars for delays


psect	keypad_code,class=CODE
Keypad_Setup:
    movlb   0x0F	    ; Select bank 15
    bsf	    REPU
    clrf    LATE, A
    movlw   0x00
    movwf   TRISD, A	    ; Set port D to be outputs
    movlw   30
    call    Keypad_delay_ms
    return

Keypad_Read:
    movlw   0x0F 
    movwf   TRISE, A	    ; Set TRISE to 0x0f
    movlw   1
    call    Keypad_delay_ms ; Add in delay
    movlw   0x00
    movwf   PORTE, A	    ; Drive 4-7 low
    movf    PORTE, W, A
    align   2
    movwf   read_bit_1, A  ; Read the low bits of PORTE
    movlw   10
    call    Keypad_delay_ms ; wait 1 ms
    
    ; Now, do the reverse
    movlw   0xF0
    movwf   TRISE, A	    ; Set TRISE to 0xf0
    movlw   1
    call    Keypad_delay_ms
    align   2
    movlw   0x00
    movwf   PORTE, A	    ; Drive 1-3 low
    movf    PORTE, W, A
    movwf   read_bit_2, A
    movlw   10
    call    Keypad_delay_ms ; wait 1 ms
    
    ; Read out to PORTD for testing
    movf    read_bit_1, W, A
    addwf   read_bit_2, W, A
    align   2
    movwf   PORTD, A
    movwf   read_nmbr, A    ; Store the number
    movlw   5
    call    Keypad_delay_ms
    comf    read_nmbr, f, A
    comf    read_bit_1, f, A	; compliment the numbers 
    comf    read_bit_2, f, A
    call    Decode_Keypad
    return
    
Decode_Keypad:
    ; Decode the keypad using 16 if statements
    ; First check if no numbers
    movf    read_nmbr, W, A
    
    movlw   0xFF
    cpfseq  read_nmbr, A    ; Check if no press
    bra	    col1
    movlw   0x00
    return
    
col1:
    movlw   0x1F
    cpfseq  read_bit_2, A	; Check if in col1
    bra	    col2
row11:
    movlw   0xF1
    cpfseq  read_bit_1, A	; check if row 1
    bra	    row12
    movlw   0x31
    return
row12:
    movlw   0xF2
    cpfseq  read_bit_1, A	; check if row 2
    bra	    row13
    movlw   0x32
    return
row13:
    movlw   0xF4
    cpfseq  read_bit_1, A	; check if row 3
    bra	    row14
    movlw   0x33
    return
row14:
    movlw   0xF8
    cpfseq  read_bit_1, A	; check if row 1
    bra	    fail1
    movlw   0x46
    return
fail1:
    movlw   0xFF		; Not valid
    return
    
    
col2:
    movlw   0x2F
    cpfseq  read_bit_2, A	; Check if in col2
    bra	    col3
row21:
    movlw   0xF1
    cpfseq  read_bit_1, A	; check if row 1
    bra	    row21
    movlw   0x34
    return
row22:
    movlw   0xF2
    cpfseq  read_bit_1, A	; check if row 2
    bra	    row23
    movlw   0x35
    return
row23:
    movlw   0xF4
    cpfseq  read_bit_1, A	; check if row 3
    bra	    row24
    movlw   0x36
    return
row24:
    movlw   0xF8
    cpfseq  read_bit_1, A	; check if row 1
    bra	    fail2
    movlw   0x45
    return
fail2:
    movlw   0xFF		; Not valid
    return
    
col3:
    movlw   0x4F
    cpfseq  read_bit_2, A	; Check if in col3
    bra	    col4
row31:
    movlw   0xF1
    cpfseq  read_bit_1, A	; check if row 1
    bra	    row32
    movlw   0x37
    return
row32:
    movlw   0xF2
    cpfseq  read_bit_1, A	; check if row 2
    bra	    row33
    movlw   0x38
    return
row33:
    movlw   0xF4
    cpfseq  read_bit_1, A	; check if row 3
    bra	    row34
    movlw   0x39
    return
row34:
    movlw   0xF8
    cpfseq  read_bit_1, A	; check if row 1
    bra	    fail3
    movlw   0x34
    return
fail3:
    movlw   0xFF		; Not valid
    return
col4:
row41:
    movlw   0xF1
    cpfseq  read_bit_1, A	; check if row 1
    bra	    row42
    movlw   0x41
    return
row42:
    movlw   0xF2
    cpfseq  read_bit_1, A	; check if row 2
    bra	    row43
    movlw   0x30
    return
row43:
    movlw   0xF4
    cpfseq  read_bit_1, A	; check if row 3
    bra	    row44
    movlw   0x42
    return
row44:
    movlw   0xF8
    cpfseq  read_bit_1, A	; check if row 1
    bra	    fail4
    movlw   0x43
    return
fail4:
    movlw   0xFF		; Not valid
    return
    
    
Keypad_delay_ms:		    ; delay given in ms in W
	movwf	Keypad_cnt_ms, A
kpdlp2:	movlw	250	    ; 1 ms delay
	call	Keypad_delay_x4us	
	decfsz	Keypad_cnt_ms, A
	bra	kpdlp2
	return
    
Keypad_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	Keypad_cnt_l, A	; now need to multiply by 16
	swapf   Keypad_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	Keypad_cnt_l, W, A ; move low nibble to W
	movwf	Keypad_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	Keypad_cnt_l, F, A ; keep high nibble in LCD_cnt_l
	call	Keypad_delay
	return

Keypad_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
kpdlp1:	decf 	Keypad_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	Keypad_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	kpdlp1		; carry, then loop again
	return			; carry reset so return

