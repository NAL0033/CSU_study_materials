.MODEL SMALL
.STACK 100H
.DATA

menuText DB 13,10
         DB '=========== CALCULATOR V2 ===========',13,10
         DB '1. Calculate',13,10
         DB '2. Read history',13,10
         DB '3. Clear history',13,10
         DB '4. Exit',13,10
         DB 'Choose: $'

exprPrompt DB 13,10
           DB 'Input expression:',13,10
           DB 'Example: 12+3*4-6/2',13,10
           DB '> $'

resultMsg DB 13,10
          DB 'Result = $'

errorMsg DB 13,10
         DB 'Input error or divide by zero.$'

byeMsg DB 13,10
       DB 'Bye.$'

saveMsg DB 13,10
        DB 'Saved to HISTORY.TXT.$'

historyTitle DB 13,10
             DB '=========== HISTORY ===========',13,10,'$'

noHistoryMsg DB 13,10
             DB 'No history file.$'

clearMsg DB 13,10
         DB 'History cleared.$'

fileErrMsg DB 13,10
           DB 'File operation error.$'

crlf DB 13,10,'$'

equalText DB ' = '
crlfRaw DB 13,10

histName DB 'HISTORY.TXT',0

choiceBuf DB 3
          DB 0
          DB 4 DUP(0)

inputBuf DB 100
         DB 0
         DB 101 DUP(0)

readBuf DB 128 DUP(0)

nums DW 32 DUP(0)
ops DB 32 DUP(0)

numCount DW 0
opCount DW 0
iVar DW 0
result DW 0

parseErr DB 0
expectNum DB 0

fileHandle DW 0
resultStr DB 12 DUP(0)
resultLen DW 0

.CODE

MAIN PROC
    MOV AX,@DATA
    MOV DS,AX

menu_loop:
    LEA DX,menuText
    CALL PrintString

    LEA DX,choiceBuf
    CALL ReadLine

    MOV AL,[choiceBuf+2]

    CMP AL,'1'
    JE do_calculate

    CMP AL,'2'
    JE do_read_history

    CMP AL,'3'
    JE do_clear_history

    CMP AL,'4'
    JE do_exit

    LEA DX,errorMsg
    CALL PrintString
    LEA DX,crlf
    CALL PrintString
    JMP menu_loop

do_calculate:
    LEA DX,exprPrompt
    CALL PrintString

    LEA DX,inputBuf
    CALL ReadLine

    CALL ParseExpression

    CMP BYTE PTR [parseErr],0
    JNE calc_error

    CALL EvalMulDiv

    CMP BYTE PTR [parseErr],0
    JNE calc_error

    CALL EvalAddSub

    CMP BYTE PTR [parseErr],0
    JNE calc_error

    LEA DX,resultMsg
    CALL PrintString

    MOV AX,[result]
    CALL PrintInt

    LEA DX,crlf
    CALL PrintString

    CALL SaveHistory

    JMP menu_loop

calc_error:
    LEA DX,errorMsg
    CALL PrintString
    LEA DX,crlf
    CALL PrintString
    JMP menu_loop

do_read_history:
    CALL ReadHistory
    JMP menu_loop

do_clear_history:
    CALL ClearHistory
    JMP menu_loop

do_exit:
    LEA DX,byeMsg
    CALL PrintString

    MOV AX,4C00H
    INT 21H

MAIN ENDP

ReadLine PROC
    PUSH AX
    PUSH BX
    PUSH SI

    MOV AH,0AH
    INT 21H

    MOV BX,DX
    XOR AX,AX
    MOV AL,[BX+1]
    MOV SI,AX
    MOV BYTE PTR [BX+SI+2],0

    POP SI
    POP BX
    POP AX
    RET
ReadLine ENDP

PrintString PROC
    MOV AH,09H
    INT 21H
    RET
PrintString ENDP

ParseExpression PROC
    MOV BYTE PTR [parseErr],0
    MOV BYTE PTR [expectNum],1
    MOV WORD PTR [numCount],0
    MOV WORD PTR [opCount],0

    MOV SI,OFFSET inputBuf+2

    XOR AX,AX
    MOV AL,[inputBuf+1]
    MOV BX,OFFSET inputBuf+2
    ADD BX,AX

parse_loop:
    CMP SI,BX
    JAE parse_end

    MOV AL,[SI]

    CMP AL,' '
    JE parse_skip

    CMP BYTE PTR [expectNum],1
    JE parse_need_number

    CMP AL,'+'
    JE parse_store_op

    CMP AL,'-'
    JE parse_store_op

    CMP AL,'*'
    JE parse_store_op

    CMP AL,'/'
    JE parse_store_op

    JMP parse_error

parse_need_number:
    CMP AL,'-'
    JE parse_negative_number

    CMP AL,'+'
    JE parse_positive_number

    CMP AL,'0'
    JB parse_error

    CMP AL,'9'
    JA parse_error

    CALL ReadNumber
    JMP parse_store_number

parse_negative_number:
    INC SI

    CMP SI,BX
    JAE parse_error

    MOV AL,[SI]

    CMP AL,'0'
    JB parse_error

    CMP AL,'9'
    JA parse_error

    CALL ReadNumber
    NEG AX
    JMP parse_store_number

parse_positive_number:
    INC SI

    CMP SI,BX
    JAE parse_error

    MOV AL,[SI]

    CMP AL,'0'
    JB parse_error

    CMP AL,'9'
    JA parse_error

    CALL ReadNumber
    JMP parse_store_number

parse_store_number:
    MOV DI,[numCount]
    SHL DI,1
    MOV [nums+DI],AX

    INC WORD PTR [numCount]
    MOV BYTE PTR [expectNum],0

    JMP parse_loop

parse_store_op:
    MOV DI,[opCount]
    MOV [ops+DI],AL

    INC WORD PTR [opCount]
    INC SI

    MOV BYTE PTR [expectNum],1

    JMP parse_loop

parse_skip:
    INC SI
    JMP parse_loop

parse_end:
    CMP BYTE PTR [expectNum],1
    JE parse_error

    RET

parse_error:
    MOV BYTE PTR [parseErr],1
    RET

ParseExpression ENDP

ReadNumber PROC
    XOR AX,AX

read_number_loop:
    CMP SI,BX
    JAE read_number_done

    MOV DL,[SI]

    CMP DL,'0'
    JB read_number_done

    CMP DL,'9'
    JA read_number_done

    SUB DL,'0'

    PUSH DX

    MOV CX,10
    MUL CX

    POP DX

    XOR DH,DH
    ADD AX,DX

    INC SI

    JMP read_number_loop

read_number_done:
    RET
ReadNumber ENDP

EvalMulDiv PROC
    MOV BYTE PTR [parseErr],0
    MOV WORD PTR [iVar],0

emd_loop:
    MOV AX,[iVar]
    CMP AX,[opCount]
    JAE emd_done

    MOV SI,AX
    MOV AL,[ops+SI]

    CMP AL,'*'
    JE emd_mul

    CMP AL,'/'
    JE emd_div

    INC WORD PTR [iVar]
    JMP emd_loop

emd_mul:
    MOV AX,[iVar]
    SHL AX,1
    MOV SI,AX

    MOV AX,[nums+SI]
    IMUL WORD PTR [nums+SI+2]

    MOV [nums+SI],AX

    CALL RemoveItem
    JMP emd_loop

emd_div:
    MOV AX,[iVar]
    SHL AX,1
    MOV SI,AX

    CMP WORD PTR [nums+SI+2],0
    JE emd_error

    MOV AX,[nums+SI]
    CWD
    IDIV WORD PTR [nums+SI+2]

    MOV [nums+SI],AX

    CALL RemoveItem
    JMP emd_loop

emd_error:
    MOV BYTE PTR [parseErr],1
    RET

emd_done:
    RET

EvalMulDiv ENDP

RemoveItem PROC
    MOV DX,[iVar]
    INC DX

remove_num_loop:
    MOV AX,[numCount]
    DEC AX

    CMP DX,AX
    JAE remove_num_done

    MOV SI,DX
    SHL SI,1

    MOV AX,[nums+SI+2]
    MOV [nums+SI],AX

    INC DX
    JMP remove_num_loop

remove_num_done:
    MOV DX,[iVar]

remove_op_loop:
    MOV AX,[opCount]
    DEC AX

    CMP DX,AX
    JAE remove_op_done

    MOV SI,DX

    MOV AL,[ops+SI+1]
    MOV [ops+SI],AL

    INC DX
    JMP remove_op_loop

remove_op_done:
    DEC WORD PTR [numCount]
    DEC WORD PTR [opCount]

    RET
RemoveItem ENDP

EvalAddSub PROC
    MOV BYTE PTR [parseErr],0

    CMP WORD PTR [numCount],0
    JE eas_error

    MOV AX,[nums]
    MOV [result],AX

    XOR BX,BX

eas_loop:
    CMP BX,[opCount]
    JAE eas_done

    MOV SI,BX

    MOV DI,BX
    INC DI
    SHL DI,1

    MOV AX,[result]

    CMP BYTE PTR [ops+SI],'+'
    JE eas_add

    CMP BYTE PTR [ops+SI],'-'
    JE eas_sub

    JMP eas_error

eas_add:
    ADD AX,[nums+DI]
    MOV [result],AX

    INC BX
    JMP eas_loop

eas_sub:
    SUB AX,[nums+DI]
    MOV [result],AX

    INC BX
    JMP eas_loop

eas_error:
    MOV BYTE PTR [parseErr],1
    RET

eas_done:
    RET

EvalAddSub ENDP

SaveHistory PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    CALL MakeResultString

    MOV AX,3D02H
    LEA DX,histName
    INT 21H

    JC sh_create

    MOV [fileHandle],AX
    JMP sh_seek_end

sh_create:
    MOV AH,3CH
    MOV CX,0
    LEA DX,histName
    INT 21H

    JC sh_file_error

    MOV [fileHandle],AX

sh_seek_end:
    MOV BX,[fileHandle]
    MOV AX,4202H
    XOR CX,CX
    XOR DX,DX
    INT 21H

    MOV BX,[fileHandle]
    LEA DX,inputBuf+2
    XOR CX,CX
    MOV CL,[inputBuf+1]
    MOV AH,40H
    INT 21H

    MOV BX,[fileHandle]
    LEA DX,equalText
    MOV CX,3
    MOV AH,40H
    INT 21H

    MOV BX,[fileHandle]
    LEA DX,resultStr
    MOV CX,[resultLen]
    MOV AH,40H
    INT 21H

    MOV BX,[fileHandle]
    LEA DX,crlfRaw
    MOV CX,2
    MOV AH,40H
    INT 21H

    MOV BX,[fileHandle]
    MOV AH,3EH
    INT 21H

    LEA DX,saveMsg
    CALL PrintString
    LEA DX,crlf
    CALL PrintString

    JMP sh_done

sh_file_error:
    LEA DX,fileErrMsg
    CALL PrintString
    LEA DX,crlf
    CALL PrintString

sh_done:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SaveHistory ENDP

ReadHistory PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    LEA DX,historyTitle
    CALL PrintString

    MOV AX,3D00H
    LEA DX,histName
    INT 21H

    JC rh_no_file

    MOV [fileHandle],AX

rh_read_loop:
    MOV BX,[fileHandle]
    LEA DX,readBuf
    MOV CX,128
    MOV AH,3FH
    INT 21H

    JC rh_close

    CMP AX,0
    JE rh_close

    MOV CX,AX
    MOV BX,1
    LEA DX,readBuf
    MOV AH,40H
    INT 21H

    JMP rh_read_loop

rh_close:
    MOV BX,[fileHandle]
    MOV AH,3EH
    INT 21H

    LEA DX,crlf
    CALL PrintString

    JMP rh_done

rh_no_file:
    LEA DX,noHistoryMsg
    CALL PrintString
    LEA DX,crlf
    CALL PrintString

rh_done:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ReadHistory ENDP

ClearHistory PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV AH,3CH
    MOV CX,0
    LEA DX,histName
    INT 21H

    JC ch_error

    MOV BX,AX
    MOV AH,3EH
    INT 21H

    LEA DX,clearMsg
    CALL PrintString
    LEA DX,crlf
    CALL PrintString

    JMP ch_done

ch_error:
    LEA DX,fileErrMsg
    CALL PrintString
    LEA DX,crlf
    CALL PrintString

ch_done:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ClearHistory ENDP

MakeResultString PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI

    LEA DI,resultStr
    MOV WORD PTR [resultLen],0

    MOV AX,[result]

    CMP AX,0
    JNE mrs_not_zero

    MOV BYTE PTR [DI],'0'
    MOV WORD PTR [resultLen],1

    JMP mrs_done

mrs_not_zero:
    CMP AX,0
    JGE mrs_positive

    MOV BYTE PTR [DI],'-'
    INC DI
    INC WORD PTR [resultLen]

    NEG AX

mrs_positive:
    XOR CX,CX
    MOV BX,10

mrs_div_loop:
    XOR DX,DX
    DIV BX

    PUSH DX
    INC CX

    CMP AX,0
    JNE mrs_div_loop

mrs_pop_loop:
    POP DX

    ADD DL,'0'
    MOV [DI],DL

    INC DI
    INC WORD PTR [resultLen]

    LOOP mrs_pop_loop

mrs_done:
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
MakeResultString ENDP

PrintInt PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    CMP AX,0
    JNE pi_not_zero

    MOV DL,'0'
    MOV AH,02H
    INT 21H

    JMP pi_done

pi_not_zero:
    CMP AX,0
    JGE pi_positive

    MOV DL,'-'
    MOV AH,02H
    INT 21H

    NEG AX

pi_positive:
    XOR CX,CX
    MOV BX,10

pi_div_loop:
    XOR DX,DX
    DIV BX

    PUSH DX
    INC CX

    CMP AX,0
    JNE pi_div_loop

pi_print_loop:
    POP DX

    ADD DL,'0'
    MOV AH,02H
    INT 21H

    LOOP pi_print_loop

pi_done:
    POP DX
    POP CX
    POP BX
    POP AX
    RET

PrintInt ENDP

END MAIN