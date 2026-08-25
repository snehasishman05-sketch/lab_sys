.MODEL SMALL
.STACK 100H

.DATA

STR1 DB 'HELLO', 0
STR2 DB 'HELLO', 0

LEN1 DW ?
CMP_RESULT DB ?
REVSTR DB 'ASSEMBLY', 0

.CODE
MAIN PROC

    MOV AX, @DATA
    MOV DS, AX

    ;================================
    ; STRLEN
    ;================================

    LEA SI, STR1
    CALL STRLEN

    MOV LEN1, AX


    ;================================
    ; STRCMP
    ;================================

    LEA SI, STR1
    LEA DI, STR2

    CALL STRCMP

    MOV CMP_RESULT, AL


    ;================================
    ; STRREV
    ;================================

    LEA SI, REVSTR
    CALL STRREV


    MOV AH, 4CH
    INT 21H

MAIN ENDP


;========================================
; STRLEN
;
; Input:
;   DS:SI -> null terminated string
;
; Output:
;   AX = length
;========================================

STRLEN PROC

    XOR AX, AX

LEN_LOOP:

    CMP BYTE PTR [SI], 0
    JE LEN_DONE

    INC AX
    INC SI

    JMP LEN_LOOP

LEN_DONE:

    RET

STRLEN ENDP


;========================================
; STRCMP
;
; Input:
;   DS:SI -> first string
;   DS:DI -> second string
;
; Output:
;   AL = 0  if equal
;   AL = 1  if first > second
;   AL = FFH if first < second
;========================================

STRCMP PROC

COMPARE:

    MOV AL, [SI]
    MOV BL, [DI]

    CMP AL, BL

    JNE NOT_EQUAL

    CMP AL, 0
    JE EQUAL

    INC SI
    INC DI

    JMP COMPARE


NOT_EQUAL:

    JA FIRST_GREATER

    MOV AL, 0FFH
    RET


FIRST_GREATER:

    MOV AL, 01H
    RET


EQUAL:

    MOV AL, 00H
    RET

STRCMP ENDP


;========================================
; STRREV
;
; Input:
;   DS:SI -> null terminated string
;
; Reverses string in place
;========================================

STRREV PROC

    ; Find end of string

    MOV DI, SI

FIND_END:

    CMP BYTE PTR [DI], 0
    JE END_FOUND

    INC DI
    JMP FIND_END


END_FOUND:

    DEC DI

    ; SI = beginning
    ; DI = last character

REVERSE_LOOP:

    CMP SI, DI
    JAE REVERSE_DONE

    MOV AL, [SI]
    MOV BL, [DI]

    MOV [SI], BL
    MOV [DI], AL

    INC SI
    DEC DI

    JMP REVERSE_LOOP


REVERSE_DONE:

    RET

STRREV ENDP

END MAIN