;========================================================
; QUESTION 5(a)
; STRLEN - Return length of a string
;
; Input:
;     SI → beginning of string
;
; Output:
;     AX → length of string
;========================================================

.MODEL SMALL                    ; Use small memory model
.STACK 100H                     ; Allocate stack

.DATA                           ; Start data segment

STR1 DB 'HELLO', 0              ; Store string with NULL terminator

LEN1 DW ?                       ; Variable to store string length

.CODE                           ; Start code segment

MAIN PROC                       ; Start main procedure

    MOV AX, @DATA               ; Load data segment address

    MOV DS, AX                  ; Initialize DS

    LEA SI, STR1                ; SI points to first character of string

    CALL STRLEN                 ; Call STRLEN procedure

    MOV LEN1, AX                ; Store returned length in LEN1

    MOV AH, 4CH                 ; DOS terminate function

    INT 21H                     ; Call DOS interrupt

MAIN ENDP                       ; End main procedure


;========================================================
; STRLEN PROCEDURE
;
; Counts characters until NULL character 00H is found
;========================================================

STRLEN PROC                     ; Start STRLEN procedure

    XOR AX, AX                  ; AX = 0
                                ; AX will store string length

LEN_LOOP:

    CMP BYTE PTR [SI], 0        ; Check whether current character is NULL

    JE LEN_DONE                 ; If NULL, string has ended

    INC AX                      ; Increase length by 1

    INC SI                      ; Move to next character

    JMP LEN_LOOP                ; Continue checking characters

LEN_DONE:

    RET                         ; Return with length in AX

STRLEN ENDP                     ; End STRLEN procedure

END MAIN                        ; End program