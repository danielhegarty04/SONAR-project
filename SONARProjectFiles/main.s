#include <xc.inc>

extrn	Motor_Setup, Stop_Motor, Run_Clockwise, Run_Counter ; External Subrouts
extrn	Delay_ms, Motor_delay_01ms
extrn	Sonar_Setup, Run_Ping
extrn	Multiply_171, low_dist, high_dist
extrn	LCD_Setup
extrn   Hex_to_Dec, d0, d1, d2, d3, Send_dist_to_LCD
global byte_l, byte_h
psect	udata_acs   ; reserve data space in access ram
counter:    ds 1    ; reserve one byte for a counter variable
delay_count:ds 1    ; reserve one byte for counter in the delay routine
byte_l:	    ds 1    
byte_h:	    ds 1
max_rots_clock:   ds 1    ; Holds the max number of rotations in each direction
max_rots_counter: ds 1
rot_count:  ds 1    ; Holds the rotation counter
    
psect	code, abs	
rst: 	org 0x0
 	goto	setup

	; ******* Programme FLASH read Setup Code ***********************
setup:	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory

	call	Motor_Setup	; setup the motor
	call	Sonar_Setup
	call	LCD_Setup

	; Set the max rotations in each direction
	movlw	11
	movwf	max_rots_clock, A
	movlw	12
	movwf	max_rots_counter, A
	goto	start
	
	; ******* Main programme ****************************************
start: 	
	; Code to run a ping and display it
	;call	Static_Mode
	movff	max_rots_clock, rot_count
clock_loop:
	
	call	Run_Ping	    ; Run the ping
	call	Multiply_171	    ; Convert time to distance
	call	Send_dist_to_LCD    ; Display on LCD
	
	; Rotate by x degrees (need to calibrate)
	movlw   4
	call	Run_Clockwise
	
	; Wait for 1 second

	movlw	250
	call	Delay_ms
	call	Delay_ms
	call	Delay_ms
	call	Delay_ms

	
	
	
	decfsz	rot_count, F, A
	bra	clock_loop
	
	; Check if D is pressed
	tstfsz	PORTD, A
	call	Static_Mode
	
	movff	max_rots_counter, rot_count
counter_loop:
	
	call	Run_Ping	    ; Run the ping
	call	Multiply_171	    ; Convert time to distance
	call	Send_dist_to_LCD    ; Display on LCD
	
	; Rotate by x degrees (need to calibrate)
	movlw   4
	call	Run_Counter
	
	; Wait for 1 second
	movlw	250
	call	Delay_ms
	call	Delay_ms
	call	Delay_ms
	call	Delay_ms
	
	decfsz	rot_count, F, A
	bra	counter_loop
	
	; Check if D is pressed
	tstfsz	PORTD, A
	bra     Static_Mode

	goto	start

Static_Mode:
	; If D is ever pressed, go to static mode
	call	Run_Ping	    ; Run the ping
	call	Multiply_171	    ; Convert time to distance
	call	Send_dist_to_LCD    ; Display on LCD
	
	; Wait for 0.5 second
	movlw	250
	call	Delay_ms
	call	Delay_ms
	
	; Check if D is still pressed
	tstfsz	PORTD, A
	bra     Static_Mode
	
	return
	
	

delay:	decfsz	delay_count, A	; decrement until zero
	bra	delay
	return

	end	rst