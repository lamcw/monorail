; Board settings: 1. Connect LCD data pins D0-D7 to PORTF0-7.
; 2. Connect the four LCD control pins BE-RS to PORTA4-7.
  
.include "m2560def.inc"

.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

.macro lcd_set
    sbi PORTA, @0
.endmacro

.macro lcd_clr
    cbi PORTA, @0
.endmacro

.macro do_lcd_command
    ldi r16, @0
    rcall lcd_command
    rcall lcd_wait
.endmacro

.macro do_lcd_data
    ldi r16, @0
    rcall lcd_data
    rcall lcd_wait
.endmacro

halt:
    rjmp halt

;
; Send a command to the LCD (r16)
;

lcd_command:
    out PORTF, r16
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
    out PORTF, r16
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
    push r16
    clr r16
    out DDRF, r16
    out PORTF, r16
    lcd_set LCD_RW

lcd_wait_loop:
    nop
    lcd_set LCD_E
    nop
    nop
    nop
    in r16, PINF
    lcd_clr LCD_E
    sbrc r16, 7
    rjmp lcd_wait_loop
    lcd_clr LCD_RW
    ser r16
    out DDRF, r16
    pop r16
    ret