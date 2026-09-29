.MODEL SMALL
.STACK 100h

.DATA
    ; Prompts and Messages
    prompt_str      DB 0DH, 0AH, "SHELL> $", 0
    unknown_cmd     DB 0DH, 0AH, "Unknown command. Available: DIR, TYPE, COPY, EXIT$", 0
    newline         DB 0DH, 0AH, "$"
    err_file        DB 0DH, 0AH, "Error: File operation failed!$", 0
    err_args        DB 0DH, 0AH, "Error: Missing arguments!$", 0
    copy_success    DB 0DH, 0AH, "File copied successfully.$", 0
    
    ; Mock DIR Listing
    mock_dir        DB 0DH, 0AH, " Directory listing:"
                    DB 0DH, 0AH, "  README  TXT"
                    DB 0DH, 0AH, "  TEST    DOC"
                    DB 0DH, 0AH, "  DATA    BIN"
                    DB 0DH, 0AH, "        3 File(s)$"

    ; Buffered Input Structure for INT 21h, AH=0Ah
    input_buffer    DB 80          ; Max bytes to read
    input_len       DB 0           ; Actual bytes read
    input_text      DB 80 DUP(0)   ; Entered characters

    ; File handling variables
    file_src_handle DW ?
    file_dst_handle DW ?
    buffer          DB 512 DUP(0)  ; Buffer for reading file contents
    
    ; Command Strings for Comparison
    cmd_dir         DB "DIR", 0
    cmd_type        DB "TYPE", 0
    cmd_copy        DB "COPY", 0
    cmd_exit        DB "EXIT", 0

    ; Parsed Arguments (Null-terminated ASCIIZ strings)
    arg1            DB 64 DUP(0)
    arg2            DB 64 DUP(0)
    arg3            DB 64 DUP(0)

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    MOV ES, AX          ; Set ES = DS for string instructions

SHELL_LOOP:
    ; 1. Print Prompt
    LEA DX, prompt_str
    MOV AH, 09h
    INT 21h

    ; 2. Read User Input
    LEA DX, input_buffer
    MOV AH, 0Ah
    INT 21h

    ; Append null terminator to input text
    XOR BH, BH
    MOV BL, input_len
    CMP BL, 0
    JE SHELL_LOOP      ; If empty input, prompt again
    MOV input_text[BX], 0

    ; 3. Parse Input into Arguments
    CALL PARSE_INPUT

    ; Check if command is empty
    CMP arg1[0], 0
    JE SHELL_LOOP

    ; 4. Match Commands
    ; Check DIR
    LEA SI, arg1
    LEA DI, cmd_dir
    CALL COMPARE_STR
    JZ EXEC_DIR

    ; Check TYPE
    LEA SI, arg1
    LEA DI, cmd_type
    CALL COMPARE_STR
    JZ EXEC_TYPE

    ; Check COPY
    LEA SI, arg1
    LEA DI, cmd_copy
    CALL COMPARE_STR
    JZ EXEC_COPY

    ; Check EXIT
    LEA SI, arg1
    LEA DI, cmd_exit
    CALL COMPARE_STR
    JZ EXEC_EXIT

    ; Unknown Command
    LEA DX, unknown_cmd
    MOV AH, 09h
    INT 21h
    JMP SHELL_LOOP

EXEC_DIR:
    LEA DX, mock_dir
    MOV AH, 09h
    INT 21h
    JMP SHELL_LOOP

EXEC_TYPE:
    CMP arg2[0], 0
    JE TYPE_MISSING_ARGS
    
    ; Open Source File
    LEA DX, arg2
    MOV AH, 3Dh         ; DOS Open File
    MOV AL, 0           ; Read-only mode
    INT 21h
    JC FILE_ERROR
    MOV file_src_handle, AX

    LEA DX, newline
    MOV AH, 09h
    INT 21h

READ_TYPE_LOOP:
    ; Read from File
    MOV AH, 3Fh
    MOV BX, file_src_handle
    CX, 512
    LEA DX, buffer
    INT 21h
    JC CLOSE_TYPE_ERR
    CMP AX, 0          ; Check EOF (AX = bytes read)
    JE CLOSE_TYPE_SUCCESS

    ; Display read content to terminal
    MOV CX, AX         ; Number of bytes read
    MOV SI, 0
PRINT_CHAR_LOOP:
    MOV DL, buffer[SI]
    MOV AH, 02h
    INT 21h
    INC SI
    LOOP PRINT_CHAR_LOOP
    JMP READ_TYPE_LOOP

CLOSE_TYPE_SUCCESS:
    MOV AH, 3Eh        ; Close file
    MOV BX, file_src_handle
    INT 21h
    JMP SHELL_LOOP

CLOSE_TYPE_ERR:
    MOV AH, 3Eh
    MOV BX, file_src_handle
    INT 21h
    JMP FILE_ERROR

TYPE_MISSING_ARGS:
    LEA DX, err_args
    MOV AH, 09h
    INT 21h
    JMP SHELL_LOOP

EXEC_COPY:
    CMP arg2[0], 0
    JE COPY_MISSING_ARGS
    CMP arg3[0], 0
    JE COPY_MISSING_ARGS

    ; Open Source File (Read)
    LEA DX, arg2
    MOV AH, 3Dh
    MOV AL, 0
    INT 21h
    JC FILE_ERROR
    MOV file_src_handle, AX

    ; Create/Overwrite Destination File (Write)
    LEA DX, arg3
    MOV AH, 3Ch
    MOV CX, 0          ; Normal file attribute
    INT 21h
    JC CLOSE_SRC_AND_ERR
    MOV file_dst_handle, AX

COPY_LOOP:
    ; Read from Source
    MOV AH, 3Fh
    MOV BX, file_src_handle
    MOV CX, 512
    LEA DX, buffer
    INT 21h
    JC CLOSE_BOTH_ERR
    CMP AX, 0          ; EOF
    JE COPY_SUCCESS_END

    ; Write to Destination
    MOV CX, AX         ; Bytes read = Bytes to write
    MOV AH, 40h
    MOV BX, file_dst_handle
    LEA DX, buffer
    INT 21h
    JC CLOSE_BOTH_ERR
    JMP COPY_LOOP

COPY_SUCCESS_END:
    ; Close Source
    MOV AH, 3Eh
    MOV BX, file_src_handle
    INT 21h

    ; Close Destination
    MOV AH, 3Eh
    MOV BX, file_dst_handle
    INT 21h

    LEA DX, copy_success
    MOV AH, 09h
    INT 21h
    JMP SHELL_LOOP

CLOSE_SRC_AND_ERR:
    MOV AH, 3Eh
    MOV BX, file_src_handle
    INT 21h
    JMP FILE_ERROR

CLOSE_BOTH_ERR:
    MOV AH, 3Eh
    MOV BX, file_src_handle
    INT 21h
    MOV AH, 3Eh
    MOV BX, file_dst_handle
    INT 21h
    JMP FILE_ERROR

COPY_MISSING_ARGS:
    LEA DX, err_args
    MOV AH, 09h
    INT 21h
    JMP SHELL_LOOP

FILE_ERROR:
    LEA DX, err_file
    MOV AH, 09h
    INT 21h
    JMP SHELL_LOOP

EXEC_EXIT:
    MOV AH, 4Ch        ; Terminate program
    INT 21h

MAIN ENDP

;---------------------------------------------------------------------
; Helper: Parse input_text into arg1, arg2, arg3 separated by spaces
;---------------------------------------------------------------------
PARSE_INPUT PROC
    ; Clear previous arguments
    CALL CLEAR_ARGS

    LEA SI, input_text
    
    ; Parse arg1
    CALL SKIP_SPACES
    LEA DI, arg1
    CALL EXTRACT_TOKEN

    ; Parse arg2
    CALL SKIP_SPACES
    LEA DI, arg2
    CALL EXTRACT_TOKEN

    ; Parse arg3
    CALL SKIP_SPACES
    LEA DI, arg3
    CALL EXTRACT_TOKEN

    RET
PARSE_INPUT ENDP

SKIP_SPACES PROC
SKIP_LOOP:
    MOV AL, [SI]
    CMP AL, ' '
    JNE SKIP_DONE
    INC SI
    JMP SKIP_LOOP
SKIP_DONE:
    RET
SKIP_SPACES ENDP

EXTRACT_TOKEN PROC
TOKEN_LOOP:
    MOV AL, [SI]
    CMP AL, 0
    JE TOKEN_DONE
    CMP AL, ' '
    JE TOKEN_DONE
    CMP AL, 0DH        ; Carriage Return
    JE TOKEN_DONE
    
    ; Convert character to uppercase for case-insensitivity
    CMP AL, 'a'
    JB NOT_LOWER
    CMP AL, 'z'
    JA NOT_LOWER
    SUB AL, 32
NOT_LOWER:
    MOV [DI], AL
    INC SI
    INC DI
    JMP TOKEN_LOOP
TOKEN_DONE:
    MOV BYTE PTR [DI], 0 ; Null terminate string
    RET
EXTRACT_TOKEN ENDP

CLEAR_ARGS PROC
    MOV CX, 64
    MOV AL, 0
    LEA DI, arg1
    REP STOSB
    MOV CX, 64
    LEA DI, arg2
    REP STOSB
    MOV CX, 64
    LEA DI, arg3
    REP STOSB
    RET
CLEAR_ARGS ENDP

;---------------------------------------------------------------------
; Helper: Compare null-terminated strings at SI and DI
; Sets Zero Flag (ZF=1) if equal
;---------------------------------------------------------------------
COMPARE_STR PROC
CMP_LOOP:
    MOV AL, [SI]
    MOV BL, [DI]
    CMP AL, BL
    JNE CMP_MISMATCH
    CMP AL, 0
    JE CMP_MATCH
    INC SI
    INC DI
    JMP CMP_LOOP
CMP_MATCH:
    XOR AX, AX         ; Set ZF = 1
    RET
CMP_MISMATCH:
    OR AX, 1           ; Clear ZF = 0
    RET
COMPARE_STR ENDP

END MAIN