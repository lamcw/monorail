;
; monorail.asm
;
; Author : thomas, akshin
;

.include "m2560def.inc"

.def temp = r16

.equ WAIT_5 = 1 << 0
.equ TRAVEL = 1 << 1
.equ STOP = 1 << 2

.dseg
; configs
max_station: .byte 1
station_names: .byte 110
station_travel_times: .byte 10
stop_time: .byte 1

stage: .byte 1
current_station: .byte 1
request_stop: .byte 1

enable_timer: .byte 1
timer0ovf_count: .byte 2
timer0ovf_count_led: .byte 2
time_passed: .byte 2

is_led_on: .byte 1

.cseg
.org 0
    jmp     RESET
.org INT0addr
    jmp     EXT_INT0
.org INT1addr
    jmp     EXT_INT1
.org OVF0addr
    jmp     TIMER0_OVF

INVALID: .db "!", 0
MAX_STATION_PROMPT: .db "max stations:", 0
STATION_NAME_PROMPT: .db "name", 0, 0
STATION_TIME_PROMPT: .db "time", 0, 0
STOP_TIME_PROMPT: .db "stop time:", 0, 0
WAIT_PROMPT: .db "wait 5 sec", 0, 0

.include "keypad.inc"
.include "lcd.inc"
.include "timer.inc"
.include "util.inc"
.include "motor.inc"

RESET:
    ; init stack
    ldi     temp, low(RAMEND)
    out     SPL, temp
    ldi     temp, high(RAMEND)
    out     SPH, temp

    ldi     temp, PORTLDIR          ; columns are outputs, rows are inputs
    sts     DDRL, temp              ; cannot use out

    ser     temp
    out     DDRF, temp
    out     DDRA, temp
    out     DDRE, temp
    out     DDRC, temp

    clr     temp
    sts     OCR3BL, temp
    sts     OCR3BH, temp
    ldi     temp, (1 << CS30)       ; no prescaling
    sts     TCCR3B, temp
    ldi     temp, (1 << WGM30) | (1 << COM3B1)
    ; WGM30 = 1: phase correct PWM
    ; COM3B1 = 1: OC3B override the normal port functionality of the I/O pin PE2
    sts     TCCR3A, temp

    clr     temp
    out     PORTF, temp
    out     PORTA, temp
    out     DDRD, temp
    out     PORTD, temp

    ; the built-in constants ISC10=2 and ISC00=0 are their bit numbers in EICRA register
    ldi     temp, (2 << ISC10) | (2 << ISC00)
    ; temp = 0b00001010 so both interrupts are configured as falling edge triggered interrupts
    sts     EICRA, temp
    in      temp, EIMSK
    ori     temp, (1 << INT0) | (1 << INT1)
    out     EIMSK, temp	            ; enable EXT_INT0 and EXT_INT1

    do_lcd_command 0b00111000       ; 2x5x7
    rcall   sleep_5ms
    do_lcd_command 0b00111000       ; 2x5x7
    rcall   sleep_1ms
    do_lcd_command 0b00111000       ; 2x5x7
    do_lcd_command 0b00111000       ; 2x5x7
    do_lcd_command 0b00001000       ; display off?
    do_lcd_command 0b00000001       ; clear display
    do_lcd_command 0b00000110       ; increment, no display shift
    do_lcd_command 0b00001110       ; Cursor on, bar, no blink

    clr     temp
    out     TCCR0A, temp
    ldi     temp, 0b10
    out     TCCR0B, temp
    ldi     temp, (1 << TOIE0)
    sts     TIMSK0, temp            ; enable Timer0 overflow interrupt
    sei

    clr     temp
    sts     timer0ovf_count, temp
    sts     timer0ovf_count+1, temp
    sts     timer0ovf_count_led, temp
    sts     timer0ovf_count_led+1, temp
    sts     time_passed, temp
    sts     time_passed+1, temp
    sts     stage, temp
    sts     enable_timer, temp
    sts     current_station, temp
    sts     request_stop, temp
    sts     is_led_on, temp
    rjmp    main

; handle PB0 interrupt
EXT_INT0:
    push    temp
    in      temp, SREG
    push    temp

    ldi     temp, 1
    sts     request_stop, temp

    pop     temp
    out     SREG, temp
    pop     temp
    reti

; handle PB1 interrupt
EXT_INT1:
    push    temp
    in      temp, SREG
    push    temp

    ldi     temp, 1
    sts     request_stop, temp

    pop     temp
    out     SREG, temp
    pop     temp
    reti

_to_end_timer0_ovf:
    rjmp    _end_timer0_ovf
_to_store_ovf_count:
    rjmp    _store_ovf_count
; handle timer0 overflow interrupt
TIMER0_OVF:
    push    temp
    in      temp, SREG
    push    temp
    push    r23
    push    r24
    push    r25
    push    r28
    push    r29

    lds     temp, enable_timer          ; if timer not enabled
    tst     temp
    breq    _to_end_timer0_ovf

    lds     r23, stage
    cpi     r23, TRAVEL
    breq    _turn_led_off
    cpi     r23, STOP
    brne    _timer
    lds     r28, timer0ovf_count_led
    lds     r29, timer0ovf_count_led+1
    adiw    r29:r28, 1
    cpi     r28, low(INT_SEC_COUNT / 3)
    ldi     temp, high(INT_SEC_COUNT / 3)
    cpc     r29, temp
    brge    _toggle_led
    rjmp    _timer

_toggle_led:
    clr     temp
    clr     r28
    clr     r29
    lds     temp, is_led_on
    tst     temp
    brne    _turn_led_off
    ldi     temp, 0b00000011
    out     PORTC, temp
    ldi     temp, 1
    sts     is_led_on, temp
    rjmp    _timer

_turn_led_off:
    clr     temp
    out     PORTC, temp
    sts     is_led_on, temp
   
_timer:
    lds     r24, timer0ovf_count
    lds     r25, timer0ovf_count+1
    adiw    r25:r24, 1
    cpi     r24, low(INT_SEC_COUNT)
    ldi     temp, high(INT_SEC_COUNT)
    cpc     r25, temp
    brlo    _store_ovf_count            ; if less than one sec has passed

    lds     r28, time_passed
    lds     r29, time_passed+1          ; one sec has passed
    adiw    r29:r28, 1
    sts     time_passed, r28
    sts     time_passed+1, r29
    clr     r24
    clr     r25
    cpi     r23, WAIT_5
    breq    _handle_wait_5
    rjmp    _store_ovf_count

_handle_wait_5:
    cpi     r28, 5
    brne    _store_ovf_count

    do_lcd_command 0b00000001
    clr     temp
    sts     time_passed, temp
    sts     time_passed+1, temp         ; resets time
    sts     current_station, temp       ; station starts from 0
    ldi     temp, TRAVEL
    sts     stage, temp
    rcall   motor_rotate

_store_ovf_count:
    sts     timer0ovf_count, r24
    sts     timer0ovf_count+1, r25
    sts     timer0ovf_count_led, r28
    sts     timer0ovf_count_led+1, r29

_end_timer0_ovf:
    pop     r29
    pop     r28
    pop     r25
    pop     r24
    pop     r23
    pop     temp
    out     SREG, temp
    pop     temp
    reti

main:
    rcall   step_1
    rcall   step_2
    rcall   step_3
    rcall   step_4
    do_lcd_command 0b00000001
    prompt_pm WAIT_PROMPT
    ldi     temp, WAIT_5
    sts     stage, temp
    ldi     temp, 1
    sts     enable_timer, temp

_main_loop:
    lds     temp, stage
    cpi     temp, WAIT_5
    breq    _main_loop
    ldi     r24, NUM_MODE
    rcall   input
    cpi     temp, TRAVEL
    breq    _main_handle_stop
    cpi     temp, STOP
    breq    _main_handle_travel

_main_handle_stop:
    rcall   motor_stop
    ldi     temp, STOP
    sts     stage, temp
    rjmp    _end_main_loop

_main_handle_travel:
    rcall   motor_rotate
    ldi     temp, TRAVEL
    sts     stage, temp

_end_main_loop:
    rjmp    _main_loop

step_1:
    do_lcd_command 0b00000001
    prompt_pm MAX_STATION_PROMPT
    ldi     r24, NUM_MODE
    rcall   input

_check_step_1:                          ; 0 < input <= 10
    cpi     r24, 11
    brge    _do_step_1
    cpi     r24, 1
    brlo    _do_step_1
    rjmp    _end_step_1

_do_step_1:
    do_lcd_command 0b00000001
    prompt_pm INVALID
    prompt_pm MAX_STATION_PROMPT
    ldi     r24, NUM_MODE
    rcall   input
    rjmp    _check_step_1

_end_step_1:
    sts     max_station, r24
    ret

_to_end_step_2:
    jmp     _end_step_2

step_2:
    clr     temp

_step_2_loop:                           ; keeps receiving input until correct
    lds     r18, max_station
    cp      temp, r18
    brge    _to_end_step_2
    do_lcd_command 0b00000001
    prompt_pm STATION_NAME_PROMPT
    mov     r17, temp
    subi    r17, -'0' - 1
    do_lcd_data r17
    do_lcd_data_i ':'
    ldi     r24, TEXT_MODE
    ldi     xl, low(station_names)
    ldi     xh, high(station_names)
    ldi     r18, 11
    mul     temp, r18
    add     xl, r0
    rcall   input

_check_step_2:
    cpi     r25, 11
    brge    _do_step_2
    cpi     r25, 1
    brlo    _do_step_2
    rjmp    _end_step_2_loop

_do_step_2:
    do_lcd_command 0b00000001
    prompt_pm INVALID
    prompt_pm STATION_NAME_PROMPT
    do_lcd_data r17
    do_lcd_data_i ':'
    ldi     r24, TEXT_MODE
    ldi     xl, low(station_names)
    ldi     xh, high(station_names)
    ldi     r18, 11
    mul     temp, r18
    add     xl, r0
    adc     xh, r1
    rcall   input
    rjmp    _check_step_2

_end_step_2_loop:
    clr     r18
    st      x, r18                      ; write terminating char
    ldi     xl, low(station_names)
    ldi     xh, high(station_names)
    ldi     r18, 11
    mul     temp, r18
    add     xl, r0
    adc     xh, r1
    inc     temp
    rjmp    _step_2_loop

_end_step_2:
    ret

_to_end_step_3:
    rjmp    _end_step_3

step_3:
    clr     temp
    ldi     xl, low(station_travel_times)
    ldi     xh, high(station_travel_times)

_step_3_loop:
    lds     r19, max_station
    cp      temp, r19
    brge    _to_end_step_3
    do_lcd_command 0b00000001
    prompt_pm STATION_TIME_PROMPT
    mov     r20, r19
    subi    r20, 1
    cp      temp, r20
    breq    _last
    mov     r17, temp
    subi    r17, -'0' - 1
    mov     r18, temp
    subi    r18, -'0' - 2
    rjmp    _step_3_prompt

_last:
    mov     r17, temp
    subi    r17, -'0' - 1
    ldi     r18, '1'

_step_3_prompt:
    do_lcd_data r17
    do_lcd_data_i '-'
    do_lcd_data_i '>'
    do_lcd_data r18
    do_lcd_data_i ':'
    ldi     r24, NUM_MODE
    rcall   input

_check_step_3:
    cpi     r24, 11
    brge    _do_step_3
    cpi     r24, 1
    brlo    _do_step_3
    rjmp    _end_step_3_loop

_do_step_3:
    do_lcd_command 0b00000001
    prompt_pm INVALID
    prompt_pm STATION_TIME_PROMPT
    do_lcd_data r17
    do_lcd_data_i '-'
    do_lcd_data_i '>'
    do_lcd_data r18
    do_lcd_data_i ':'
    ldi     r24, NUM_MODE
    rcall   input
    rjmp    _check_step_3

_end_step_3_loop:
    st      x+, r22
    inc     temp
    rjmp    _step_3_loop

_end_step_3:
    ret

step_4:
    do_lcd_command 0b00000001
    prompt_pm STOP_TIME_PROMPT
    ldi     r24, NUM_MODE
    rcall   input

_check_step_4:
    cpi     r24, 6
    brge    _do_step_4
    cpi     r24, 2
    brlo    _do_step_4
    rjmp    _end_step_4

_do_step_4:
    do_lcd_command 0b00000001
    prompt_pm INVALID
    prompt_pm STOP_TIME_PROMPT
    ldi     r24, NUM_MODE
    rcall   input
    rjmp    _check_step_4

_end_step_4:
    sts     stop_time, r24
    ret