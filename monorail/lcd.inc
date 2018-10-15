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
    push    r16
    ldi     r16, @0
    rcall   lcd_command
    rcall   lcd_wait
    pop     r16
.endmacro

.macro do_lcd_data
    push    r16
    mov     r16, @0
    rcall   lcd_data
    rcall   lcd_wait
    pop     r16
.endmacro

.macro do_lcd_data_i
    push    r16
    ldi     r16, @0
    rcall   lcd_data
    rcall   lcd_wait
    pop     r16
.endmacro

.macro prompt_pm
    ldi     zl, low(@0 << 1)
    ldi     zh, high(@0 << 1)
    rcall   print_str_pm
.endmacro

; @0: address of label, @1: index, @2: max size of str
.macro print_str_2d
    push    xl
    push    xh
    push    r17
    push    r0
    push    r1
    ldi     xl, low(@0)
    ldi     xh, high(@0)
    ldi     r17, @2
    mul     r17, @1
    add     xl, r0
    adc     xh, r1
    rcall   print_str_sm
    pop     r1
    pop     r0
    pop     r17
    pop     xh
    pop     xl
.endmacro

print_str_pm:
    push    r16
    lpm     r16, z+

_print_str_pm_loop:
    tst     r16
    breq    _end_print_str_pm
    do_lcd_data r16
    lpm     r16, z+
    rjmp    _print_str_pm_loop

_end_print_str_pm:
    pop     r16
    ret

print_str_sm:
    push    r16
    ld      r16, x+

_print_str_sm_loop:
    tst     r16
    breq    _end_print_str_sm
    do_lcd_data r16
    ld      r16, x+
    rjmp    _print_str_sm_loop

_end_print_str_sm:
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
