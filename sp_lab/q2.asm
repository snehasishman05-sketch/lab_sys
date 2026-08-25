.MODEL SMALL
.STACK 100H

.DATA

ARR DB 10, 5, 8, 3, 12, 7, 6, 15, 2, 9
    DB 20, 4, 11, 1, 14, 13, 18, 16, 19, 17

.CODE
MAIN PROC

    MOV AX, @DATA
    MOV DS, AX

    MOV SI, OFFSET ARR
    MOV CX, 19

NEXT:

    ; Determine whether this pair should be
    ; less-than or greater-than

    MOV AX, CX
    TEST AX, 1
    JZ GREATER

    ; Odd iteration:
    ; ARR[i] < ARR[i+1]

    MOV AL, [SI]
    MOV BL, [SI+1]

    CMP AL, BL
    JL OK

    ; Swap
    MOV [SI], BL
    MOV [SI+1], AL

    JMP OK

GREATER:

    ; Even iteration:
    ; ARR[i] > ARR[i+1]

    MOV AL, [SI]
    MOV BL, [SI+1]

    CMP AL, BL
    JG OK

    ; Swap
    MOV [SI], BL
    MOV [SI+1], AL

OK:
    INC SI
    LOOP NEXT

    MOV AH, 4CH
    INT 21H

MAIN ENDP
END MAIN