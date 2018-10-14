#ifndef MOTOR_INC
#define MOTOR_INC

.include "m2560def.inc"

.equ MOTOR_SPEED = 60

motor_rotate:
    push    r16

    ldi     r16, MOTOR_SPEED
    sts     OCR3BL, r16
    clr     r16
    sts     OCR3BH, r16

    pop     r16
    ret

motor_stop:
    push    r16

    clr     r16
    sts     OCR3BL, r16
    sts     OCR3BH, r16

    pop     r16
    ret

#endif
