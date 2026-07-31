.MODEL SMALL
.STACK 400H

.DATA

menuText DB 13,10
         DB '=========== CALCULATOR V5 ===========',13,10
         DB '1. Calculate',13,10
         DB '2. Read history',13,10
         DB '3. Clear history',13,10
         DB '4. Exit',13,10
         DB 'Choose: $'

exprPrompt DB 13,10
           DB 'Input expression:',13,10
           DB 'Example: (3.2+4.5)*(5.1-2.0)/3.0',13,10
           DB 'Press UP to use previous expression.',13,10
           DB '> $'

smallPrompt DB '> $'

stepMsg DB 13,10
        DB 'Step: $'

resultMsg DB 13,10
          DB 'Result = $'

errorMsg DB 13,10
         DB 'Input error, overflow, or divide by zero.$'

byeMsg DB 13,10
       DB 'Bye.$'

saveMsg DB 13,10
        DB 'Saved to HISTORY.TXT.$'

historyTitle DB 13,10
             DB '=========== HISTORY ===========',13,10,'$'

noHistoryMsg DB 13,10
             DB 'No history file.$'

emptyHistoryMsg DB 13,10
                DB 'History is empty.$'

clearMsg DB 13,10
         DB 'History cleared.$'

fileErrMsg DB 13,10
           DB 'File operation error.$'

pauseMsg DB 13,10
         DB '--- Press any key to continue ---$'

lastUseMsg DB 13,10
           DB 'Use previous: $'

noLastMsg DB 13,10
          DB 'No previous expression.',13,10,'$'

crlf DB 13,10,'$'
crlfRaw DB 13,10
equalText DB ' = '

histName DB 'HISTORY.TXT',0

choiceBuf DB 4
          DB 0
          DB 5 DUP(0)

inputBuf DB 100
         DB 0
         DB 101 DUP(0)

lastBuf DB 100 DUP(0)
lastLen DB 0

readBuf DB 128 DUP(0)
oneByte DB 0

parseEnd DW 0
parseErr DB 0

result DW 0

stepA DW 0
stepB DW 0
stepR DW 0
stepOp DB 0

fileHandle DW 0

resultStr DB 20 DUP(0)
resultLen DW 0

hasRead DB 0
lineCount DB 0

scaleVal DW 100

numberValue DW 0
fracValue DW 0
fracCount DB 0
fracFound DB 0

fixedFrac DW 0
fracTens DB 0
fracOnes DB 0

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

    CALL ReadExprLine

    CMP BYTE PTR [inputBuf+1],0
    JE calc_error

    MOV BYTE PTR [parseErr],0

    MOV SI,OFFSET inputBuf+2

    XOR AX,AX
    MOV AL,[inputBuf+1]
    MOV BX,OFFSET inputBuf+2
    ADD BX,AX
    MOV [parseEnd],BX

    CALL ParseExpr

    CMP BYTE PTR [parseErr],0
    JNE calc_error

    CALL SkipSpaces

    CMP SI,[parseEnd]
    JNE calc_error

    MOV [result],AX

    LEA DX,resultMsg
    CALL PrintString

    MOV AX,[result]
    CALL PrintFixed

    LEA DX,crlf
    CALL PrintString

    CALL StoreLastExpr
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

ReadExprLine PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV DI,OFFSET inputBuf
    MOV BYTE PTR [DI+1],0
    XOR BX,BX

rel_loop:
    MOV AH,00H
    INT 16H

    CMP AL,0
    JE rel_extend

    CMP AL,0E0H
    JE rel_extend

    CMP AL,13
    JE rel_done

    CMP AL,8
    JE rel_backspace

    CMP BX,100
    JAE rel_loop

    MOV [DI+BX+2],AL
    INC BX

    MOV DL,AL
    CALL PrintChar

    JMP rel_loop

rel_extend:
    CMP AH,48H
    JE rel_up
    JMP rel_loop

rel_up:
    CMP BYTE PTR [lastLen],0
    JE rel_no_last

    XOR CX,CX
    MOV CL,[lastLen]
    MOV [inputBuf+1],CL

    MOV SI,OFFSET lastBuf
    MOV DI,OFFSET inputBuf+2
    REP MOVSB

    XOR BX,BX
    MOV BL,[inputBuf+1]
    MOV SI,OFFSET inputBuf+2
    ADD SI,BX
    MOV BYTE PTR [SI],0

    LEA DX,lastUseMsg
    CALL PrintString

    MOV BX,1
    LEA DX,inputBuf+2
    XOR CX,CX
    MOV CL,[inputBuf+1]
    MOV AH,40H
    INT 21H

    LEA DX,crlf
    CALL PrintString

    JMP rel_exit

rel_no_last:
    LEA DX,noLastMsg
    CALL PrintString
    LEA DX,smallPrompt
    CALL PrintString
    JMP rel_loop

rel_backspace:
    CMP BX,0
    JE rel_loop

    DEC BX

    MOV DL,8
    CALL PrintChar
    MOV DL,' '
    CALL PrintChar
    MOV DL,8
    CALL PrintChar

    JMP rel_loop

rel_done:
    MOV [inputBuf+1],BL

    MOV SI,OFFSET inputBuf+2
    ADD SI,BX
    MOV BYTE PTR [SI],0

    LEA DX,crlf
    CALL PrintString

rel_exit:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ReadExprLine ENDP

StoreLastExpr PROC
    PUSH AX
    PUSH CX
    PUSH SI
    PUSH DI

    XOR CX,CX
    MOV CL,[inputBuf+1]
    MOV [lastLen],CL

    MOV SI,OFFSET inputBuf+2
    MOV DI,OFFSET lastBuf
    REP MOVSB

    POP DI
    POP SI
    POP CX
    POP AX
    RET
StoreLastExpr ENDP

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
    JNE expr_error_pop

    MOV BX,AX
    POP AX

    MOV [stepA],AX
    MOV [stepB],BX

    ADD AX,BX
    JO expr_overflow

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
    JNE expr_error_pop

    MOV BX,AX
    POP AX

    MOV [stepA],AX
    MOV [stepB],BX

    SUB AX,BX
    JO expr_overflow

    MOV [stepR],AX
    MOV BYTE PTR [stepOp],'-'

    CALL PrintStep

    MOV AX,[stepR]
    JMP expr_loop

expr_error_pop:
    POP BX
    JMP expr_done

expr_overflow:
    MOV BYTE PTR [parseErr],1

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
    JNE term_error_pop

    MOV BX,AX
    POP AX

    MOV [stepA],AX
    MOV [stepB],BX

    IMUL BX
    IDIV WORD PTR [scaleVal]

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
    JNE term_error_pop

    MOV BX,AX
    POP AX

    CMP BX,0
    JE term_div_zero

    MOV [stepA],AX
    MOV [stepB],BX

    IMUL WORD PTR [scaleVal]
    IDIV BX

    MOV [stepR],AX
    MOV BYTE PTR [stepOp],'/'

    CALL PrintStep

    MOV AX,[stepR]
    JMP term_loop

term_error_pop:
    POP BX
    JMP term_done

term_div_zero:
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

    CMP BYTE PTR [parseErr],0
    JNE factor_done

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

    MOV DL,[SI]

    CMP DL,')'
    JNE factor_error

    INC SI
    RET

factor_error:
    MOV BYTE PTR [parseErr],1

factor_done:
    RET
ParseFactor ENDP

ReadNumber PROC
    MOV WORD PTR [numberValue],0
    MOV WORD PTR [fracValue],0
    MOV BYTE PTR [fracCount],0
    MOV BYTE PTR [fracFound],0

rn_int_loop:
    CMP SI,[parseEnd]
    JAE rn_int_done

    MOV DL,[SI]

    CMP DL,'0'
    JB rn_int_done

    CMP DL,'9'
    JA rn_int_done

    SUB DL,'0'
    XOR DH,DH

    MOV BX,DX

    MOV AX,[numberValue]
    MOV CX,10
    MUL CX

    CMP DX,0
    JNE rn_error

    ADD AX,BX
    JC rn_error

    MOV [numberValue],AX

    INC SI
    JMP rn_int_loop

rn_int_done:
    MOV AX,[numberValue]
    MUL WORD PTR [scaleVal]

    CMP DX,0
    JNE rn_error

    CMP AX,32767
    JA rn_error

    MOV [numberValue],AX

    CMP SI,[parseEnd]
    JAE rn_done

    MOV DL,[SI]

    CMP DL,'.'
    JNE rn_done

    INC SI

rn_frac_loop:
    CMP SI,[parseEnd]
    JAE rn_frac_done

    MOV DL,[SI]

    CMP DL,'0'
    JB rn_frac_done

    CMP DL,'9'
    JA rn_frac_done

    CMP BYTE PTR [fracCount],2
    JAE rn_error

    MOV BYTE PTR [fracFound],1

    SUB DL,'0'
    XOR DH,DH
    MOV BX,DX

    MOV AX,[fracValue]
    MOV CX,10
    MUL CX

    ADD AX,BX
    MOV [fracValue],AX

    INC BYTE PTR [fracCount]
    INC SI

    JMP rn_frac_loop

rn_frac_done:
    CMP BYTE PTR [fracFound],1
    JNE rn_error

    CMP BYTE PTR [fracCount],1
    JNE rn_add_frac

    MOV AX,[fracValue]
    MOV CX,10
    MUL CX
    MOV [fracValue],AX

rn_add_frac:
    MOV AX,[numberValue]
    ADD AX,[fracValue]
    JC rn_error

    CMP AX,32767
    JA rn_error

    MOV [numberValue],AX

rn_done:
    MOV AX,[numberValue]
    RET

rn_error:
    MOV BYTE PTR [parseErr],1
    XOR AX,AX
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
    CALL PrintFixed

    MOV DL,' '
    CALL PrintChar

    MOV DL,[stepOp]
    CALL PrintChar

    MOV DL,' '
    CALL PrintChar

    MOV AX,[stepB]
    CALL PrintFixed

    MOV DL,' '
    CALL PrintChar

    MOV DL,'='
    CALL PrintChar

    MOV DL,' '
    CALL PrintChar

    MOV AX,[stepR]
    CALL PrintFixed

    LEA DX,crlf
    CALL PrintString

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PrintStep ENDP

PrintFixed PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    CMP AX,0
    JGE pf_positive

    MOV DL,'-'
    CALL PrintChar

    NEG AX

pf_positive:
    XOR DX,DX
    DIV WORD PTR [scaleVal]

    MOV [fixedFrac],DX

    CALL PrintInt

    CMP WORD PTR [fixedFrac],0
    JE pf_done

    MOV DL,'.'
    CALL PrintChar

    MOV AX,[fixedFrac]
    MOV BL,10
    DIV BL

    MOV [fracTens],AL
    MOV [fracOnes],AH

    MOV DL,[fracTens]
    ADD DL,'0'
    CALL PrintChar

    MOV DL,[fracOnes]
    ADD DL,'0'
    CALL PrintChar

pf_done:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PrintFixed ENDP

PrintInt PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    CMP AX,0
    JNE print_not_zero

    MOV DL,'0'
    CALL PrintChar

    JMP print_done

print_not_zero:
    XOR CX,CX
    MOV BX,10

print_div_loop:
    XOR DX,DX
    DIV BX

    PUSH DX
    INC CX

    CMP AX,0
    JNE print_div_loop

print_pop_loop:
    POP DX

    ADD DL,'0'
    CALL PrintChar

    LOOP print_pop_loop

print_done:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PrintInt ENDP

SaveHistory PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    CALL MakeResultString

    MOV AX,3D02H
    LEA DX,histName
    INT 21H

    JC save_create

    MOV [fileHandle],AX
    JMP save_seek_end

save_create:
    MOV AH,3CH
    MOV CX,0
    LEA DX,histName
    INT 21H

    JC save_error

    MOV [fileHandle],AX

save_seek_end:
    MOV BX,[fileHandle]
    MOV AX,4202H
    XOR CX,CX
    XOR DX,DX
    INT 21H

    JC save_close_error

    MOV BX,[fileHandle]
    LEA DX,inputBuf+2
    XOR CX,CX
    MOV CL,[inputBuf+1]
    MOV AH,40H
    INT 21H

    JC save_close_error

    MOV BX,[fileHandle]
    LEA DX,equalText
    MOV CX,3
    MOV AH,40H
    INT 21H

    JC save_close_error

    MOV BX,[fileHandle]
    LEA DX,resultStr
    MOV CX,[resultLen]
    MOV AH,40H
    INT 21H

    JC save_close_error

    MOV BX,[fileHandle]
    LEA DX,crlfRaw
    MOV CX,2
    MOV AH,40H
    INT 21H

    JC save_close_error

    MOV BX,[fileHandle]
    MOV AH,3EH
    INT 21H

    LEA DX,saveMsg
    CALL PrintString
    LEA DX,crlf
    CALL PrintString

    JMP save_done

save_close_error:
    MOV BX,[fileHandle]
    MOV AH,3EH
    INT 21H

save_error:
    LEA DX,fileErrMsg
    CALL PrintString
    LEA DX,crlf
    CALL PrintString

save_done:
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

    MOV BYTE PTR [hasRead],0
    MOV BYTE PTR [lineCount],0

    MOV AX,3D00H
    LEA DX,histName
    INT 21H

    JC read_no_file

    MOV [fileHandle],AX

read_loop:
    MOV BX,[fileHandle]
    LEA DX,oneByte
    MOV CX,1
    MOV AH,3FH
    INT 21H

    JC read_close

    CMP AX,0
    JE read_close

    MOV BYTE PTR [hasRead],1

    MOV BX,1
    LEA DX,oneByte
    MOV CX,1
    MOV AH,40H
    INT 21H

    CMP BYTE PTR [oneByte],10
    JNE read_loop

    INC BYTE PTR [lineCount]

    CMP BYTE PTR [lineCount],10
    JB read_loop

    LEA DX,pauseMsg
    CALL PrintString

    MOV AH,08H
    INT 21H

    LEA DX,crlf
    CALL PrintString

    MOV BYTE PTR [lineCount],0

    JMP read_loop

read_close:
    MOV BX,[fileHandle]
    MOV AH,3EH
    INT 21H

    CMP BYTE PTR [hasRead],1
    JE read_finish

    LEA DX,emptyHistoryMsg
    CALL PrintString

read_finish:
    LEA DX,crlf
    CALL PrintString
    JMP read_done

read_no_file:
    LEA DX,noHistoryMsg
    CALL PrintString
    LEA DX,crlf
    CALL PrintString

read_done:
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

    JC clear_error

    MOV BX,AX
    MOV AH,3EH
    INT 21H

    LEA DX,clearMsg
    CALL PrintString
    LEA DX,crlf
    CALL PrintString

    JMP clear_done

clear_error:
    LEA DX,fileErrMsg
    CALL PrintString
    LEA DX,crlf
    CALL PrintString

clear_done:
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
    JGE make_positive

    MOV BYTE PTR [DI],'-'
    INC DI
    INC WORD PTR [resultLen]

    NEG AX

make_positive:
    XOR DX,DX
    DIV WORD PTR [scaleVal]

    MOV [fixedFrac],DX

    CALL AppendUnsigned

    CMP WORD PTR [fixedFrac],0
    JE make_done

    MOV BYTE PTR [DI],'.'
    INC DI
    INC WORD PTR [resultLen]

    MOV AX,[fixedFrac]
    MOV BL,10
    DIV BL

    MOV [fracTens],AL
    MOV [fracOnes],AH

    MOV AL,[fracTens]
    ADD AL,'0'
    MOV [DI],AL
    INC DI
    INC WORD PTR [resultLen]

    MOV AL,[fracOnes]
    ADD AL,'0'
    MOV [DI],AL
    INC DI
    INC WORD PTR [resultLen]

make_done:
    MOV BYTE PTR [DI],0

    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
MakeResultString ENDP

AppendUnsigned PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    CMP AX,0
    JNE au_not_zero

    MOV BYTE PTR [DI],'0'
    INC DI
    INC WORD PTR [resultLen]

    JMP au_done

au_not_zero:
    XOR CX,CX
    MOV BX,10

au_div_loop:
    XOR DX,DX
    DIV BX

    PUSH DX
    INC CX

    CMP AX,0
    JNE au_div_loop

au_pop_loop:
    POP DX

    ADD DL,'0'
    MOV [DI],DL

    INC DI
    INC WORD PTR [resultLen]

    LOOP au_pop_loop

au_done:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
AppendUnsigned ENDP

END MAIN