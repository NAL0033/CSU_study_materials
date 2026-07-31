
; =============================================================
; Features:
; 1) One-line expression input
; 2) + - * /, negative numbers, decimal numbers by fixed point x100
; 3) Parentheses and operator precedence
; 4) Step output for every operation
; 5) HISTORY.TXT save/read/clear, 10 lines per page
; 6) Up arrow recalls last expression in this run
; 7) Read history menu can select two history expressions and multiply them
; =============================================================

.MODEL SMALL
.STACK 100H

MAXEXPR EQU 100
MAXHIST EQU 20
SCALE   EQU 100

.DATA
menuText DB 13,10
         DB '=========== CALCULATOR PRO ===========',13,10
         DB '1. Calculate',13,10
         DB '2. Read history',13,10
         DB '3. Clear history',13,10
         DB '4. Exit',13,10
         DB 'Choose: $'

exprPrompt DB 13,10
           DB 'Input expression:',13,10
           DB 'Example: (3.2 + 4.5) * (5.1 - 2.0) / 3.0',13,10
           DB 'Tip: press UP key to recall last expression.',13,10
           DB '> $'

stepTitle DB 13,10,'Steps:',13,10,'$'
stepText  DB 'Step: $'
resultMsg DB 13,10,'Result = $'
errorMsg  DB 13,10,'Input error, overflow, or divide by zero.$'
byeMsg    DB 13,10,'Bye.$'
saveMsg   DB 13,10,'Saved to HISTORY.TXT.$'
historyTitle DB 13,10,'=========== HISTORY ===========',13,10,'$'
noHistoryMsg DB 13,10,'No history record.$'
clearMsg  DB 13,10,'History cleared.$'
fileErrMsg DB 13,10,'File operation error.$'
pageMsg   DB 13,10,'-- Press ENTER for next page, Q to quit --$'
multiAsk  DB 13,10,'Multiply two history expressions? (Y/N): $'
firstAsk  DB 13,10,'First record number: $'
secondAsk DB 13,10,'Second record number: $'
newExprMsg DB 13,10,'New expression: $'
badSelectMsg DB 13,10,'Invalid record number.$'

crlf DB 13,10,'$'
spaceText DB ' $'
equalText DB ' = '
crlfRaw DB 13,10
dotSpace DB '. $'

histName DB 'D:\HISTORY.TXT',0

choiceBuf DB 8
          DB 0
          DB 9 DUP(0)

inputBuf DB MAXEXPR
         DB 0
         DB MAXEXPR+1 DUP(0)

lastLen DB 0
lastExpr DB MAXEXPR+1 DUP(0)

readChar DB 0
resultStr DB 18 DUP(0)
resultLen DW 0

endPtr DW 0
parseErr DB 0
signFlag DB 0
digitSeen DB 0
fracCount DB 0

intPart DW 0
fracPart DW 0
tempLeft DW 0
tempRight DW 0
tempResult DW 0
result DW 0
scaleWord DW SCALE
stepOp DB 0

fileHandle DW 0
lineNo DW 0
pageLines DW 0
atLineStart DB 0
anyByte DB 0
historyQuit DB 0

histCount DW 0
histPos DW 0
copyFlag DB 0
lineHasData DB 0
histExprs DB MAXHIST*MAXEXPR DUP(0)
selA DW 0
selB DW 0
buildLen DW 0
buildErr DB 0

stepLineBuf DB 80 DUP(0)
stepBuf    DB 400 DUP(0)
stepBufPos DW 0

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
    CALL ReadExpressionLine
    CALL CalculateCurrentInput
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

; -------------------------------------------------------------
; DOS buffered line input. DX points to a 0AH buffer.
; -------------------------------------------------------------
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

; -------------------------------------------------------------
; Custom expression input. Supports BACKSPACE and UP arrow recall.
; -------------------------------------------------------------
ReadExpressionLine PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    XOR CX,CX
    MOV DI,OFFSET inputBuf+2

rel_loop:
    MOV AH,08H
    INT 21H

    CMP AL,0DH
    JE rel_done

    CMP AL,08H
    JE rel_backspace

    CMP AL,00H
    JE rel_ext
    CMP AL,0E0H
    JE rel_ext

    MOV BL,[inputBuf]
    XOR BH,BH
    CMP CX,BX
    JAE rel_loop

    MOV [DI],AL
    INC DI
    INC CX
    MOV DL,AL
    CALL PrintChar
    JMP rel_loop

rel_backspace:
    CMP CX,0
    JE rel_loop
    DEC CX
    DEC DI
    MOV DL,08H
    CALL PrintChar
    MOV DL,' '
    CALL PrintChar
    MOV DL,08H
    CALL PrintChar
    JMP rel_loop

rel_ext:
    MOV AH,08H
    INT 21H
    CMP AL,48H              ; UP arrow scan code
    JNE rel_loop
    CMP CX,0
    JNE rel_loop
    CMP BYTE PTR [lastLen],0
    JE rel_loop

    MOV SI,OFFSET lastExpr
rel_copy_last:
    MOV AL,[SI]
    CMP AL,0
    JE rel_loop
    MOV BL,[inputBuf]
    XOR BH,BH
    CMP CX,BX
    JAE rel_loop
    MOV [DI],AL
    INC DI
    INC SI
    INC CX
    MOV DL,AL
    CALL PrintChar
    JMP rel_copy_last

rel_done:
    MOV [inputBuf+1],CL
    MOV BYTE PTR [DI],0
    LEA DX,crlf
    CALL PrintString

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ReadExpressionLine ENDP

CopyInputToLast PROC
    PUSH AX
    PUSH CX
    PUSH SI
    PUSH DI

    XOR CX,CX
    MOV CL,[inputBuf+1]
    MOV [lastLen],CL
    MOV SI,OFFSET inputBuf+2
    MOV DI,OFFSET lastExpr
    REP MOVSB
    MOV BYTE PTR [DI],0

    POP DI
    POP SI
    POP CX
    POP AX
    RET
CopyInputToLast ENDP

ShowInputBuf PROC
    PUSH AX
    PUSH CX
    PUSH DX
    PUSH SI

    XOR CX,CX
    MOV CL,[inputBuf+1]
    MOV SI,OFFSET inputBuf+2
sib_loop:
    CMP CX,0
    JE sib_done
    MOV DL,[SI]
    CALL PrintChar
    INC SI
    DEC CX
    JMP sib_loop
sib_done:
    POP SI
    POP DX
    POP CX
    POP AX
    RET
ShowInputBuf ENDP

; -------------------------------------------------------------
; Calculate the expression already stored in inputBuf.
; -------------------------------------------------------------
CalculateCurrentInput PROC
    PUSH AX
    PUSH DX

    MOV BYTE PTR [parseErr],0
    MOV WORD PTR [stepBufPos],0
    MOV SI,OFFSET inputBuf+2
    XOR AX,AX
    MOV AL,[inputBuf+1]
    MOV BX,OFFSET inputBuf+2
    ADD BX,AX
    MOV [endPtr],BX

    LEA DX,stepTitle
    CALL PrintString

    CALL ParseExpression
    CMP BYTE PTR [parseErr],0
    JNE cci_error

    CALL SkipSpaces
    CMP SI,[endPtr]
    JNE cci_error

    MOV [result],AX

    LEA DX,resultMsg
    CALL PrintString
    MOV AX,[result]
    CALL PrintFixed
    LEA DX,crlf
    CALL PrintString

    CALL SaveHistory
    CALL CopyInputToLast
    JMP cci_done

cci_error:
    LEA DX,errorMsg
    CALL PrintString
    LEA DX,crlf
    CALL PrintString

cci_done:
    POP DX
    POP AX
    RET
CalculateCurrentInput ENDP

; -------------------------------------------------------------
; Recursive descent parser:
; Expression = Term {(+|-) Term}
; Term       = Factor {(*|/) Factor}
; Factor     = number | '(' Expression ')' | unary + - Factor
; All numbers use fixed point: real value * 100.
; -------------------------------------------------------------
SkipSpaces PROC
ss_loop:
    CMP SI,[endPtr]
    JAE ss_done
    CMP BYTE PTR [SI],' '
    JNE ss_done
    INC SI
    JMP ss_loop
ss_done:
    RET
SkipSpaces ENDP

ParseExpression PROC
    CALL ParseTerm
    CMP BYTE PTR [parseErr],0
    JNE pe_done

pe_loop:
    CALL SkipSpaces
    CMP SI,[endPtr]
    JAE pe_done

    MOV DL,[SI]
    CMP DL,'+'
    JE pe_op
    CMP DL,'-'
    JE pe_op
    JMP pe_done

pe_op:
    INC SI
    PUSH AX                 ; left
    PUSH DX                 ; operator in DL
    CALL ParseTerm
    POP DX
    POP BX                  ; BX = left, AX = right

    CMP BYTE PTR [parseErr],0
    JNE pe_done

    MOV [tempLeft],BX
    MOV [tempRight],AX
    MOV [stepOp],DL

    MOV AX,BX
    CMP DL,'+'
    JE pe_add
    SUB AX,[tempRight]
    JMP pe_store
pe_add:
    ADD AX,[tempRight]
pe_store:
    MOV [tempResult],AX
    CALL PrintStep
    MOV AX,[tempResult]
    JMP pe_loop

pe_done:
    RET
ParseExpression ENDP

ParseTerm PROC
    CALL ParseFactor
    CMP BYTE PTR [parseErr],0
    JNE pt_done

pt_loop:
    CALL SkipSpaces
    CMP SI,[endPtr]
    JAE pt_done

    MOV DL,[SI]
    CMP DL,'*'
    JE pt_op
    CMP DL,'/'
    JE pt_op
    JMP pt_done

pt_op:
    INC SI
    PUSH AX                 ; left
    PUSH DX                 ; operator
    CALL ParseFactor
    POP DX
    POP BX                  ; BX = left, AX = right

    CMP BYTE PTR [parseErr],0
    JNE pt_done

    MOV [tempLeft],BX
    MOV [tempRight],AX
    MOV [stepOp],DL

    CMP DL,'*'
    JE pt_mul

pt_div:
    CMP WORD PTR [tempRight],0
    JE pt_error
    MOV AX,[tempLeft]
    IMUL WORD PTR [scaleWord]       ; DX:AX = left * 100
    IDIV WORD PTR [tempRight]       ; (left * 100) / right
    JMP pt_store

pt_mul:
    MOV AX,[tempLeft]
    IMUL WORD PTR [tempRight]       ; DX:AX = left * right
    IDIV WORD PTR [scaleWord]       ; / 100

pt_store:
    MOV [tempResult],AX
    CALL PrintStep
    MOV AX,[tempResult]
    JMP pt_loop

pt_error:
    MOV BYTE PTR [parseErr],1
pt_done:
    RET
ParseTerm ENDP

ParseFactor PROC
    CALL SkipSpaces
    MOV BYTE PTR [signFlag],0

pf_sign_loop:
    CALL SkipSpaces
    CMP SI,[endPtr]
    JAE pf_error
    MOV AL,[SI]
    CMP AL,'+'
    JE pf_plus
    CMP AL,'-'
    JE pf_minus
    JMP pf_body

pf_plus:
    INC SI
    JMP pf_sign_loop
pf_minus:
    XOR BYTE PTR [signFlag],1
    INC SI
    JMP pf_sign_loop

pf_body:
    CMP BYTE PTR [SI],'('
    JE pf_paren

    CALL ParseNumber
    CMP BYTE PTR [parseErr],0
    JNE pf_done
    CMP BYTE PTR [signFlag],0
    JE pf_done
    NEG AX
    JMP pf_done

pf_paren:
    INC SI
    CALL ParseExpression
    CMP BYTE PTR [parseErr],0
    JNE pf_done
    CALL SkipSpaces
    CMP SI,[endPtr]
    JAE pf_error
    CMP BYTE PTR [SI],')'
    JNE pf_error
    INC SI
    CMP BYTE PTR [signFlag],0
    JE pf_done
    NEG AX
    JMP pf_done

pf_error:
    MOV BYTE PTR [parseErr],1
pf_done:
    RET
ParseFactor ENDP

ParseNumber PROC
    MOV WORD PTR [intPart],0
    MOV WORD PTR [fracPart],0
    MOV BYTE PTR [fracCount],0
    MOV BYTE PTR [digitSeen],0

pn_int_loop:
    CMP SI,[endPtr]
    JAE pn_after_int
    MOV AL,[SI]
    CMP AL,'0'
    JB pn_after_int
    CMP AL,'9'
    JA pn_after_int

    MOV BYTE PTR [digitSeen],1
    SUB AL,'0'
    XOR AH,AH
    PUSH AX
    MOV AX,[intPart]
    MOV BX,10
    MUL BX
    POP BX
    ADD AX,BX
    MOV [intPart],AX
    INC SI
    JMP pn_int_loop

pn_after_int:
    CMP SI,[endPtr]
    JAE pn_make
    CMP BYTE PTR [SI],'.'
    JNE pn_make
    INC SI

pn_dec_loop:
    CMP SI,[endPtr]
    JAE pn_make
    MOV AL,[SI]
    CMP AL,'0'
    JB pn_make
    CMP AL,'9'
    JA pn_make

    MOV BYTE PTR [digitSeen],1
    SUB AL,'0'
    XOR AH,AH

    CMP BYTE PTR [fracCount],0
    JE pn_first_dec
    CMP BYTE PTR [fracCount],1
    JE pn_second_dec
    JMP pn_skip_extra

pn_first_dec:
    MOV BL,10
    MUL BL                  ; AX = digit * 10
    ADD [fracPart],AX
    INC BYTE PTR [fracCount]
    JMP pn_skip_extra

pn_second_dec:
    ADD [fracPart],AX
    INC BYTE PTR [fracCount]

pn_skip_extra:
    INC SI
    JMP pn_dec_loop

pn_make:
    CMP BYTE PTR [digitSeen],0
    JE pn_error
    MOV AX,[intPart]
    MOV BX,SCALE
    MUL BX
    ADD AX,[fracPart]
    RET

pn_error:
    MOV BYTE PTR [parseErr],1
    RET
ParseNumber ENDP

; -------------------------------------------------------------
; Output one calculation step: left op right = result
; -------------------------------------------------------------
PrintStep PROC
    PUSH AX
    PUSH DX

    LEA DX,stepText
    CALL PrintString
    MOV AX,[tempLeft]
    CALL PrintFixed
    MOV DL,' '
    CALL PrintChar
    MOV DL,[stepOp]
    CALL PrintChar
    MOV DL,' '
    CALL PrintChar
    MOV AX,[tempRight]
    CALL PrintFixed
    LEA DX,equalText
    MOV AH,09H              ; equalText is not $-ended; use manual print below instead
    ; fall through is unsafe for AH=09, so print manually
    MOV DL,' '
    CALL PrintChar
    MOV DL,'='
    CALL PrintChar
    MOV DL,' '
    CALL PrintChar
    MOV AX,[tempResult]
    CALL PrintFixed
    LEA DX,crlf
    CALL PrintString

    CALL BufferStep

    POP DX
    POP AX
    RET
PrintStep ENDP

; -------------------------------------------------------------
; Append fixed-point number string to buffer at DI.
; Input: AX = value * SCALE, DI = buffer pointer
; Output: DI updated past the formatted string
; -------------------------------------------------------------
AppendFixed PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    CMP AX,0
    JGE af_pos
    MOV BYTE PTR [DI],'-'
    INC DI
    NEG AX

af_pos:
    XOR DX,DX
    MOV BX,SCALE
    DIV BX
    PUSH DX

    CMP AX,0
    JNE af_int_nz
    MOV BYTE PTR [DI],'0'
    INC DI
    JMP af_int_done

af_int_nz:
    XOR CX,CX
    MOV BX,10
af_div:
    XOR DX,DX
    DIV BX
    PUSH DX
    INC CX
    CMP AX,0
    JNE af_div
af_pop:
    POP DX
    ADD DL,'0'
    MOV [DI],DL
    INC DI
    LOOP af_pop

af_int_done:
    MOV BYTE PTR [DI],'.'
    INC DI
    POP AX
    XOR AH,AH
    MOV BL,10
    DIV BL
    MOV DH,AH
    ADD AL,'0'
    MOV [DI],AL
    INC DI
    MOV AL,DH
    ADD AL,'0'
    MOV [DI],AL
    INC DI

    POP DX
    POP CX
    POP BX
    POP AX
    RET
AppendFixed ENDP

; -------------------------------------------------------------
; Save one step record to HISTORY.TXT.
; Writes: "Step: tempLeft op tempRight = tempResult"
; -------------------------------------------------------------
BufferStep PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH SI

    LEA DI,stepLineBuf

    MOV BYTE PTR [DI],'S'
    INC DI
    MOV BYTE PTR [DI],'t'
    INC DI
    MOV BYTE PTR [DI],'e'
    INC DI
    MOV BYTE PTR [DI],'p'
    INC DI
    MOV BYTE PTR [DI],':'
    INC DI
    MOV BYTE PTR [DI],' '
    INC DI

    MOV AX,[tempLeft]
    CALL AppendFixed

    MOV BYTE PTR [DI],' '
    INC DI
    MOV AL,[stepOp]
    MOV [DI],AL
    INC DI
    MOV BYTE PTR [DI],' '
    INC DI

    MOV AX,[tempRight]
    CALL AppendFixed

    MOV BYTE PTR [DI],' '
    INC DI
    MOV BYTE PTR [DI],'='
    INC DI
    MOV BYTE PTR [DI],' '
    INC DI

    MOV AX,[tempResult]
    CALL AppendFixed

    MOV BYTE PTR [DI],13
    INC DI
    MOV BYTE PTR [DI],10
    INC DI

    MOV CX,DI
    LEA BX,stepLineBuf
    SUB CX,BX

    PUSH CX
    PUSH ES
    PUSH DS
    POP ES
    MOV SI,OFFSET stepLineBuf
    MOV DI,OFFSET stepBuf
    ADD DI,[stepBufPos]
    REP MOVSB
    POP ES
    POP CX
    ADD [stepBufPos],CX

    POP SI
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
BufferStep ENDP

; -------------------------------------------------------------
; Print fixed point AX / 100, always with two decimal digits.
; -------------------------------------------------------------
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
    MOV BX,SCALE
    DIV BX                  ; AX = integer part, DX = fraction 0..99
    PUSH DX
    CALL PrintUInt
    MOV DL,'.'
    CALL PrintChar
    POP AX
    CALL PrintTwoDigits

    POP DX
    POP CX
    POP BX
    POP AX
    RET
PrintFixed ENDP

PrintUInt PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    CMP AX,0
    JNE pu_not_zero
    MOV DL,'0'
    CALL PrintChar
    JMP pu_done

pu_not_zero:
    XOR CX,CX
    MOV BX,10
pu_div_loop:
    XOR DX,DX
    DIV BX
    PUSH DX
    INC CX
    CMP AX,0
    JNE pu_div_loop

pu_print_loop:
    POP DX
    ADD DL,'0'
    CALL PrintChar
    LOOP pu_print_loop

pu_done:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PrintUInt ENDP

PrintTwoDigits PROC
    PUSH AX
    PUSH BX
    PUSH DX

    XOR AH,AH
    MOV BL,10
    DIV BL                  ; AL=tens, AH=ones
    MOV DH,AH
    ADD AL,'0'
    MOV DL,AL
    CALL PrintChar
    MOV DL,DH
    ADD DL,'0'
    CALL PrintChar

    POP DX
    POP BX
    POP AX
    RET
PrintTwoDigits ENDP

; -------------------------------------------------------------
; Save expression and fixed result to HISTORY.TXT
; -------------------------------------------------------------
SaveHistory PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    CALL MakeFixedString

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
    JNC sh_skip5
    JMP sh_file_error
sh_skip5:
    MOV [fileHandle],AX

sh_seek_end:
    MOV BX,[fileHandle]
    MOV AX,4202H
    XOR CX,CX
    XOR DX,DX
    INT 21H

    CMP WORD PTR [stepBufPos],0
    JE sh_no_steps
    MOV BX,[fileHandle]
    LEA DX,stepBuf
    MOV CX,[stepBufPos]
    MOV AH,40H
    INT 21H

sh_no_steps:
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

MakeFixedString PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI

    LEA DI,resultStr
    MOV WORD PTR [resultLen],0
    MOV AX,[result]

    CMP AX,0
    JGE mfs_positive
    MOV BYTE PTR [DI],'-'
    INC DI
    INC WORD PTR [resultLen]
    NEG AX

mfs_positive:
    XOR DX,DX
    MOV BX,SCALE
    DIV BX                  ; AX integer, DX fraction
    PUSH DX
    CALL AppendUInt
    MOV BYTE PTR [DI],'.'
    INC DI
    INC WORD PTR [resultLen]
    POP AX
    CALL AppendTwoDigits

    MOV BYTE PTR [DI],0

    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
MakeFixedString ENDP

AppendUInt PROC
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
AppendUInt ENDP

AppendTwoDigits PROC
    PUSH AX
    PUSH BX
    PUSH DX

    XOR AH,AH
    MOV BL,10
    DIV BL
    MOV DH,AH
    ADD AL,'0'
    MOV [DI],AL
    INC DI
    INC WORD PTR [resultLen]
    MOV AL,DH
    ADD AL,'0'
    MOV [DI],AL
    INC DI
    INC WORD PTR [resultLen]

    POP DX
    POP BX
    POP AX
    RET
AppendTwoDigits ENDP

; -------------------------------------------------------------
; Read history, 10 records per page, then optional multiply records.
; -------------------------------------------------------------
ReadHistory PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    LEA DX,historyTitle
    CALL PrintString

    MOV WORD PTR [lineNo],1
    MOV WORD PTR [pageLines],0
    MOV BYTE PTR [atLineStart],1
    MOV BYTE PTR [anyByte],0
    MOV BYTE PTR [historyQuit],0

    MOV AX,3D00H
    LEA DX,histName
    INT 21H
    JNC rh_skip1
    JMP rh_no_file
rh_skip1:
    MOV [fileHandle],AX

rh_read_loop:
    MOV BX,[fileHandle]
    LEA DX,readChar
    MOV CX,1
    MOV AH,3FH
    INT 21H
    JNC rh_skip2
    JMP rh_close
rh_skip2:
    CMP AX,0
    JE rh_eof

    MOV BYTE PTR [anyByte],1
    MOV AL,[readChar]
    CMP AL,10
    JE rh_read_loop
    CMP AL,13
    JE rh_new_line

    CMP BYTE PTR [atLineStart],1
    JNE rh_print_char
    MOV AX,[lineNo]
    CALL PrintUInt
    LEA DX,dotSpace
    CALL PrintString
    MOV BYTE PTR [atLineStart],0

rh_print_char:
    MOV DL,[readChar]
    CALL PrintChar
    JMP rh_read_loop

rh_new_line:
    LEA DX,crlf
    CALL PrintString
    INC WORD PTR [lineNo]
    INC WORD PTR [pageLines]
    MOV BYTE PTR [atLineStart],1
    CMP WORD PTR [pageLines],10
    JB rh_read_loop

    MOV WORD PTR [pageLines],0
    LEA DX,pageMsg
    CALL PrintString
    MOV AH,08H
    INT 21H
    LEA DX,crlf
    CALL PrintString
    CMP AL,'q'
    JE rh_quit_page
    CMP AL,'Q'
    JE rh_quit_page
    JMP rh_read_loop

rh_quit_page:
    MOV BYTE PTR [historyQuit],1
    JMP rh_close

rh_eof:
    CMP BYTE PTR [anyByte],0
    JNE rh_close
    LEA DX,noHistoryMsg
    CALL PrintString
    LEA DX,crlf
    CALL PrintString

rh_close:
    MOV BX,[fileHandle]
    MOV AH,3EH
    INT 21H
    CMP BYTE PTR [anyByte],0
    JE rh_done
    CMP BYTE PTR [historyQuit],1
    JE rh_done
    CALL AskHistoryMultiply
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

AskHistoryMultiply PROC
    PUSH AX
    PUSH BX
    PUSH DX

    CALL LoadHistoryMemory
    CMP WORD PTR [histCount],2
    JNB ahm_skip
    JMP ahm_done
ahm_skip:

    LEA DX,multiAsk
    CALL PrintString
    MOV AH,01H
    INT 21H
    LEA DX,crlf
    CALL PrintString
    CMP AL,'Y'
    JE ahm_yes
    CMP AL,'y'
    JNE ahm_done

ahm_yes:
    LEA DX,firstAsk
    CALL PrintString
    LEA DX,choiceBuf
    CALL ReadLine
    CALL BufferToNumber
    MOV [selA],AX

    LEA DX,secondAsk
    CALL PrintString
    LEA DX,choiceBuf
    CALL ReadLine
    CALL BufferToNumber
    MOV [selB],AX

    MOV AX,[selA]
    CMP AX,1
    JB ahm_bad
    CMP AX,[histCount]
    JA ahm_bad
    MOV AX,[selB]
    CMP AX,1
    JB ahm_bad
    CMP AX,[histCount]
    JA ahm_bad

    CALL ComposeHistoryMul
    CMP BYTE PTR [buildErr],0
    JNE ahm_bad

    LEA DX,newExprMsg
    CALL PrintString
    CALL ShowInputBuf
    LEA DX,crlf
    CALL PrintString
    CALL CalculateCurrentInput
    JMP ahm_done

ahm_bad:
    LEA DX,badSelectMsg
    CALL PrintString
    LEA DX,crlf
    CALL PrintString

ahm_done:
    POP DX
    POP BX
    POP AX
    RET
AskHistoryMultiply ENDP

BufferToNumber PROC
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    XOR AX,AX
    XOR CX,CX
    MOV CL,[choiceBuf+1]
    MOV SI,OFFSET choiceBuf+2
btn_loop:
    CMP CX,0
    JE btn_done
    MOV DL,[SI]
    CMP DL,'0'
    JB btn_next
    CMP DL,'9'
    JA btn_next
    SUB DL,'0'
    PUSH DX
    MOV BX,10
    MUL BX
    POP DX
    XOR DH,DH
    ADD AX,DX
btn_next:
    INC SI
    DEC CX
    JMP btn_loop
btn_done:
    POP SI
    POP DX
    POP CX
    POP BX
    RET
BufferToNumber ENDP

LoadHistoryMemory PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV WORD PTR [histCount],0

    MOV AX,3D00H
    LEA DX,histName
    INT 21H
    JNC lhm_skip
    JMP lhm_done
lhm_skip:
    MOV [fileHandle],AX

lhm_next_line:
    CMP WORD PTR [histCount],MAXHIST
    JB lhm_skip2
    JMP lhm_close
lhm_skip2:

    MOV AX,[histCount]
    MOV BX,MAXEXPR
    MUL BX
    MOV DI,OFFSET histExprs
    ADD DI,AX
    MOV WORD PTR [histPos],0
    MOV BYTE PTR [copyFlag],1
    MOV BYTE PTR [lineHasData],0

lhm_read:
    MOV BX,[fileHandle]
    LEA DX,readChar
    MOV CX,1
    MOV AH,3FH
    INT 21H
    JNC lhm_skip4
    JMP lhm_close
lhm_skip4:
    CMP AX,0
    JE lhm_eof

    MOV AL,[readChar]
    CMP AL,10
    JE lhm_read
    CMP AL,13
    JE lhm_finish_line

    MOV BYTE PTR [lineHasData],1
    CMP BYTE PTR [copyFlag],1
    JNE lhm_read
    CMP AL,'='
    JE lhm_stop_copy

    MOV BX,[histPos]
    CMP BX,MAXEXPR-1
    JAE lhm_read
    MOV [DI+BX],AL
    INC WORD PTR [histPos]
    JMP lhm_read

lhm_stop_copy:
    MOV BYTE PTR [copyFlag],0
lhm_trim_loop:
    MOV BX,[histPos]
    CMP BX,0
    JE lhm_trim_done
    MOV SI,DI
    ADD SI,BX
    DEC SI
    CMP BYTE PTR [SI],' '
    JNE lhm_trim_done
    DEC WORD PTR [histPos]
    JMP lhm_trim_loop
lhm_trim_done:
    MOV BX,[histPos]
    MOV BYTE PTR [DI+BX],0
    JMP lhm_read

lhm_finish_line:
    CMP BYTE PTR [lineHasData],0
    JNE lhm_skip3
    JMP lhm_next_line
lhm_skip3:
    MOV BX,[histPos]
    MOV BYTE PTR [DI+BX],0
    INC WORD PTR [histCount]
    JMP lhm_next_line

lhm_eof:
    CMP BYTE PTR [lineHasData],0
    JE lhm_close
    MOV BX,[histPos]
    MOV BYTE PTR [DI+BX],0
    INC WORD PTR [histCount]

lhm_close:
    MOV BX,[fileHandle]
    MOV AH,3EH
    INT 21H

lhm_done:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
LoadHistoryMemory ENDP

ComposeHistoryMul PROC
    PUSH AX
    PUSH BX
    PUSH SI
    PUSH DI

    MOV BYTE PTR [buildErr],0
    MOV WORD PTR [buildLen],0
    MOV DI,OFFSET inputBuf+2

    MOV AL,'('
    CALL AppendCharInput
    MOV AX,[selA]
    CALL GetHistPtr
    CALL AppendZInput
    MOV AL,')'
    CALL AppendCharInput
    MOV AL,'*'
    CALL AppendCharInput
    MOV AL,'('
    CALL AppendCharInput
    MOV AX,[selB]
    CALL GetHistPtr
    CALL AppendZInput
    MOV AL,')'
    CALL AppendCharInput

    MOV AX,[buildLen]
    MOV [inputBuf+1],AL
    MOV BYTE PTR [DI],0

    POP DI
    POP SI
    POP BX
    POP AX
    RET
ComposeHistoryMul ENDP

GetHistPtr PROC
    DEC AX
    MOV BX,MAXEXPR
    MUL BX
    MOV SI,OFFSET histExprs
    ADD SI,AX
    RET
GetHistPtr ENDP

AppendCharInput PROC
    CMP WORD PTR [buildLen],MAXEXPR
    JAE aci_error
    MOV [DI],AL
    INC DI
    INC WORD PTR [buildLen]
    RET
aci_error:
    MOV BYTE PTR [buildErr],1
    RET
AppendCharInput ENDP

AppendZInput PROC
azi_loop:
    CMP BYTE PTR [buildErr],0
    JNE azi_done
    MOV AL,[SI]
    CMP AL,0
    JE azi_done
    CALL AppendCharInput
    INC SI
    JMP azi_loop
azi_done:
    RET
AppendZInput ENDP

; -------------------------------------------------------------
; Clear history by truncating/creating HISTORY.TXT
; -------------------------------------------------------------
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

END MAIN
