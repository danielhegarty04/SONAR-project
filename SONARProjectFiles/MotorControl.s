#include <xc.inc>
    
global  Motor_Setup, Stop_Motor, Run_Clockwise, Run_Counter, Motor_delay_01ms, Delay_ms

psect	udata_acs   ; reserve data space in access ram
read_bit_1: ds    1	    ; reserve 1 byte for the first measurement
read_bit_2: ds	  1	    ; second measurement 
Motor_cnt_l: ds  1
Motor_cnt_h: ds  1
Motor_cnt_ms: ds 1	    ; Vars for delays
Signal_time:  ds 1	    ; Counts the time to run the signal


psect	motor_code,class=CODE

Motor_Setup:
	bcf	TRISC, 0, A	    ; Set the motor bit to output
	movlw	30
	call	Motor_delay_01ms    ; wait 3ms for setup
	
	return
	
Stop_Motor:			    ; Send 1.5 ms pulse
	bsf	PORTC, 0, A	    ; Set motor bit high
	movlw	17		    ; wait 1.5 ms
	call	Motor_delay_01ms
	bcf	PORTC, 0, A	    ; Set motor bit low
	return
	
Run_Clockwise:			    ; Sends a 1 ms pulse
	; Repeats every 20 ms until a time in W in terms of 100 ms
	movwf	Signal_time, A
cwlp:
	
	bsf	PORTC, 0, A	    ; Set motor bit high
	movlw	11		    ; Wait 1 ms
	call	Motor_delay_01ms
	
	bcf	PORTC, 0, A	    ; Set motor bit low
	movlw	188
	call	Motor_delay_01ms    ; Repeat the signal a number of times in W
	decfsz	Signal_time, A
	bra	cwlp
	
	return
	
Run_Counter:			    ; Send 2 ms pulse
	; Repeats every 20 ms until a time in W in terms of 20 ms
	movwf	Signal_time, A
ccwlp:
	bsf	PORTC, 0, A	    ; Set motor bit high
	movlw	23		    ; Wait 2 ms
	call	Motor_delay_01ms
	bcf	PORTC, 0, A	    ; Set motor bit low
	movlw	176
	call	Motor_delay_01ms
	decfsz	Signal_time, A	    ; Repeat the signal a number of times in W
	bra	ccwlp
	
	return

Delay_ms:		    ; delay given in ms in W
	movwf	Motor_cnt_ms, A
mtlp3:	movlw	250	    ; 1 ms delay
	call	Motor_delay_x4us	
	decfsz	Motor_cnt_ms, A
	bra	mtlp3
	return
	
Motor_delay_01ms:		    ; delay given in 0.1 ms in W
	movwf	Motor_cnt_ms, A
mtlp2:	movlw	25	    ; 0.1 ms delay
	call	Motor_delay_x4us	
	decfsz	Motor_cnt_ms, A
	bra	mtlp2
	return
    
Motor_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	Motor_cnt_l, A	; now need to multiply by 16
	swapf   Motor_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	Motor_cnt_l, W, A ; move low nibble to W
	movwf	Motor_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	Motor_cnt_l, F, A ; keep high nibble in LCD_cnt_l
	call	Motor_delay
	return

Motor_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
mtlp1:	decf 	Motor_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	Motor_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	mtlp1		; carry, then loop again
	return			; carry reset so return

