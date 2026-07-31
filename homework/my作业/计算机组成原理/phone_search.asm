.MODEL SMALL
.STACK 100H

.DATA
    MAX_ENTRIES EQU 50
    NAME_LEN    EQU 20
    PHONE_LEN   EQU 8
    ENTRY_LEN   EQU 28
    
    tel_tab     DB MAX_ENTRIES * ENTRY_LEN DUP(0)
    entry_count DW 0
    
    temp_name   DB NAME_LEN DUP(0)
    temp_phone  DB PHONE_LEN DUP(0)
    temp_entry  DB ENTRY_LEN DUP(0)
    
    found_flag  DB 0
    
    msg_input_name   DB 'Input name: $'
    msg_input_phone  DB 'Input a telephone number: $'
    msg_continue     DB 'Do you want to add more? (Y/N): $'
    msg_search       DB 'Do you want a telephone number? (Y/N): $'
    msg_which_name   DB 'Name? $'
    msg_not_found    DB 'Name not found!$'
    msg_header1      DB 'Name                Tel.$'
    msg_newline      DB 13, 10, '$'
    msg_spaces       DB '                    $'

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    MOV ES, AX
    
INPUT_LOOP:
    LEA DX, msg_input_name
    CALL PRINT_STRING
    
    CALL INPUT_NAME
    
    CALL STORNAME
    
    LEA DX, msg_input_phone
    CALL PRINT_STRING
    
    CALL INPHONE
    
    LEA DX, msg_continue
    CALL PRINT_STRING
    CALL GET_CHAR
    CALL PRINT_NEWLINE
    
    CMP AL, 'N'
    JE  SORT_AND_SEARCH
    CMP AL, 'n'
    JE  SORT_AND_SEARCH
    JMP INPUT_LOOP
    
SORT_AND_SEARCH:
    CALL NAME_SORT
    
SEARCH_LOOP:
    LEA DX, msg_search
    CALL PRINT_STRING
    CALL GET_CHAR
    CALL PRINT_NEWLINE
    
    CMP AL, 'N'
    JE  EXIT_PROG
    CMP AL, 'n'
    JE  EXIT_PROG
    
    LEA DX, msg_which_name
    CALL PRINT_STRING
    
    CALL INPUT_NAME
    
    CALL NAME_SEARCH
    
    CMP found_flag, 1
    JNE NOT_FOUND
    
    CALL PRINTLINE
    JMP SEARCH_LOOP
    
NOT_FOUND:
    LEA DX, msg_not_found
    CALL PRINT_STRING
    CALL PRINT_NEWLINE
    JMP SEARCH_LOOP
    
EXIT_PROG:
    MOV AX, 4C00H
    INT 21H
MAIN ENDP

PRINT_STRING PROC
    PUSH AX
    MOV AH, 09H
    INT 21H
    POP AX
    RET
PRINT_STRING ENDP

PRINT_NEWLINE PROC
    PUSH AX
    PUSH DX
    LEA DX, msg_newline
    MOV AH, 09H
    INT 21H
    POP DX
    POP AX
    RET
PRINT_NEWLINE ENDP

GET_CHAR PROC
    MOV AH, 01H
    INT 21H
    RET
GET_CHAR ENDP

INPUT_NAME PROC
    PUSH BX
    PUSH CX
    PUSH DX
    
    LEA BX, temp_name
    MOV CX, NAME_LEN
    
    PUSH CX
    PUSH BX
CLEAR_NAME:
    MOV BYTE PTR [BX], 0
    INC BX
    LOOP CLEAR_NAME
    POP BX
    POP CX
    
READ_NAME_LOOP:
    MOV AH, 01H
    INT 21H
    
    CMP AL, 13
    JE  END_READ_NAME
    
    CMP CX, 0
    JE  READ_NAME_LOOP
    
    MOV [BX], AL
    INC BX
    DEC CX
    JMP READ_NAME_LOOP
    
END_READ_NAME:
    CALL PRINT_NEWLINE
    POP DX
    POP CX
    POP BX
    RET
INPUT_NAME ENDP

STORNAME PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    MOV AX, entry_count
    CMP AX, MAX_ENTRIES
    JAE STORNAME_END
    
    MOV BX, ENTRY_LEN
    MUL BX
    LEA DI, tel_tab
    ADD DI, AX
    
    LEA SI, temp_name
    MOV CX, NAME_LEN
COPY_NAME:
    MOV AL, [SI]
    MOV [DI], AL
    INC SI
    INC DI
    LOOP COPY_NAME
    
STORNAME_END:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
STORNAME ENDP

INPHONE PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    LEA BX, temp_phone
    MOV CX, PHONE_LEN
    
    PUSH CX
    PUSH BX
CLEAR_PHONE:
    MOV BYTE PTR [BX], 0
    INC BX
    LOOP CLEAR_PHONE
    POP BX
    POP CX
    
READ_PHONE_LOOP:
    MOV AH, 01H
    INT 21H
    
    CMP AL, 13
    JE  END_READ_PHONE
    
    CMP CX, 0
    JE  READ_PHONE_LOOP
    
    MOV [BX], AL
    INC BX
    DEC CX
    JMP READ_PHONE_LOOP
    
END_READ_PHONE:
    CALL PRINT_NEWLINE
    
    MOV AX, entry_count
    CMP AX, MAX_ENTRIES
    JAE INPHONE_END
    
    MOV BX, ENTRY_LEN
    MUL BX
    LEA DI, tel_tab
    ADD DI, AX
    ADD DI, NAME_LEN
    
    LEA SI, temp_phone
    MOV CX, PHONE_LEN
COPY_PHONE:
    MOV AL, [SI]
    MOV [DI], AL
    INC SI
    INC DI
    LOOP COPY_PHONE
    
    INC entry_count
    
INPHONE_END:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
INPHONE ENDP

NAME_SORT PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    MOV CX, entry_count
    CMP CX, 1
    JBE SORT_DONE
    DEC CX
    
OUTER_LOOP:
    PUSH CX
    LEA SI, tel_tab
    
INNER_LOOP:
    MOV DI, SI
    ADD DI, ENTRY_LEN
    
    PUSH CX
    PUSH SI
    PUSH DI
    
    MOV CX, NAME_LEN
COMPARE_NAMES:
    MOV AL, [SI]
    MOV BL, [DI]
    CMP AL, BL
    JA  NEED_SWAP
    JB  NO_SWAP
    INC SI
    INC DI
    LOOP COMPARE_NAMES
    JMP NO_SWAP
    
NEED_SWAP:
    POP DI
    POP SI
    PUSH SI
    PUSH DI
    
    MOV CX, ENTRY_LEN
SWAP_LOOP:
    MOV AL, [SI]
    MOV BL, [DI]
    MOV [SI], BL
    MOV [DI], AL
    INC SI
    INC DI
    LOOP SWAP_LOOP
    
NO_SWAP:
    POP DI
    POP SI
    POP CX
    
    ADD SI, ENTRY_LEN
    LOOP INNER_LOOP
    
    POP CX
    LOOP OUTER_LOOP
    
SORT_DONE:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
NAME_SORT ENDP

NAME_SEARCH PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    MOV found_flag, 0
    LEA SI, tel_tab
    MOV DX, entry_count
    
SEARCH_ENTRY:
    CMP DX, 0
    JE  SEARCH_NOT_FOUND
    
    PUSH SI
    LEA DI, temp_name
    MOV CX, NAME_LEN
    
COMPARE_SEARCH:
    MOV AL, [SI]
    MOV BL, [DI]
    
    CMP AL, 0
    JNE CHECK_BL
    CMP BL, 0
    JE  FOUND_MATCH
    JMP NOT_MATCH
    
CHECK_BL:
    CMP BL, 0
    JE  NOT_MATCH
    
    CMP AL, BL
    JNE NOT_MATCH
    INC SI
    INC DI
    LOOP COMPARE_SEARCH
    
FOUND_MATCH:
    POP SI
    MOV found_flag, 1
    
    LEA DI, temp_entry
    MOV CX, ENTRY_LEN
COPY_FOUND:
    MOV AL, [SI]
    MOV [DI], AL
    INC SI
    INC DI
    LOOP COPY_FOUND
    JMP SEARCH_DONE
    
NOT_MATCH:
    POP SI
    ADD SI, ENTRY_LEN
    DEC DX
    JMP SEARCH_ENTRY
    
SEARCH_NOT_FOUND:
    MOV found_flag, 0
    
SEARCH_DONE:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
NAME_SEARCH ENDP

PRINTLINE PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    LEA DX, msg_header1
    CALL PRINT_STRING
    CALL PRINT_NEWLINE
    
    LEA SI, temp_entry
    MOV CX, NAME_LEN
PRINT_NAME_CHAR:
    MOV DL, [SI]
    CMP DL, 0
    JE  PAD_NAME
    MOV AH, 02H
    INT 21H
    INC SI
    DEC CX
    JMP PRINT_NAME_CHAR
    
PAD_NAME:
    CMP CX, 0
    JE  PRINT_PHONE
    MOV DL, ' '
    MOV AH, 02H
    INT 21H
    DEC CX
    JMP PAD_NAME
    
PRINT_PHONE:
    LEA SI, temp_entry
    ADD SI, NAME_LEN
    MOV CX, PHONE_LEN
PRINT_PHONE_CHAR:
    MOV DL, [SI]
    CMP DL, 0
    JE  END_PRINT
    MOV AH, 02H
    INT 21H
    INC SI
    LOOP PRINT_PHONE_CHAR
    
END_PRINT:
    CALL PRINT_NEWLINE
    
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINTLINE ENDP

END MAIN
