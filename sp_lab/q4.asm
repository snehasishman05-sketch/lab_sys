.MODEL SMALL
.STACK 100H

.DATA

HEXNUM DB 3AH

ASCII  DB 2 DUP(?)

.CODE
MAIN PROC

    MOV AX, @DATA
    MOV DS, AX

    MOV AL, HEXNUM

    ; Convert upper nibble
    MOV AH, AL
    AND AH, 0F0H
    MOV CL, 4
    SHR AH, CL

    CALL HEX_ASCII

    MOV ASCII, AL

    ; Convert lower nibble
    MOV AL, HEXNUM
    AND AL, 0FH

    CALL HEX_ASCII

    MOV ASCII+1, AL

    MOV AH, 4CH
    INT 21H

MAIN ENDP


;----------------------------------
; HEX_ASCII
; Converts value 0-15 in AL
; into ASCII character
;----------------------------------

HEX_ASCII PROC

    CMP AL, 9
    JBE DIGIT

    ADD AL, 37H
    RET

DIGIT:
    ADD AL, 30H
    RET

HEX_ASCII ENDP

END MAIN