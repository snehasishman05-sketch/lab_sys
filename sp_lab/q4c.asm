;========================================================
; QUESTION 4
; Basic calculator for arithmetic operations
;
; Operations:
;     Addition
;     Subtraction
;     Multiplication
;     Division
;========================================================

.MODEL SMALL                    ; Use small memory model
.STACK 100H                     ; Allocate stack

.DATA                           ; Start data segment

NUM1 DB 20                      ; First number = 20
NUM2 DB 5                       ; Second number = 5

SUM DB ?                        ; Variable to store addition result

DIFF DB ?                       ; Variable to store subtraction result

PROD DW ?                       ; Variable to store multiplication result
                                ; DW because result can be 16-bit

QUOT DB ?                       ; Variable to store quotient

REM DB ?                        ; Variable to store remainder

.CODE                           ; Start code segment

MAIN PROC                       ; Start main procedure

    MOV AX, @DATA               ; Load data segment address
    MOV DS, AX                  ; Initialize DS


;========================================================
; ADDITION
; SUM = NUM1 + NUM2
;========================================================

    MOV AL, NUM1                ; Load NUM1 into AL

    ADD AL, NUM2                ; AL = NUM1 + NUM2

    MOV SUM, AL                 ; Store addition result


;========================================================
; SUBTRACTION
; DIFF = NUM1 - NUM2
;========================================================

    MOV AL, NUM1                ; Load NUM1 into AL

    SUB AL, NUM2                ; AL = NUM1 - NUM2

    MOV DIFF, AL                ; Store subtraction result


;========================================================
; MULTIPLICATION
; PROD = NUM1 × NUM2
;========================================================

    MOV AL, NUM1                ; Load first number into AL

    MOV BL, NUM2                ; Load second number into BL

    MUL BL                      ; AX = AL × BL

    MOV PROD, AX                ; Store 16-bit multiplication result


;========================================================
; DIVISION
; QUOT = NUM1 / NUM2
; REM  = NUM1 % NUM2
;========================================================

    MOV AL, NUM1                ; Load numerator into AL

    MOV AH, 00H                 ; Clear AH
                                ; AX now contains NUM1

    MOV BL, NUM2                ; Load divisor into BL

    DIV BL                      ; AL = quotient
                                ; AH = remainder

    MOV QUOT, AL                ; Store quotient

    MOV REM, AH                 ; Store remainder


;========================================================
; TERMINATE PROGRAM
;========================================================

    MOV AH, 4CH                 ; DOS terminate function

    INT 21H                     ; Call DOS interrupt

MAIN ENDP                       ; End main procedure

END MAIN                        ; End program