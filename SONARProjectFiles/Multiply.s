#include <xc.inc>
    
global  Multiply_171
global  low_dist, high_dist	; Make the bytes global
extrn	byte_l, byte_h
psect	udata_acs		; Reserve data space in access RAM
temp_0:		ds 1
temp_1:		ds 1
low_dist:	ds 1	    
high_dist:	ds 1		; Vars to store the multiplied number
    
psect	multiply_code, class=CODE
Multiply_171: 
; Multiply the number in the timer (stored in units of us) by
; 0.171 - converts to units of mm
; Theoretical 0.5% error
; CHANGE byte_l to TMR3L, byte_h to TMR3H
	clrf  temp_0, A
	clrf  temp_1, A
	clrf  low_dist, A
	clrf  high_dist, A
	movlw 0x85		; Move the lower of 0x2B85 to w
	mulwf TMR3L, A		; ARG1L * ARG2L-> CHange to 
				; PRODH:PRODL
	movff PRODH, temp_1	;
	movff PRODL, temp_0	;

	movlw 0x2B		; Move the upper of 0x2B85 to w
	mulwf TMR3H, A	; ARG1H * ARG2H->
			    ; PRODH:PRODL
	movff PRODH, high_dist	;
	movff PRODL, low_dist	;

	movlw 0x85		; Move the lower of 0x2B85 to w
	mulwf TMR3H, A		; ARG1L * ARG2H-> ; PRODH:PRODL
	movf  PRODL, W, A	;
	addwf temp_1, F, A	; Add cross
	movf  PRODH, W, A	; products
	addwfc low_dist, F, A	;
	clrf  WREG, A	;
	addwfc high_dist, F, A	;

	movlw 0x2B		; Move the upper of 0x2B85 to w
	mulwf TMR3L, A		; ARG1H * ARG2L-> PRODH:PRODL
	movf  PRODL, W, A	;
	addwf temp_1, F, A	; Add cross prods
	movf  PRODH, W, A	; 
	addwfc low_dist, F, A	;
	clrf  WREG, A	;
	addwfc high_dist, F, A	;    
 

    
	return
    
    
; OLD CODE ;    
; TMR3 is in units of us
;        movlw   171
 ;       mulwf   byte_l, A	    ; replace with timer
;	
;	movff   PRODL, low_byte, A
;	movff   PRODH, mid_byte, A
;
;Multiply high byte by 171
;	clrf    high_byte, A
;	movlw   171
;	mulwf   byte_h, A

;Add together high:low
;	movf	PRODL, W, A
;	addwf   mid_byte, F, A
;	movf	PRODH, W, A
;	addwfc	high_byte, F, A

;	return

