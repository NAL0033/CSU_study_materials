.MODEL SMALL
.STACK 200H

.DATA

menuText DB 13,10
         DB '=========== CALCULATOR V4 ===========',13,10
         DB '1. Calculate',13,10
         DB '2. Read history',13,10
         DB '3. Clear history',13,10
         DB '4. Exit',13,10
         DB 'Choose: $'

exprPrompt DB 13,10
           DB 'Input expression:',13,10
           DB 'Example: 3*(4+5)-6/2',13,10
           DB '> $'

stepMsg DB 13,10
        DB 'Step: $'

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
crlfRaw DB 13,10
equalText DB ' = '

histName DB 'D:\tmp\HISTORY.TXT',0

choiceBuf DB 3
          DB 0
          DB 4 DUP(0)

inputBuf DB 100
         DB 0
         DB 101 DUP(0)

readBuf DB 128 DUP(0)

parseEnd DW 0
parseErr DB 0
result DW 0

stepA DW 0
stepB DW 0
stepR DW 0
stepOp DB 0

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

    MOV BYTE PTR [parseErr],0

    MOV SI,OFFSET inputBuf+2

    XOR AX,AX
    MOV AL,[inputBuf+1]
    MOV BX,OFFSET inputBuf+2
    ADD BX,AX
    MOV [parseEnd],BX

    CALL ParseExpr

    MOV [result],AX

    CMP BYTE PTR [parseErr],0
    JNE calc_error

    CALL SkipSpaces

    CMP SI,[parseEnd]
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

PrintChar PROC
    MOV AH,02H
    INT 21H
    RET
PrintChar ENDP

SkipSpaces PROC
skip_loop:
    CMP SI,[parseEnd]
    JAE skip_done

    MOV AL,[SI]

    CMP AL,' '
    JNE skip_done

    INC SI
    JMP skip_loop

skip_done:
    RET
SkipSpaces ENDP

ParseExpr PROC
    CALL ParseTerm

expr_loop:
    CMP BYTE PTR [parseErr],0
    JNE expr_done

    CALL SkipSpaces

    CMP SI,[parseEnd]
    JAE expr_done

    MOV DL,[SI]

    CMP DL,'+'
    JE expr_add

    CMP DL,'-'
    JE expr_sub

    JMP expr_done

expr_add:
    INC SI

    PUSH AX
    CALL ParseTerm

    CMP BYTE PTR [parseErr],0
    JNE expr_pop_error

    MOV BX,AX
    POP AX

    MOV [stepA],AX
    MOV [stepB],BX

    ADD AX,BX

    MOV [stepR],AX
    MOV BYTE PTR [stepOp],'+'

    CALL PrintStep

    MOV AX,[stepR]
    JMP expr_loop

expr_sub:
    INC SI

    PUSH AX
    CALL ParseTerm

    CMP BYTE PTR [parseErr],0
    JNE expr_pop_error

    MOV BX,AX
    POP AX

    MOV [stepA],AX
    MOV [stepB],BX

    SUB AX,BX

    MOV [stepR],AX
    MOV BYTE PTR [stepOp],'-'

    CALL PrintStep

    MOV AX,[stepR]
    JMP expr_loop

expr_pop_error:
    POP BX

expr_done:
    RET
ParseExpr ENDP

ParseTerm PROC
    CALL ParseFactor

term_loop:
    CMP BYTE PTR [parseErr],0
    JNE term_done

    CALL SkipSpaces

    CMP SI,[parseEnd]
    JAE term_done

    MOV DL,[SI]

    CMP DL,'*'
    JE term_mul

    CMP DL,'/'
    JE term_div

    JMP term_done

term_mul:
    INC SI

    PUSH AX
    CALL ParseFactor

    CMP BYTE PTR [parseErr],0
    JNE term_pop_error

    MOV BX,AX
    POP AX

    MOV [stepA],AX
    MOV [stepB],BX

    IMUL BX

    MOV [stepR],AX
    MOV BYTE PTR [stepOp],'*'

    CALL PrintStep

    MOV AX,[stepR]
    JMP term_loop

term_div:
    INC SI

    PUSH AX
    CALL ParseFactor

    CMP BYTE PTR [parseErr],0
    JNE term_pop_error

    MOV BX,AX
    POP AX

    CMP BX,0
    JE term_div_error

    MOV [stepA],AX
    MOV [stepB],BX

    CWD
    IDIV BX

    MOV [stepR],AX
    MOV BYTE PTR [stepOp],'/'

    CALL PrintStep

    MOV AX,[stepR]
    JMP term_loop

term_pop_error:
    POP BX
    JMP term_done

term_div_error:
    MOV BYTE PTR [parseErr],1

term_done:
    RET
ParseTerm ENDP

ParseFactor PROC
    CALL SkipSpaces

    CMP SI,[parseEnd]
    JAE factor_error

    MOV AL,[SI]

    CMP AL,'+'
    JE factor_positive

    CMP AL,'-'
    JE factor_negative

    CMP AL,'('
    JE factor_left

    CMP AL,'0'
    JB factor_error

    CMP AL,'9'
    JA factor_error

    CALL ReadNumber
    RET

factor_positive:
    INC SI
    CALL ParseFactor
    RET

factor_negative:
    INC SI
    CALL ParseFactor
    NEG AX
    RET

factor_left:
    INC SI

    CALL ParseExpr

    CMP BYTE PTR [parseErr],0
    JNE factor_done

    CALL SkipSpaces

    CMP SI,[parseEnd]
    JAE factor_error

    MOV AL,[SI]

    CMP AL,')'
    JNE factor_error

    INC SI
    RET

factor_error:
    MOV BYTE PTR [parseErr],1

factor_done:
    RET
ParseFactor ENDP

ReadNumber PROC
    XOR AX,AX

read_number_loop:
    CMP SI,[parseEnd]
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

PrintStep PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    LEA DX,stepMsg
    CALL PrintString

    MOV AX,[stepA]
    CALL PrintInt

    MOV DL,' '
    CALL PrintChar

    MOV DL,[stepOp]
    CALL PrintChar

    MOV DL,' '
    CALL PrintChar

    MOV AX,[stepB]
    CALL PrintInt

    MOV DL,' '
    CALL PrintChar

    MOV DL,'='
    CALL PrintChar

    MOV DL,' '
    CALL PrintChar

    MOV AX,[stepR]
    CALL PrintInt

    LEA DX,crlf
    CALL PrintString

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PrintStep ENDP

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

    JC sh_close_error

    MOV BX,[fileHandle]
    LEA DX,equalText
    MOV CX,3
    MOV AH,40H
    INT 21H

    JC sh_close_error

    MOV BX,[fileHandle]
    LEA DX,resultStr
    MOV CX,[resultLen]
    MOV AH,40H
    INT 21H

    JC sh_close_error

    MOV BX,[fileHandle]
    LEA DX,crlfRaw
    MOV CX,2
    MOV AH,40H
    INT 21H

    JC sh_close_error

    MOV BX,[fileHandle]
    MOV AH,3EH
    INT 21H

    LEA DX,saveMsg
    CALL PrintString
    LEA DX,crlf
    CALL PrintString

    JMP sh_done

sh_close_error:
    MOV BX,[fileHandle]
    MOV AH,3EH
    INT 21H

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
    CALL PrintChar

    JMP pi_done

pi_not_zero:
    CMP AX,0
    JGE pi_positive

    MOV DL,'-'
    CALL PrintChar

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
    CALL PrintChar

    LOOP pi_print_loop

pi_done:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PrintInt ENDP

END MAIN