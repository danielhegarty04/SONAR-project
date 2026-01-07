#include <xc.inc>

global  LCD_Setup, LCD_Write_Message, LCD_Send_Byte_I, LCD_delay_ms, LCD_Send_Byte_D
global  Send_dist_to_LCD, Hex_to_Dec, d0, d1, d2, d3
extrn	low_dist, high_dist
    
psect	udata_acs   ; named variables in access ram
LCD_cnt_l:	ds 1   ; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1   ; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1   ; reserve 1 byte for ms counter
LCD_tmp:	ds 1   ; reserve 1 byte for temporary use
LCD_counter:	ds 1   ; reserve 1 byte for counting through nessage
LCD_counter_max:ds 1   ; reserve 1 byte for the maximum value of the counter
LCD_16:		ds 1   ; reserve 1 byte for 16#
res_0:		ds 1
res_1:		ds 1
res_2:		ds 1
res_3:		ds 1   ; Variables for 16x16 multiplication
res_0_new:	ds 1
res_1_new:	ds 1
res_2_new:	ds 1
res_3_new:	ds 1   ; Variables for 8x24 multiplication
d0:		ds 1
d1:		ds 1
d2:		ds 1
d3:		ds 1   ; Vars for hex -> dec conversion

	LCD_E	EQU 5	; LCD enable bit
    	LCD_RS	EQU 4	; LCD register select bit

psect	lcd_code,class=CODE
    
LCD_Setup:
	clrf    LATB, A
	movlw   11000000B	    ; RB0:5 all outputs
	movwf	TRISB, A
	movlw   40
	call	LCD_delay_ms	; wait 40ms for LCD to start up properly
	movlw	00110000B	; Function set 4-bit
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00101000B	; 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00101000B	; repeat, 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00001111B	; display on, cursor on, blinking on
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00000001B	; display clear
	call	LCD_Send_Byte_I
	movlw	2		; wait 2ms
	call	LCD_delay_ms
	movlw	00000110B	; entry mode incr by 1 no shift
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	10000000B	; Set DDram address to 0?
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	
	return

LCD_Write_Message:	    ; Message stored at FSR2, length stored in W
	
	movwf   LCD_counter, A
	movwf   LCD_counter_max, A
	movlw   0x10
	movwf   LCD_16, A
	;movlw	10000000B	; Set DDram address to 0
	;call	LCD_Send_Byte_I
	;movlw	10		; wait 40us
	;call	LCD_delay_x4us
LCD_Loop_message:
	movf	LCD_counter, W, A
	subwf	LCD_counter_max, W, A
	cpfseq	LCD_16, A
	bra	jump1
	movlw	11000000B	; Set DDram address to 64
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	
jump1:	movf    POSTINC2, W, A
	call    LCD_Send_Byte_D
	decfsz  LCD_counter, A
	bra	LCD_Loop_message
	return

LCD_Send_Byte_I:	    ; Transmits byte stored in W to instruction reg
	movwf   LCD_tmp, A
	swapf   LCD_tmp, W, A   ; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bcf	LATB, LCD_RS, A	; Instruction write clear RS bit
	call    LCD_Enable  ; Pulse enable Bit 
	movf	LCD_tmp, W, A   ; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bcf	LATB, LCD_RS, A	; Instruction write clear RS bit
        call    LCD_Enable  ; Pulse enable Bit 
	return

LCD_Send_Byte_D:	    ; Transmits byte stored in W to data reg
	movwf   LCD_tmp, A
	swapf   LCD_tmp, W, A	; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bsf	LATB, LCD_RS, A	; Data write set RS bit
	call    LCD_Enable  ; Pulse enable Bit 
	movf	LCD_tmp, W, A	; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bsf	LATB, LCD_RS, A	; Data write set RS bit	    
        call    LCD_Enable  ; Pulse enable Bit 
	movlw	10	    ; delay 40us
	call	LCD_delay_x4us
	return

LCD_Enable:	    ; pulse enable bit LCD_E for 500ns
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bsf	LATB, LCD_E, A	    ; Take enable high
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bcf	LATB, LCD_E, A	    ; Writes data to LCD
	return

Send_dist_to_LCD:
    ; Code to send the hex distance value in low:high_dist to the
    ; LCD after converting to decimal
    movlw   00000001B	; display clear
    call    LCD_Send_Byte_I
    movlw   2		; wait 2ms
    call    LCD_delay_ms
	
    call Hex_to_Dec
    
    ; Add 0x30 to convert to ascii
    movlw   0x30
    addwf   d0, F, A
    addwf   d1, F, A
    addwf   d2, F, A
    addwf   d3, F, A
    
    movf d0, W, A	; Send smallest number first
    call LCD_Send_Byte_D
    movf d1, W, A	; Send next number
    call LCD_Send_Byte_D
    movf d2, W, A	; Send next number
    call LCD_Send_Byte_D
    movf d3, W, A	; Send next number
    call LCD_Send_Byte_D
    
    ; Show that it is in mm
    movlw 0x20
    call LCD_Send_Byte_D    ; send ' '
    movlw 0x6D
    call LCD_Send_Byte_D    ; send m
    movlw 0x6D
    call LCD_Send_Byte_D    ; send m
    
    return
    
    

	
Hex_to_Dec:
    ; Code to convert a hexidecimal number to a decimal one
    ; The decimal will be stored in d0:3
    ; The original hex number is in low:high_dist
    ; Ideally the number should be in units of mm
    ; Takes ~7 us to run
    
    ; Start with 16 bit multiplication
	movlw 0x8A		; Move the lower of 0x418A to w
	mulwf low_dist, A	; ARG1L * ARG2L->
			    ; PRODH:PRODL
	movff PRODH, res_1	;
	movff PRODL, res_0	;

	movlw 0x41		; Move the upper of 0x418A to w
	mulwf high_dist, A	; ARG1H * ARG2H->
			    ; PRODH:PRODL
	movff PRODH, res_3	;
	movff PRODL, res_2	;

	movlw 0x8A		; Move the lower of 0x418A to w
	mulwf high_dist, A	; ARG1L * ARG2H-> ; PRODH:PRODL
	movf  PRODL, W, A	;
	addwf res_1, F, A	; Add cross
	movf  PRODH, W, A	; products
	addwfc res_2, F, A	;
	clrf  WREG, A	;
	addwfc res_3, F, A	;

	movlw 0x41		; Move the upper of 0x418A to w
	mulwf low_dist, A	; ARG1H * ARG2L-> PRODH:PRODL
	movf  PRODL, W, A	;
	addwf res_1, F, A	; Add cross prods
	movf  PRODH, W, A	; 
	addwfc res_2, F, A	;
	clrf  WREG, A	;
	addwfc res_3, F, A	;    

	movff res_3, d0
	clrf  res_3, A

	
	; Do 8x24 multiplication
	; 24 bit result is in res_0:2
	clrf res_0_new
	clrf res_1_new
	clrf res_2_new
	clrf res_3_new
    
	movlw 0x0A		; Multiply by 10
	mulwf res_0, A		; ARG1L * ARG2L->
				; PRODH:PRODL
	movff PRODH, res_1_new	;
	movff PRODL, res_0_new	;
	
	movlw 0x0A
	mulwf res_1, A		; multiply middle byte
	movf  PRODL, W, A
	addwf res_1_new, F, A	; Add low mult to res_1'
	movf  PRODH, W, A   
	addwfc res_2_new, A	; Add to res_2' with carry
	
	clrf  WREG, A
	addwfc res_3_new, F, A	; Propagate the carry
	
	movlw 0x0A  
	mulwf res_2, A		; multiply high byte
	movf  PRODL, W, A
	addwf res_2_new, F, A	; Add low byte to res_2'
	movf  PRODH, W, A
	addwfc res_3_new, F, A	; add high byte to res_3' with carry

	movff res_3_new, d1
	clrf  res_3_new, A
	
	; Do 8x24 multiplication
	; 24 bit result is in res_0_new:2_new
	clrf res_0
	clrf res_1
	clrf res_2
	clrf res_3
    
	movlw 0x0A		; Multiply by 10
	mulwf res_0_new, A		; ARG1L * ARG2L->
				; PRODH:PRODL
	movff PRODH, res_1	;
	movff PRODL, res_0	;
	
	movlw 0x0A
	mulwf res_1_new, A		; multiply middle byte
	movf  PRODL, W, A
	addwf res_1, F, A	; Add low mult to res_1'
	movf  PRODH, W, A   
	addwfc res_2, A	; Add to res_2' with carry
	
	clrf  WREG, A
	addwfc res_3, F, A	; Propagate the carry
	
	movlw 0x0A  
	mulwf res_2_new, A		; multiply high byte
	movf  PRODL, W, A
	addwf res_2, F, A	; Add low byte to res_2'
	movf  PRODH, W, A
	addwfc res_3, F, A	; add high byte to res_3' with carry

	movff res_3, d2
	clrf  res_3, A
	
	
	; Do 8x24 multiplication
	; 24 bit result is in res_0:2
	clrf res_0_new
	clrf res_1_new
	clrf res_2_new
	clrf res_3_new
    
	movlw 0x0A		; Multiply by 10
	mulwf res_0, A		; ARG1L * ARG2L->
				; PRODH:PRODL
	movff PRODH, res_1_new	;
	movff PRODL, res_0_new	;
	
	movlw 0x0A
	mulwf res_1, A		; multiply middle byte
	movf  PRODL, W, A
	addwf res_1_new, F, A	; Add low mult to res_1'
	movf  PRODH, W, A   
	addwfc res_2_new, A	; Add to res_2' with carry
	
	clrf  WREG, A
	addwfc res_3_new, F, A	; Propagate the carry
	
	movlw 0x0A  
	mulwf res_2, A		; multiply high byte
	movf  PRODL, W, A
	addwf res_2_new, F, A	; Add low byte to res_2'
	movf  PRODH, W, A
	addwfc res_3_new, F, A	; add high byte to res_3' with carry

	movff res_3_new, d3
	clrf  res_3_new, A
	
	return
	
	
; ** a few delay routines below here as LCD timing can be quite critical ****
LCD_delay_ms:		    ; delay given in ms in W
	movwf	LCD_cnt_ms, A
lcdlp2:	movlw	250	    ; 1 ms delay
	call	LCD_delay_x4us	
	decfsz	LCD_cnt_ms, A
	bra	lcdlp2
	return
    
LCD_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	LCD_cnt_l, A	; now need to multiply by 16
	swapf   LCD_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	LCD_cnt_l, W, A ; move low nibble to W
	movwf	LCD_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	LCD_cnt_l, F, A ; keep high nibble in LCD_cnt_l
	call	LCD_delay
	return

LCD_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lcdlp1:	decf 	LCD_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	LCD_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	lcdlp1		; carry, then loop again
	return			; carry reset so return

	
    end


