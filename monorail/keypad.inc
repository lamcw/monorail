#ifndef KEYPAD_INC
#define KEYPAD_INC

; IMPORTANT NOTICE: 
; The labels on PORTL are reversed, i.e., PLi is actually PL7-i (i=0, 1, бн, 7).  

; Board settings: 
; Connect the four columns C0~C3 of the keypad to PL3~PL0 of PORTL and the four rows R0~R3 to PL7~PL4 of PORTL.
; Connect LED0~LED7 of LEDs to PC0~PC7 of PORTC.
    
; For I/O registers located in extended I/O map, "IN", "OUT", "SBIS", "SBIC", 
; "CBI", and "SBI" instructions must be replaced with instructions that allow access to 
; extended I/O. Typically "LDS" and "STS" combined with "SBRS", "SBRC", "SBR", and "CBR".

.include "m2560def.inc"
.include "lcd.inc"

.def row = r17
.def col = r18
.def keypad_mask = r19
.def keypad_temp = r20

.equ PORTLDIR = 0xF0
.equ INITCOLMASK = 0xEF
.equ INITROWMASK = 0x01
.equ ROWMASK = 0x0F

.equ NUM_MODE = 1 << 0
.equ TEXT_MODE = 1 << 1

; main keeps scanning the keypad to find which key is pressed.
input:
    push    r16
    push    r17
    push    r18
    push    r19
    push    r20
    push    r21                         ; previous keypress
    push    r22                         ; stores result
    push    r23                         ; temp
    clr     r22
    clr     r25                         ; input str length

_input_main:
    ldi     keypad_mask, INITCOLMASK    ; initial column keypad_mask
    clr     col                         ; initial column

_colloop:
    sts     PORTL, keypad_mask          ; set column to keypad_mask value
                                        ; (sets column 0 off)
    ldi     r16, 0xFF                   ; implement a delay so the
                                        ; hardware can stabilize

_keypad_delay:
    dec     r16
    brne    _keypad_delay
    lds     r16, PINL                   ; read PORTL. Cannot use in 
    andi    r16, ROWMASK                ; read only the row bits
    cpi     r16, 0xF                    ; check if any rows are grounded
    breq    _nextcol                    ; if not go to the next column
    ldi     keypad_mask, INITROWMASK    ; initialise row check
    clr     row                         ; initial row

_rowloop:      
    mov     keypad_temp, r16
    and     keypad_temp, keypad_mask    ; check masked bit
    brne    _skipconv			        ; if the result is non-zero,
	                                    ; we need to look again
    rcall   convert                     ; if bit is clear, convert the bitcode
    rcall   sleep_100ms                 ; stabalize keypad
    rcall   sleep_50ms
    cpi     r16, 0xF                    ; if pressed hash
    breq    _end_input
    cpi     r24, TEXT_MODE
    breq    _handles_text_mode
    ; number input
    ldi     r23, 10
    mul     r22, r23
    mov     r22, r0
    add     r22, r16
    subi    r16, -'0'
    do_lcd_data r16
    rjmp    _input_main

_to_input_main:
    rjmp    _input_main

_handles_text_mode:
    cpi     r16, 0x0
    breq    _space
    cpi     r16, 0xA
    brlo    _select_char
    cpi     r16, 0xD                    ; checks if key entered is letter
    brlo    _lt_D
    rjmp    _input_main

_lt_D:
    cpi     r16, 0xA
    brge    _valid_select
    rjmp    _input_main

_valid_select:
    mov     r21, r16
    subi    r21, 0xA
    rjmp    _input_main

_select_char:
    subi    r16, 1
    ldi     r23, 3
    mul     r16, r23
    mov     r16, r0
    add     r16, r21
    subi    r16, -'A'
    rjmp    _end_select

_space:
    ldi     r16, ' '

_end_select:
    do_lcd_data r16
    st      x+, r16
    inc     r25
    clr     r21
    rjmp    _input_main

_skipconv:
    inc     row                         ; else move to the next row
    lsl     keypad_mask                 ; shift the keypad_mask to the next bit
    jmp     _rowloop

_nextcol:     
    cpi     col, 3                      ; check if we're on the last column
    breq    _to_input_main              ; if so, no buttons were pushed,
	                                    ; so start again.

    sec                                 ; else shift the column keypad_mask:
	                                    ; We must set the carry bit
    rol     keypad_mask                 ; and then rotate left by a bit,
	                                    ; shifting the carry into
	                                    ; bit zero. We need this to make
	                                    ; sure all the rows have
	                                    ; pull-up resistors
    inc     col                         ; increment column value
    jmp     _colloop                    ; and check the next column
	                                    ; convert function converts the row and column given to a
	                                    ; binary number and also outputs the value to PORTC.
	                                    ; Inputs come from registers row and col and output is in r16

_end_input:
    mov     r24, r22
    pop     r23
    pop     r22
    pop     r21
    pop     r20
    pop     r19
    pop     r18
    pop     r17
    pop     r16
    ret

convert:
    cpi     col, 3                      ; if column is 3 we have a letter
    breq    letters
    cpi     row, 3                      ; if row is 3 we have a symbol or 0
    breq    symbols
    mov     r16, row                    ; otherwise we have a number (1-9)
    lsl     r16                         ; r16 = row * 2
    add     r16, row                    ; r16 = row * 3
    add     r16, col                    ; add the column address
	                                    ; to get the offset from 1
    inc     r16                         ; add 1. Value of switch is
	                                    ; row*3 + col + 1.
    jmp     convert_end

letters:
    ldi     r16, 0xA
    add     r16, row                    ; increment from 0xA by the row value
    jmp     convert_end

symbols:
    cpi     col, 0                      ; check if we have a star
    breq    star
    cpi     col, 1                      ; or if we have zero
    breq    zero
    ldi     r16, 0xF                    ; we'll output 0xF for hash
    jmp     convert_end

star:
    ldi     r16, 0xE                    ; we'll output 0xE for star
    jmp     convert_end

zero:
    clr     r16                         ; set to zero

convert_end:
    ret                                 ; return to caller

#endif
