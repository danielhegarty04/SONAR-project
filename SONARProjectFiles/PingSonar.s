#include <xc.inc>
    
global  Sonar_Setup, Run_Ping

psect	udata_acs   ; reserve data space in access ram
Sonar_cnt_l: ds  1
Sonar_cnt_h: ds  1	    ; Vars for delays
ping_time_l: ds	 1	    
ping_time_h: ds  1	    ; Vars for ping time



psect	sonar_code,class=CODE

Sonar_Setup:
	bcf	TRISC, 1, A	    ; Set the trigger/sig bit to output
	clrf	PSPCON		    ; Disable Parallel Slave Port
	clrf	ANCON0		    ; disable ANCON0
	movlw	00111100B	    ; Add x8 prescaler, set clock source to 
	movwf	T3CON, A	    ; instruction clock
	movlw	100
	call	Sonar_delay_x2us    ; wait 0.2ms for setup
	
	
	return
	
Run_Ping:			    ; Sends a 10 us pulse
	bcf	TRISC, 1, A	    ; Ensure pin is output
	bsf	PORTC, 1, A	    ; Set signal bit high
	movlw	3		    ; Wait 5 us
	call	Sonar_delay_x2us
	bcf	PORTC, 1, A	    ; Set signal bit low
	bsf	TRISC, 1, A	    ; Set bit to input
;	movlw	1
;	call	Sonar_delay_x2us    ; Wait for 2 us
	; Measure the output from the SONAR device
	
Wait_High:
	; Wait for the pin to go high
	btfss	PORTC, 1, A	    ; Check while output is low
	bra	Wait_High

	clrf    TMR3H, A	    ; Clear the timers
	clrf    TMR3L, A
	;bcf     TMR3IF		    ; clear overflow flag
	bsf     TMR3ON		    ; start Timer1

Wait_Low:
	btfsc   PORTC, 1, A	     ; Check while output is high
	bra     Wait_Low	    

	bcf     TMR3ON		     ; stop timer
				     ; 1 on a timer == 1/2 us
	
	
	; Divide by 2 to get in units of us
	rrcf	TMR3H, F, A
	rrcf	TMR3L, F, A	     
	
	return


Sonar_delay_x2us:		    ; delay given in chunks of 2 microsecond in W
	clrf    Sonar_cnt_h, A	    ; Clear the high bit
	movwf	Sonar_cnt_l, A	    ; now need to multiply by 8
	rlcf    Sonar_cnt_l, F, A  ; shift left 1 (×2)
	rlcf    Sonar_cnt_h, F, A
	rlcf    Sonar_cnt_l, F, A  ; shift left again (×4)
	rlcf    Sonar_cnt_h, F, A
	rlcf    Sonar_cnt_l, F, A  ; shift left again (×8)
	rlcf    Sonar_cnt_h, F, A
	call	Sonar_delay
	return

Sonar_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
snlp1:	decf 	Sonar_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	Sonar_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	snlp1		; carry, then loop again
	return			; carry reset so return

