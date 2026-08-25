.MODEL SMALL
.STACK 100H

.DATA

.CODE
MAIN PROC

    MOV AX, @DATA
    MOV DS, AX

    ; Source = 3000H
    ; Destination = 4000H

    MOV SI, 3000H
    MOV DI, 4000H
    MOV CX, 10

NEXT:
    MOV AL, [SI]       ; Get byte from source

    MOV BL, AL
    MOV BH, 0

    ; Multiply by 5
    MOV AL, BL
    MOV AH, 0

    MOV DL, 5
    MUL DL             ; AX = AL * 5

    ; Add 10
    ADD AL, 10

    MOV [DI], AL       ; Store result at destination

    INC SI
    INC DI

    LOOP NEXT

    MOV AH, 4CH
    INT 21H

MAIN ENDP
END MAIN