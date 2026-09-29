;=========================================================
; SIMPLE COMMAND-LINE SHELL EMULATOR
; MASM 8086 / DOS
;
; Commands:
;   DIR
;   TYPE <filename>
;   COPY <source> <destination>
;   EXIT
;
; DOS services used through INT 21H
;=========================================================

.MODEL SMALL
.STACK 100H

.DATA

;---------------------------------------------------------
; Prompt and messages
;---------------------------------------------------------

prompt      DB 13,10,'MY-SHELL> $'

msgUnknown  DB 13,10,'Invalid command.$'
msgNoFile   DB 13,10,'File name missing.$'
msgCopyErr  DB 13,10,'COPY failed.$'
msgTypeErr  DB 13,10,'Unable to open/read file.$'
msgCopied   DB 13,10,'File copied successfully.$'

;---------------------------------------------------------
; Mock DIR listing
;---------------------------------------------------------

dirMsg      DB 13,10,'Directory listing:',13,10
            DB '--------------------------------',13,10
            DB 'FILE1.TXT',13,10
            DB 'FILE2.TXT',13,10
            DB 'DATA.DAT',13,10
            DB 'README.TXT',13,10
            DB 'PROGRAM.ASM',13,10
            DB '--------------------------------',13,10,'$'

;---------------------------------------------------------
; Input buffer for DOS function 0AH
;
; First byte  = maximum characters
; Second byte = number of characters entered
; Remaining   = input characters
;---------------------------------------------------------

inputBuffer DB 100
            DB 0
            DB 100 DUP(0)

;---------------------------------------------------------
; Temporary buffers
;---------------------------------------------------------

filename1   DB 64 DUP(0)
filename2   DB 64 DUP(0)

; Buffer used when reading file contents
fileBuffer  DB 512 DUP(0)

; File handles
sourceHandle DW ?
destHandle   DW ?

;---------------------------------------------------------
; CR/LF
;---------------------------------------------------------

newline     DB 13,10,'$'

.CODE

;=========================================================
; MAIN
;=========================================================

MAIN PROC

    MOV AX, @DATA
    MOV DS, AX

;---------------------------------------------------------
; Main shell loop
;---------------------------------------------------------

SHELL_LOOP:

    ; Display prompt
    LEA DX, prompt
    MOV AH, 09H
    INT 21H

    ; Read command from keyboard
    LEA DX, inputBuffer
    MOV AH, 0AH
    INT 21H

    ; Add NULL character at end of input
    XOR BX, BX
    MOV BL, inputBuffer[1]

    LEA SI, inputBuffer + 2
    ADD SI, BX
    MOV BYTE PTR [SI], 0

    ; If empty command, show prompt again
    CMP BL, 0
    JE SHELL_LOOP

    ; Convert command to uppercase
    CALL ConvertUpper

;---------------------------------------------------------
; Check EXIT
;---------------------------------------------------------

    LEA SI, inputBuffer + 2
    LEA DI, exitCmd
    CALL CompareCommand

    CMP AL, 1
    JE EXIT_SHELL

;---------------------------------------------------------
; Check DIR
;---------------------------------------------------------

    LEA SI, inputBuffer + 2
    LEA DI, dirCmd
    CALL CompareCommand

    CMP AL, 1
    JE DO_DIR

;---------------------------------------------------------
; Check TYPE
;---------------------------------------------------------

    LEA SI, inputBuffer + 2
    LEA DI, typeCmd
    CALL CompareCommand

    CMP AL, 1
    JE DO_TYPE

;---------------------------------------------------------
; Check COPY
;---------------------------------------------------------

    LEA SI, inputBuffer + 2
    LEA DI, copyCmd
    CALL CompareCommand

    CMP AL, 1
    JE DO_COPY

;---------------------------------------------------------
; Unknown command
;---------------------------------------------------------

    LEA DX, msgUnknown
    MOV AH, 09H
    INT 21H

    JMP SHELL_LOOP


;=========================================================
; EXIT
;=========================================================

EXIT_SHELL:

    MOV AH, 4CH
    MOV AL, 00H
    INT 21H


;=========================================================
; DIR COMMAND
;=========================================================

DO_DIR:

    LEA DX, dirMsg
    MOV AH, 09H
    INT 21H

    JMP SHELL_LOOP


;=========================================================
; TYPE COMMAND
;
; Syntax:
; TYPE filename
;=========================================================

DO_TYPE:

    ; SI points to beginning of input
    LEA SI, inputBuffer + 2

    ; Skip "TYPE"
    ADD SI, 4

;---------------------------------------------------------
; Skip spaces
;---------------------------------------------------------

TYPE_SKIP_SPACE:

    CMP BYTE PTR [SI], ' '
    JNE TYPE_GET_NAME

    INC SI
    JMP TYPE_SKIP_SPACE


;---------------------------------------------------------
; Check filename exists
;---------------------------------------------------------

TYPE_GET_NAME:

    CMP BYTE PTR [SI], 0
    JE TYPE_NO_FILE

;---------------------------------------------------------
; Copy filename to filename1
;---------------------------------------------------------

    LEA DI, filename1

TYPE_COPY_NAME:

    MOV AL, [SI]

    CMP AL, 0
    JE TYPE_NAME_DONE

    CMP AL, ' '
    JE TYPE_NAME_DONE

    MOV [DI], AL

    INC SI
    INC DI

    JMP TYPE_COPY_NAME

TYPE_NAME_DONE:

    MOV BYTE PTR [DI], 0

;---------------------------------------------------------
; Open file
;
; AH = 3DH
; AL = 00H -> read only
; DS:DX = filename
;---------------------------------------------------------

    LEA DX, filename1
    MOV AX, 3D00H
    INT 21H

    JC TYPE_ERROR

    MOV sourceHandle, AX

;---------------------------------------------------------
; Read file
;---------------------------------------------------------

TYPE_READ:

    MOV BX, sourceHandle

    LEA DX, fileBuffer

    MOV CX, 512

    MOV AH, 3FH
    INT 21H

    JC TYPE_ERROR_CLOSE

    ; AX = number of bytes read
    CMP AX, 0
    JE TYPE_CLOSE

    ; Save number of bytes
    MOV CX, AX

    ; Write file contents to screen
    MOV BX, 1          ; STDOUT

    MOV AH, 40H
    INT 21H

    JMP TYPE_READ


;---------------------------------------------------------
; Close file
;---------------------------------------------------------

TYPE_CLOSE:

    MOV BX, sourceHandle
    MOV AH, 3EH
    INT 21H

    JMP SHELL_LOOP


TYPE_ERROR_CLOSE:

    MOV BX, sourceHandle
    MOV AH, 3EH
    INT 21H

TYPE_ERROR:

    LEA DX, msgTypeErr
    MOV AH, 09H
    INT 21H

    JMP SHELL_LOOP


TYPE_NO_FILE:

    LEA DX, msgNoFile
    MOV AH, 09H
    INT 21H

    JMP SHELL_LOOP


;=========================================================
; COPY COMMAND
;
; Syntax:
; COPY source destination
;=========================================================

DO_COPY:

    LEA SI, inputBuffer + 2

    ; Skip "COPY"
    ADD SI, 4


;---------------------------------------------------------
; Skip spaces before source
;---------------------------------------------------------

COPY_SKIP_SPACE1:

    CMP BYTE PTR [SI], ' '
    JNE COPY_GET_SOURCE

    INC SI
    JMP COPY_SKIP_SPACE1


;---------------------------------------------------------
; Get source filename
;---------------------------------------------------------

COPY_GET_SOURCE:

    CMP BYTE PTR [SI], 0
    JE COPY_ERROR

    LEA DI, filename1

COPY_SOURCE_LOOP:

    MOV AL, [SI]

    CMP AL, 0
    JE COPY_ERROR

    CMP AL, ' '
    JE COPY_SOURCE_DONE

    MOV [DI], AL

    INC SI
    INC DI

    JMP COPY_SOURCE_LOOP


COPY_SOURCE_DONE:

    MOV BYTE PTR [DI], 0


;---------------------------------------------------------
; Skip spaces before destination
;---------------------------------------------------------

COPY_SKIP_SPACE2:

    CMP BYTE PTR [SI], ' '
    JNE COPY_GET_DEST

    INC SI
    JMP COPY_SKIP_SPACE2


;---------------------------------------------------------
; Get destination filename
;---------------------------------------------------------

COPY_GET_DEST:

    CMP BYTE PTR [SI], 0
    JE COPY_ERROR

    LEA DI, filename2

COPY_DEST_LOOP:

    MOV AL, [SI]

    CMP AL, 0
    JE COPY_DEST_DONE

    CMP AL, ' '
    JE COPY_DEST_DONE

    MOV [DI], AL

    INC SI
    INC DI

    JMP COPY_DEST_LOOP


COPY_DEST_DONE:

    MOV BYTE PTR [DI], 0


;=========================================================
; Open SOURCE file
;=========================================================

    LEA DX, filename1

    MOV AX, 3D00H       ; Open existing file, read-only
    INT 21H

    JC COPY_ERROR

    MOV sourceHandle, AX


;=========================================================
; Create DESTINATION file
;
; AH = 3CH
; CX = file attributes
; DS:DX = filename
;=========================================================

    LEA DX, filename2

    MOV CX, 0

    MOV AH, 3CH
    INT 21H

    JC COPY_CLOSE_SOURCE

    MOV destHandle, AX


;=========================================================
; Read from source
;=========================================================

COPY_READ:

    MOV BX, sourceHandle

    LEA DX, fileBuffer

    MOV CX, 512

    MOV AH, 3FH
    INT 21H

    JC COPY_CLOSE_BOTH

    ; AX contains number of bytes read
    CMP AX, 0
    JE COPY_FINISH

    ; Save bytes read
    MOV CX, AX


;=========================================================
; Write to destination
;=========================================================

    MOV BX, destHandle

    LEA DX, fileBuffer

    MOV AH, 40H
    INT 21H

    JC COPY_CLOSE_BOTH

    JMP COPY_READ


;=========================================================
; Finish COPY
;=========================================================

COPY_FINISH:

    ; Close source
    MOV BX, sourceHandle
    MOV AH, 3EH
    INT 21H

    ; Close destination
    MOV BX, destHandle
    MOV AH, 3EH
    INT 21H

    ; Display success message
    LEA DX, msgCopied
    MOV AH, 09H
    INT 21H

    JMP SHELL_LOOP


;=========================================================
; Error handling for COPY
;=========================================================

COPY_CLOSE_BOTH:

    MOV BX, sourceHandle
    MOV AH, 3EH
    INT 21H

    MOV BX, destHandle
    MOV AH, 3EH
    INT 21H

    JMP COPY_ERROR


COPY_CLOSE_SOURCE:

    MOV BX, sourceHandle
    MOV AH, 3EH
    INT 21H


COPY_ERROR:

    LEA DX, msgCopyErr
    MOV AH, 09H
    INT 21H

    JMP SHELL_LOOP


;=========================================================
; CompareCommand
;
; SI -> entered command
; DI -> command to compare
;
; Returns:
;   AL = 1 if equal
;   AL = 0 otherwise
;
; Comparison allows:
;
; DIR
; TYPE filename
; COPY source destination
;
; Therefore, comparison stops at a space.
;=========================================================

CompareCommand PROC

COMPARE_LOOP:

    MOV AL, [SI]
    MOV BL, [DI]

    ; If command string ends
    CMP AL, 0
    JE CHECK_COMMAND_END

    ; Space means command name is complete
    CMP AL, ' '
    JE CHECK_COMMAND_END

    ; Compare characters
    CMP AL, BL
    JNE COMMAND_NOT_EQUAL

    INC SI
    INC DI

    JMP COMPARE_LOOP


CHECK_COMMAND_END:

    ; DI must also be at end of command name
    CMP BYTE PTR [DI], 0
    JNE COMMAND_NOT_EQUAL

    MOV AL, 1
    RET


COMMAND_NOT_EQUAL:

    MOV AL, 0
    RET

CompareCommand ENDP


;=========================================================
; ConvertUpper
;
; Converts the entire input to uppercase.
;=========================================================

ConvertUpper PROC

    LEA SI, inputBuffer + 2

UPPER_LOOP:

    MOV AL, [SI]

    CMP AL, 0
    JE UPPER_DONE

    ; Check whether character is between a and z
    CMP AL, 'a'
    JB NOT_LOWER

    CMP AL, 'z'
    JA NOT_LOWER

    ; Convert lowercase to uppercase
    SUB AL, 20H
    MOV [SI], AL

NOT_LOWER:

    INC SI
    JMP UPPER_LOOP


UPPER_DONE:

    RET

ConvertUpper ENDP


;=========================================================
; Command names
;=========================================================

exitCmd DB 'EXIT',0
dirCmd  DB 'DIR',0
typeCmd DB 'TYPE',0
copyCmd DB 'COPY',0


END MAIN