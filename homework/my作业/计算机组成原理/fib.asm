.MODEL SMALL
.STACK 400H

.DATA
    num_input    DW 0
    result       DW 0
    
    msg_input    DB 'Please input n (1-99): $'
    msg_output   DB 'FIB(n) = $'
    msg_error    DB 'Error: n must be between 1 and 99!$'
    msg_newline  DB 13, 10, '$'

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    
    LEA DX, msg_input
    MOV AH, 09H
    INT 21H
    
    CALL INPUT_NUM
    
    CMP num_input, 0
    JE  ERROR_EXIT
    CMP num_input, 100
    JAE ERROR_EXIT
    
    MOV AX, num_input
    PUSH AX
    CALL FIBP
    ADD SP, 2
    MOV result, AX
    
    LEA DX, msg_output
    MOV AH, 09H
    INT 21H
    
    MOV AX, result
    CALL OUTPUT_NUM
    
    LEA DX, msg_newline
    MOV AH, 09H
    INT 21H
    
    JMP PROGRAM_END
    
ERROR_EXIT:
    LEA DX, msg_error
    MOV AH, 09H
    INT 21H
    LEA DX, msg_newline
    MOV AH, 09H
    INT 21H
    
PROGRAM_END:
    MOV AX, 4C00H
    INT 21H
MAIN ENDP

INPUT_NUM PROC
    PUSH BX
    PUSH CX
    PUSH DX
    
    XOR BX, BX
    
READ_LOOP:
    MOV AH, 01H
    INT 21H
    
    CMP AL, 13
    JE  READ_DONE
    
    CMP AL, '0'
    JB  READ_LOOP
    CMP AL, '9'
    JA  READ_LOOP
    
    SUB AL, '0'
    XOR AH, AH
    
    PUSH AX
    MOV AX, BX
    MOV CX, 10
    MUL CX
    MOV BX, AX
    POP AX
    
    ADD BX, AX
    JMP READ_LOOP
    
READ_DONE:
    MOV num_input, BX
    
    LEA DX, msg_newline
    MOV AH, 09H
    INT 21H
    
    POP DX
    POP CX
    POP BX
    RET
INPUT_NUM ENDP

FIBP PROC
    PUSH BP
    MOV BP, SP
    SUB SP, 4
    
    MOV AX, [BP+4]
    
    CMP AX, 1
    JE  FIB_BASE
    CMP AX, 2
    JE  FIB_BASE
    JMP FIB_RECURSE
    
FIB_BASE:
    MOV AX, 1
    JMP FIB_DONE
    
FIB_RECURSE:
    MOV AX, [BP+4]
    DEC AX
    PUSH AX
    CALL FIBP
    ADD SP, 2
    MOV [BP-2], AX
    
    MOV AX, [BP+4]
    SUB AX, 2
    PUSH AX
    CALL FIBP
    ADD SP, 2
    MOV [BP-4], AX
    
    MOV AX, [BP-2]
    ADD AX, [BP-4]
    
FIB_DONE:
    MOV SP, BP
    POP BP
    RET
FIBP ENDP

OUTPUT_NUM PROC
    PUSH BX
    PUSH CX
    PUSH DX
    
    XOR CX, CX
    MOV BX, 10
    
DIVIDE_LOOP:
    XOR DX, DX
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE DIVIDE_LOOP
    
PRINT_LOOP:
    POP DX
    ADD DL, '0'
    MOV AH, 02H
    INT 21H
    LOOP PRINT_LOOP
    
    POP DX
    POP CX
    POP BX
    RET
OUTPUT_NUM ENDP

END MAIN
