#ifndef UTIL_INC
#define UTIL_INC

.include "m2560def.inc"

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4   ; 4 cycles per iteration - setup/call-return overhead

sleep_1ms:
    push    r24
    push    r25
    ldi     r25, high(DELAY_1MS)
    ldi     r24, low(DELAY_1MS)

delayloop_1ms:
    sbiw    r25:r24, 1
    brne    delayloop_1ms
    pop     r25
    pop     r24
    ret

sleep_5ms:
    rcall   sleep_1ms
    rcall   sleep_1ms
    rcall   sleep_1ms
    rcall   sleep_1ms
    rcall   sleep_1ms
    ret

sleep_50ms:
    rcall   sleep_5ms
    rcall   sleep_5ms
    rcall   sleep_5ms
    rcall   sleep_5ms
    rcall   sleep_5ms
    rcall   sleep_5ms
    rcall   sleep_5ms
    rcall   sleep_5ms
    rcall   sleep_5ms
    rcall   sleep_5ms
    ret

sleep_100ms:
    rcall   sleep_50ms
    rcall   sleep_50ms
    ret

; 16/8 division, 16 bit result, 8 bit remainder
; divide r1:r0 by r16, quotient in r1:r0, remainder in r2
div168:
    clr     r2               ; clear remainder
    ldi     r25, 0x10        ; 16 bits
_d161:
    lsl     r0
    rol     r1
    rol     r2               ; next dividend bit to r2
    brcs    _d162            ; this should never, ever, happen
    cp      r2, r16          ; trial subtraction
    brcs    _d163            ; not big enough
_d162:
    sub     r2, r16          ; ok, subtract it
    inc     r0               ; add this power of 2 to quotient
_d163:
    dec     r25              ; count bit
    brne    _d161            ; do until done
    ret                      ; remainder in r2

#endif
