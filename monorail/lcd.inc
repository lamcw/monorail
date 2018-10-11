#ifndef LCD_INC
#define LCD_INC
; Board settings: 1. Connect LCD data pins D0-D7 to PORTF0-7.
; 2. Connect the four LCD control pins BE-RS to PORTA4-7.

.include "m2560def.inc"
.include "util.inc"

.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

.macro lcd_set
    sbi     PORTA, @0
.endmacro

.macro lcd_clr
    cbi     PORTA, @0
.endmacro

.macro do_lcd_command
    ldi     r16, @0
    rcall   lcd_command
    rcall   lcd_wait
.endmacro

.macro do_lcd_data
    mov     r16, @0
    rcall   lcd_data
    rcall   lcd_wait
.endmacro

.macro do_lcd_data_i
    ldi     r16, @0
    rcall   lcd_data
    rcall   lcd_wait
.endmacro

.macro prompt_pm
    ldi     zl, low(@0 << 1)
    ldi     zh, high(@0 << 1)
    rcall   print_str_pm
.endmacro

; print a 16 bit int
/* .macro print_int_16
    push    @0
    push    @1
    push    temp
    push    r0
    push    r1
    push    r2
    push    r3
    push    yl
    push    yh
    ldi     yl, low(@2)
    ldi     yh, high(@2)
    cpi     @0, 0
    clr     temp
    clr     r3
    cpc     @1, temp
    brge    _convert
    do_lcd_data_i '-'
    neg     @0
    neg     @1
    sbci    @1, 0

_convert:
    ldi     temp, 10
    movw    r1:r0, @1:@0
    rcall   div168
    movw    @1:@0, r1:r0
    mov     temp, r2
    subi    temp, -48
    st      y+, temp
    inc     r3
    cpi     @0, 0
    brlt    _end_convert
    breq    _end_convert
    rjmp    _convert

_end_convert:
    reverse_str @2 r3
    ldi     yl, low(@2)
    ldi     yh, high(@2)
    clr     temp

_print:
    cpi     temp, 3
    brge    _end_print
    ld      @0, y+
    do_lcd_data @0
    inc     temp
    rjmp    _print

_end_print:
    pop     yh
    pop     yl
    pop     r3
    pop     r2
    pop     r1
    pop     r0
    pop     temp
    pop     @1
    pop     @0
.endmacro

.macro reverse_str
    push    r16
    push    r17
    push    r18
    push    r19
    push    yl
    push    yh
    ldi     yl, low(@0)
    ldi     yh, high(@0)
    ld      r16, y
    
    clr     r16
    mov     r17, @1

_loop:
    cp      r16, r17
    brge    _end_reverse
    add     yl, r16
    ld      r18, y
    sub     yl, r16
    add     yl, r17
    ld      r19, y
    sub     yl, r17
    add     yl, r16
    st      y, r19
    sub     yl, r16
    add     yl, r17
    st      y, r18
    sub     yl, r17
    inc     r16
    subi    r17, 1
    rjmp    _loop

_end_reverse:
    pop     yh
    pop     yl
    pop     r19
    pop     r18
    pop     r17
    pop     r16
.endmacro */

print_str_pm:
    push    r16
    lpm     r16, z+

_print_loop:
    cpi     r16, 0
    breq    _end_print_str
    do_lcd_data r16
    lpm     r16, z+
    rjmp    _print_loop

_end_print_str:
    pop     r16
    ret

;
; Send a command to the LCD (r16)
;

lcd_command:
    out     PORTF, r16
    nop
    lcd_set LCD_E
    nop
    nop
    nop
    lcd_clr LCD_E
    nop
    nop
    nop
    ret

lcd_data:
    out     PORTF, r16
    lcd_set LCD_RS
    nop
    nop
    nop
    lcd_set LCD_E
    nop
    nop
    nop
    lcd_clr LCD_E
    nop
    nop
    nop
    lcd_clr LCD_RS
    ret

lcd_wait:
    push    r16
    clr     r16
    out     DDRF, r16
    out     PORTF, r16
    lcd_set LCD_RW

lcd_wait_loop:
    nop
    lcd_set LCD_E
    nop
    nop
    nop
    in      r16, PINF
    lcd_clr LCD_E
    sbrc    r16, 7
    rjmp    lcd_wait_loop
    lcd_clr LCD_RW
    ser     r16
    out     DDRF, r16
    pop     r16
    ret

#endif
