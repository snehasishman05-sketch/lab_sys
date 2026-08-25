;========================================================
; QUESTION 2
; Arrange 20 numbers in zig-zag order
;
; Required condition:
;
; A[0] < A[1] > A[2] < A[3] > A[4] ...
;
;========================================================

.MODEL SMALL                    ; Use small memory model
.STACK 100H                     ; Allocate stack space

.DATA                           ; Start data segment

;--------------------------------------------------------
; Declare an array containing 20 numbers
;--------------------------------------------------------

ARR DB 10, 5, 8, 3, 12, 7, 6, 15, 2, 9
    DB 20, 4, 11, 1, 14, 13, 18, 16, 19, 17

.CODE                           ; Start code segment

MAIN PROC                       ; Start main procedure

    MOV AX, @DATA               ; Load data segment address
    MOV DS, AX                  ; Initialize DS

    LEA SI, ARR                 ; SI points to first element of array

    MOV CX, 19                  ; There are 19 adjacent pairs

    MOV BL, 0                   ; BL = 0 means first comparison is <
                                ; BL = 1 means next comparison is >

NEXT:

    MOV AL, [SI]                ; Load current element into AL
    MOV AH, [SI+1]              ; Load next element into AH

    CMP BL, 0                   ; Check whether current condition is <

    JE LESS_CASE                ; If BL = 0, go to less-than case

;--------------------------------------------------------
; GREATER CASE
; Required:
; A[i] > A[i+1]
;--------------------------------------------------------

GREATER_CASE:

    CMP AL, AH                  ; Compare A[i] with A[i+1]

    JG NO_SWAP                  ; If A[i] > A[i+1], no swap required

    MOV [SI], AH                ; Put A[i+1] into A[i]
    MOV [SI+1], AL              ; Put A[i] into A[i+1]

    JMP NO_SWAP                 ; Continue execution

;--------------------------------------------------------
; LESS CASE
; Required:
; A[i] < A[i+1]
;--------------------------------------------------------

LESS_CASE:

    CMP AL, AH                  ; Compare A[i] with A[i+1]

    JL NO_SWAP                  ; If A[i] < A[i+1], no swap required

    MOV [SI], AH                ; Put A[i+1] into A[i]
    MOV [SI+1], AL              ; Put A[i] into A[i+1]

;--------------------------------------------------------
; Move to next pair
;--------------------------------------------------------

NO_SWAP:

    INC SI                      ; Move SI to next array element

    XOR BL, 1                   ; Toggle BL
                                ; 0 becomes 1
                                ; 1 becomes 0

    LOOP NEXT                   ; Repeat for remaining pairs

    MOV AH, 4CH                 ; DOS terminate function
    INT 21H                     ; Call DOS interrupt

MAIN ENDP                       ; End main procedure

END MAIN                        ; End program