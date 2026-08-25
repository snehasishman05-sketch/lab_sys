;========================================================
; QUESTION 1
; Transfer 10 bytes from memory location 3000H
; to memory location 4000H
; Then multiply each element by 5 and add 10
;========================================================

.MODEL SMALL                    ; Use small memory model
.STACK 100H                     ; Allocate 256 bytes for stack

.DATA                           ; Beginning of data segment

.CODE                           ; Beginning of code segment

MAIN PROC                       ; Start of main procedure

    MOV AX, @DATA               ; Load address of data segment into AX
    MOV DS, AX                  ; Initialize DS with data segment address

    MOV SI, 3000H               ; SI points to source memory location 3000H
    MOV DI, 4000H               ; DI points to destination memory location 4000H
    MOV CX, 10                  ; We have to process 10 bytes

;--------------------------------------------------------
; STEP 1: Transfer 10 bytes from 3000H to 4000H
;--------------------------------------------------------

TRANSFER:

    MOV AL, [SI]                ; Read one byte from source into AL
    MOV [DI], AL                ; Copy that byte to destination

    INC SI                      ; Move source pointer to next byte
    INC DI                      ; Move destination pointer to next byte

    LOOP TRANSFER               ; Repeat until all 10 bytes are transferred


;--------------------------------------------------------
; STEP 2:
; Process the transferred data at 4000H
; Formula:
;             value = value * 5 + 10
;--------------------------------------------------------

    MOV DI, 4000H               ; Reset DI to beginning of destination
    MOV CX, 10                  ; Again process 10 elements

PROCESS:

    MOV AL, [DI]                ; Load destination element into AL

    MOV BL, 5                   ; Put multiplier 5 into BL
    MUL BL                      ; AX = AL × BL

    ADD AL, 10                  ; Add 10 to the result

    MOV [DI], AL                ; Store final result back into memory

    INC DI                      ; Move to next element

    LOOP PROCESS                ; Repeat for all 10 elements

    MOV AH, 4CH                 ; DOS function to terminate program
    INT 21H                     ; Call DOS interrupt

MAIN ENDP                       ; End of main procedure

END MAIN                        ; End of program