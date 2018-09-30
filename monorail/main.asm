;
; monorail.asm
;
; Created: 9/29/2018 12:48:41 PM
; Author : cwlam
;

.include "m2560def.inc"

.include "keypad.asm"
.include "lcd.asm"

; Replace with your application code
start:
    inc r16
    rjmp start