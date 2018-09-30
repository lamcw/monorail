;
; monorail.asm
;
; Author : thomas, akshin
;

.include "m2560def.inc"

.def temp = r16

.dseg

.cseg
.org 0
jmp RESET
.org INT0addr
jmp EXT_INT0
.org INT1addr
jmp EXT_INT1
.org OVF0addr
jmp TimerOVF

.include "keypad.asm"
.include "lcd.asm"
.include "timer.asm"

RESET:
    ; init stack
    ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp

	ldi temp, PORTLDIR          ; columns are outputs, rows are inputs
	STS DDRL, temp              ; cannot use out

	ser temp
    out DDRF, temp
	out DDRA, temp

	clr temp
	out PORTF, temp
	out PORTA, temp
    out DDRD, temp
    out PORTD, temp

    out TCCR0A, temp
	ldi temp, 0b10
	out TCCR0B, temp
	ldi temp, (1 << TOIE0)
	sts TIMSK0, temp            ; enable Timer0 overflow interrupt

    ; the built-in constants ISC10=2 and ISC00=0 are their bit numbers in EICRA register
    ldi temp, (2 << ISC10) | (2 << ISC00)
    ; temp = 0b00001010 so both interrupts are configured as falling edge triggered interrupts
	sts EICRA, temp
	in temp, EIMSK
	ori temp, (1 << INT0) | (1 << INT1)
	out EIMSK, temp	            ; enable EXT_INT0 and EXT_INT1

	sei

    do_lcd_command 0b00111000   ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000   ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000   ; 2x5x7
	do_lcd_command 0b00111000   ; 2x5x7
	do_lcd_command 0b00001000   ; display off?
	do_lcd_command 0b00000001   ; clear display
	do_lcd_command 0b00000110   ; increment, no display shift
	do_lcd_command 0b00001110   ; Cursor on, bar, no blink

; handle PB0 interrupt
EXT_INT0:

; handle PB1 interrupt
EXT_INT1:

; handle timer0 overflow interrupt
TimerOVF:

main:

end:
    rjmp end