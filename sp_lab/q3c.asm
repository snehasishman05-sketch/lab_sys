;========================================================
; QUESTION 3
; Convert hexadecimal number into equivalent ASCII
;
; Example:
;     3AH
;
; Output:
;     '3' and 'A'
;========================================================

.MODEL SMALL                    ; Use small memory model
.STACK 100H                     ; Allocate stack

.DATA                           ; Start data segment

HEXNUM DB 3AH                   ; Hexadecimal number = 3AH

ASCII DB 2 DUP(?)               ; Reserve two bytes for ASCII result

.CODE                           ; Start code segment

MAIN PROC                       ; Start main procedure

    MOV AX, @DATA               ; Load data segment address
    MOV DS, AX                  ; Initialize DS


;--------------------------------------------------------
; Convert upper hexadecimal digit
;--------------------------------------------------------

    MOV AL, HEXNUM              ; Load 3AH into AL

    MOV AH, AL                  ; Copy hexadecimal number into AH

    AND AH, 0F0H                ; Keep only upper nibble
                                ; 3AH becomes 30H

    MOV CL, 4                   ; We need to shift right 4 positions

    SHR AH, CL                  ; Move upper nibble to lower position
                                ; 30H becomes 03H

    MOV AL, AH                  ; Put nibble into AL

    CALL HEX_ASCII              ; Convert 0-15 into ASCII

    MOV ASCII, AL               ; Store first ASCII character


;--------------------------------------------------------
; Convert lower hexadecimal digit
;--------------------------------------------------------

    MOV AL, HEXNUM              ; Load original hexadecimal number

    AND AL, 0FH                 ; Keep only lower nibble
                                ; 3AH becomes 0AH

    CALL HEX_ASCII              ; Convert 0AH into ASCII 'A'

    MOV ASCII+1, AL             ; Store second ASCII character


;--------------------------------------------------------
; Terminate program
;--------------------------------------------------------

    MOV AH, 4CH                 ; DOS terminate function
    INT 21H                     ; Call DOS interrupt

MAIN ENDP                       ; End main procedure


;========================================================
; HEX_ASCII PROCEDURE
;
; Input:
;     AL = hexadecimal value from 0 to 15
;
; Output:
;     AL = corresponding ASCII character
;
; 0-9  → 30H-39H
; A-F  → 41H-46H
;========================================================

HEX_ASCII PROC                  ; Start HEX_ASCII procedure

    CMP AL, 9                   ; Check whether value is 0-9

    JBE DIGIT                   ; If <= 9, it is a numeric digit

    ADD AL, 37H                 ; Convert 10-15 to A-F
                                ; 10 + 37H = 41H = 'A'

    RET                         ; Return from procedure

DIGIT:

    ADD AL, 30H                 ; Convert 0-9 to ASCII

    RET                         ; Return from procedure

HEX_ASCII ENDP                  ; End HEX_ASCII procedure

END MAIN                        ; End program