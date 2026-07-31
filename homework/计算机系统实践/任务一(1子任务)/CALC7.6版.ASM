.MODEL SMALL
.386
.STACK 400h

.DATA

SCALE1000 EQU 1000
MAXLEN    EQU 180

menuStr db 13,10
        db '========== Assembly Calculator ==========',13,10
        db '1. Calculate',13,10
        db '2. Read history',13,10
        db '3. Clear history',13,10
        db '4. Exit',13,10
        db '5. Bonus: multiply two history expressions',13,10
        db 'Choose: $'

promptExpr db 13,10,'Input expression. Press UP to use last expression.',13,10,'> $'
stepsTitle db 13,10,'Steps:',13,10,'$'
stepPrefix db '  $'
resultMsg db 13,10,'Final result = $'
syntaxErr db 13,10,'Syntax error.$'
calcErr db 13,10,'Calculation failed.$'
divZeroMsg db 13,10,'Error: division by zero.$'
waitMsg db 13,10,'Press any key to return to menu...$'
noHistMsg db 13,10,'No history file.$'
histTitle db 13,10,'History:',13,10,'$'
clearOkMsg db 13,10,'History cleared.$'
clearFailMsg db 13,10,'Failed to clear history.$'
pageMsg db 13,10,'--- Press any key for next page ---$'
noLastMsg db 13,10,'No previous expression.$'
useLastMsg db 13,10,'Use last expression: $'
invalidMsg db 13,10,'Invalid choice.$'

bonusTitle db 13,10,'Choose two expressions from first 10 history records:',13,10,'$'
chooseFirst db 13,10,'First number: $'
chooseSecond db 13,10,'Second number: $'
bonusExprMsg db 13,10,'Generated expression: $'
notEnoughHist db 13,10,'Not enough history records.$'
bonusFailMsg db 13,10,'Invalid history selection.$'

crlfStr db 13,10,'$'
crlfRaw db 13,10

histName db 'history.txt',0

exprBuf   db MAXLEN dup(0)
lastExpr  db MAXLEN dup(0)
tempLine  db MAXLEN dup(0)
histTable db 10*MAXLEN dup(0)

exprLen dw 0
lastLen dw 0
tempLen dw 0

histCount db 0
sel1 db 0
sel2 db 0

fileChar db 0
digitBuf db 16 dup(0)

errorFlag db 0
opChar db 0

opLeft   dd 0
opRight  dd 0
opResult dd 0
finalValue dd 0

.CODE

start:
    mov ax, @data
    mov ds, ax
    mov es, ax

    call LoadLastHistory

MainMenu:
    call PrintMenu

    mov ah, 01h
    int 21h

    call PrintCRLF

    cmp al, '1'
    je DoCalculate

    cmp al, '2'
    je DoReadHistory

    cmp al, '3'
    je DoClearHistory

    cmp al, '4'
    je DoExit

    cmp al, '5'
    je DoBonus

    mov dx, OFFSET invalidMsg
    call PrintStr
    call WaitAny
    jmp MainMenu

DoCalculate:
    call ReadExpression
    call EvaluateCurrentExpression
    call WaitAny
    jmp MainMenu

DoReadHistory:
    call ReadHistory
    call WaitAny
    jmp MainMenu

DoClearHistory:
    call ClearHistory
    call WaitAny
    jmp MainMenu

DoBonus:
    call BuildHistoryMulExpression
    cmp exprLen, 0
    je DoBonusEnd

    mov dx, OFFSET bonusExprMsg
    call PrintStr

    mov dx, OFFSET exprBuf
    call PrintZ

    call PrintCRLF
    call EvaluateCurrentExpression

DoBonusEnd:
    call WaitAny
    jmp MainMenu

DoExit:
    mov ax, 4C00h
    int 21h


; =========================================================
; Basic Output
; =========================================================

PrintMenu PROC NEAR
    mov dx, OFFSET menuStr
    call PrintStr
    ret
PrintMenu ENDP

PrintStr PROC NEAR
    mov ah, 09h
    int 21h
    ret
PrintStr ENDP

PrintCRLF PROC NEAR
    push dx
    mov dx, OFFSET crlfStr
    call PrintStr
    pop dx
    ret
PrintCRLF ENDP

PrintCharDL PROC NEAR
    push ax
    mov ah, 02h
    int 21h
    pop ax
    ret
PrintCharDL ENDP

PrintZ PROC NEAR
    push ax
    push dx
    push si

    mov si, dx

PZ_Loop:
    mov al, [si]
    cmp al, 0
    je PZ_End

    mov dl, al
    call PrintCharDL

    inc si
    jmp PZ_Loop

PZ_End:
    pop si
    pop dx
    pop ax
    ret
PrintZ ENDP

WaitAny PROC NEAR
    mov dx, OFFSET waitMsg
    call PrintStr
    mov ah, 00h
    int 16h
    ret
WaitAny ENDP


; =========================================================
; Read Expression
; =========================================================

ReadExpression PROC NEAR
    push ax
    push dx
    push si
    push di

    mov dx, OFFSET promptExpr
    call PrintStr

    xor di, di

RE_Loop:
    mov ah, 00h
    int 16h

    cmp ah, 48h
    je RE_UseLast

    cmp al, 13
    je RE_Done

    cmp al, 8
    je RE_Backspace

    cmp al, 0
    je RE_Loop

    cmp di, MAXLEN-1
    jae RE_Loop

    mov exprBuf[di], al
    inc di

    mov dl, al
    call PrintCharDL

    jmp RE_Loop

RE_Backspace:
    cmp di, 0
    je RE_Loop

    dec di

    mov dl, 8
    call PrintCharDL

    mov dl, ' '
    call PrintCharDL

    mov dl, 8
    call PrintCharDL

    jmp RE_Loop

RE_UseLast:
    cmp lastLen, 0
    jne RE_HasLast

    mov dx, OFFSET noLastMsg
    call PrintStr
    jmp RE_Loop

RE_HasLast:
    call PrintCRLF

    mov dx, OFFSET useLastMsg
    call PrintStr

    mov si, OFFSET lastExpr
    mov di, OFFSET exprBuf

RE_CopyLast:
    mov al, [si]
    mov [di], al

    cmp al, 0
    je RE_LastCopied

    inc si
    inc di
    jmp RE_CopyLast

RE_LastCopied:
    mov ax, di
    sub ax, OFFSET exprBuf
    mov exprLen, ax

    mov dx, OFFSET exprBuf
    call PrintZ

    jmp RE_Loop

RE_Done:
    mov BYTE PTR exprBuf[di], 0
    mov exprLen, di
    call PrintCRLF

    pop di
    pop si
    pop dx
    pop ax
    ret
ReadExpression ENDP


; =========================================================
; Evaluate
; =========================================================

EvaluateCurrentExpression PROC NEAR
    push ebx
    push ecx
    push edx
    push si

    cmp exprLen, 0
    je ECE_End

    call SaveHistory
    call CopyExprToLast

    mov errorFlag, 0

    mov dx, OFFSET stepsTitle
    call PrintStr

    mov si, OFFSET exprBuf
    call ParseExpression

    mov DWORD PTR finalValue, eax

    call SkipSpaces

    cmp BYTE PTR [si], 0
    je ECE_CheckError

    mov errorFlag, 1
    mov dx, OFFSET syntaxErr
    call PrintStr
    call PrintCRLF

ECE_CheckError:
    cmp errorFlag, 0
    jne ECE_Failed

    mov dx, OFFSET resultMsg
    call PrintStr

    mov eax, DWORD PTR finalValue
    call PrintScaled

    call PrintCRLF
    jmp ECE_End

ECE_Failed:
    mov dx, OFFSET calcErr
    call PrintStr
    call PrintCRLF

ECE_End:
    pop si
    pop edx
    pop ecx
    pop ebx
    ret
EvaluateCurrentExpression ENDP


; =========================================================
; Parser
; Expression = Term { + Term | - Term }
; Term       = Factor { * Factor | / Factor }
; Factor     = Number | ( Expression ) | +Factor | -Factor
; =========================================================

SkipSpaces PROC NEAR
SS_Loop:
    mov al, [si]

    cmp al, ' '
    je SS_Next

    cmp al, 9
    je SS_Next

    ret

SS_Next:
    inc si
    jmp SS_Loop
SkipSpaces ENDP


ParseExpression PROC NEAR
    call ParseTerm

PE_Loop:
    call SkipSpaces

    mov bl, [si]

    cmp bl, '+'
    je PE_Add

    cmp bl, '-'
    je PE_Sub

    ret

PE_Add:
    inc si

    mov DWORD PTR opLeft, eax
    push eax

    call ParseTerm

    mov DWORD PTR opRight, eax
    mov ebx, eax

    pop eax

    add eax, ebx

    mov DWORD PTR opResult, eax
    mov opChar, '+'

    call PrintStep

    jmp PE_Loop

PE_Sub:
    inc si

    mov DWORD PTR opLeft, eax
    push eax

    call ParseTerm

    mov DWORD PTR opRight, eax
    mov ebx, eax

    pop eax

    sub eax, ebx

    mov DWORD PTR opResult, eax
    mov opChar, '-'

    call PrintStep

    jmp PE_Loop
ParseExpression ENDP


ParseTerm PROC NEAR
    call ParseFactor

PT_Loop:
    call SkipSpaces

    mov bl, [si]

    cmp bl, '*'
    je PT_Mul

    cmp bl, '/'
    je PT_Div

    ret

PT_Mul:
    inc si

    mov DWORD PTR opLeft, eax
    push eax

    call ParseFactor

    mov DWORD PTR opRight, eax
    mov ebx, eax

    pop eax

    imul ebx

    mov ecx, SCALE1000
    idiv ecx

    mov DWORD PTR opResult, eax
    mov opChar, '*'

    call PrintStep

    jmp PT_Loop

PT_Div:
    inc si

    mov DWORD PTR opLeft, eax
    push eax

    call ParseFactor

    mov DWORD PTR opRight, eax
    mov ebx, eax

    pop eax

    cmp ebx, 0
    jne PT_DoDiv

    mov errorFlag, 1
    mov dx, OFFSET divZeroMsg
    call PrintStr
    call PrintCRLF

    xor eax, eax
    jmp PT_Loop

PT_DoDiv:
    mov ecx, SCALE1000
    imul ecx

    idiv ebx

    mov DWORD PTR opResult, eax
    mov opChar, '/'

    call PrintStep

    jmp PT_Loop
ParseTerm ENDP


ParseFactor PROC NEAR
    call SkipSpaces

    mov bl, [si]

    cmp bl, '-'
    je PF_Neg

    cmp bl, '+'
    je PF_Pos

    cmp bl, '('
    je PF_Paren

    call ParseNumber
    ret

PF_Neg:
    inc si
    call ParseFactor
    neg eax
    ret

PF_Pos:
    inc si
    call ParseFactor
    ret

PF_Paren:
    inc si

    call ParseExpression

    call SkipSpaces

    cmp BYTE PTR [si], ')'
    je PF_RightParen

    mov errorFlag, 1
    mov dx, OFFSET syntaxErr
    call PrintStr
    call PrintCRLF
    ret

PF_RightParen:
    inc si
    ret
ParseFactor ENDP


; =========================================================
; Parse Number
; Input:  SI points to number
; Output: EAX = fixed point number * 1000
; =========================================================

ParseNumber PROC NEAR
    push ebx
    push ecx
    push edx
    push edi

    xor eax, eax
    xor edx, edx
    xor ecx, ecx
    xor edi, edi

PN_IntLoop:
    mov bl, [si]

    cmp bl, '0'
    jb PN_CheckDot

    cmp bl, '9'
    ja PN_CheckDot

    movzx ebx, bl
    sub ebx, '0'

    push ebx
    mov ebx, 10
    imul eax, ebx
    pop ebx

    add eax, ebx

    inc si
    inc ecx

    jmp PN_IntLoop

PN_CheckDot:
    cmp BYTE PTR [si], '.'
    jne PN_Finish

    inc si

PN_FracLoop:
    mov bl, [si]

    cmp bl, '0'
    jb PN_Finish

    cmp bl, '9'
    ja PN_Finish

    inc ecx

    cmp edi, 3
    jae PN_SkipExtraFrac

    movzx ebx, bl
    sub ebx, '0'

    push ebx
    mov ebx, 10
    imul edx, ebx
    pop ebx

    add edx, ebx

    inc edi

PN_SkipExtraFrac:
    inc si
    jmp PN_FracLoop

PN_Finish:
    cmp ecx, 0
    jne PN_PadFrac

    mov errorFlag, 1
    mov dx, OFFSET syntaxErr
    call PrintStr
    call PrintCRLF

    xor eax, eax
    jmp PN_End

PN_PadFrac:
    cmp edi, 3
    jae PN_MakeValue

    mov ebx, 10
    imul edx, ebx

    inc edi
    jmp PN_PadFrac

PN_MakeValue:
    mov ebx, SCALE1000
    imul eax, ebx

    add eax, edx

PN_End:
    pop edi
    pop edx
    pop ecx
    pop ebx
    ret
ParseNumber ENDP


; =========================================================
; Print Step
; =========================================================

PrintStep PROC NEAR
    push eax
    push ebx
    push ecx
    push edx

    mov dx, OFFSET stepPrefix
    call PrintStr

    mov eax, DWORD PTR opLeft
    call PrintScaled

    mov dl, ' '
    call PrintCharDL

    mov dl, opChar
    call PrintCharDL

    mov dl, ' '
    call PrintCharDL

    mov eax, DWORD PTR opRight
    call PrintScaled

    mov dl, ' '
    call PrintCharDL

    mov dl, '='
    call PrintCharDL

    mov dl, ' '
    call PrintCharDL

    mov eax, DWORD PTR opResult
    call PrintScaled

    call PrintCRLF

    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
PrintStep ENDP


; =========================================================
; Print Number
; =========================================================

PrintUInt32 PROC NEAR
    push eax
    push ebx
    push ecx
    push edx
    push di

    cmp eax, 0
    jne PU_Convert

    mov dl, '0'
    call PrintCharDL
    jmp PU_End

PU_Convert:
    mov di, OFFSET digitBuf
    xor cx, cx
    mov ebx, 10

PU_Loop:
    xor edx, edx
    div ebx

    add dl, '0'
    mov [di], dl

    inc di
    inc cx

    cmp eax, 0
    jne PU_Loop

    dec di

PU_Print:
    mov dl, [di]
    call PrintCharDL

    dec di
    loop PU_Print

PU_End:
    pop di
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
PrintUInt32 ENDP


PrintThreeDigits PROC NEAR
    push eax
    push ebx
    push edx

    xor edx, edx
    mov ebx, 100
    div ebx

    add al, '0'
    mov dl, al
    call PrintCharDL

    mov eax, edx
    xor edx, edx

    mov ebx, 10
    div ebx

    add al, '0'
    mov dl, al
    call PrintCharDL

    add dl, '0'
    call PrintCharDL

    pop edx
    pop ebx
    pop eax
    ret
PrintThreeDigits ENDP


PrintScaled PROC NEAR
    push eax
    push ebx
    push edx

    cmp eax, 0
    jge PS_Pos

    mov dl, '-'
    call PrintCharDL

    neg eax

PS_Pos:
    xor edx, edx
    mov ebx, SCALE1000
    div ebx

    push edx

    call PrintUInt32

    mov dl, '.'
    call PrintCharDL

    pop eax
    call PrintThreeDigits

    pop edx
    pop ebx
    pop eax
    ret
PrintScaled ENDP


; =========================================================
; History
; =========================================================

SaveHistory PROC NEAR
    push ax
    push bx
    push cx
    push dx

    cmp exprLen, 0
    je SH_End

    mov ah, 3Dh
    mov al, 02h
    mov dx, OFFSET histName
    int 21h

    jc SH_Create

    mov bx, ax
    jmp SH_SeekEnd

SH_Create:
    mov ah, 3Ch
    xor cx, cx
    mov dx, OFFSET histName
    int 21h

    jc SH_End

    mov bx, ax

SH_SeekEnd:
    mov ax, 4202h
    xor cx, cx
    xor dx, dx
    int 21h

    mov ah, 40h
    mov bx, bx
    mov cx, exprLen
    mov dx, OFFSET exprBuf
    int 21h

    mov ah, 40h
    mov cx, 2
    mov dx, OFFSET crlfRaw
    int 21h

    mov ah, 3Eh
    int 21h

SH_End:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
SaveHistory ENDP


ReadHistory PROC NEAR
    push ax
    push bx
    push cx
    push dx
    push si

    mov dx, OFFSET histTitle
    call PrintStr

    mov ah, 3Dh
    mov al, 00h
    mov dx, OFFSET histName
    int 21h

    jc RH_NoFile

    mov bx, ax
    xor si, si

RH_ReadLoop:
    mov ah, 3Fh
    mov cx, 1
    mov dx, OFFSET fileChar
    int 21h

    jc RH_Close

    cmp ax, 0
    je RH_Close

    mov dl, fileChar
    call PrintCharDL

    cmp fileChar, 10
    jne RH_ReadLoop

    inc si

    cmp si, 10
    jb RH_ReadLoop

    xor si, si

    mov dx, OFFSET pageMsg
    call PrintStr

    mov ah, 00h
    int 16h

    call PrintCRLF

    jmp RH_ReadLoop

RH_Close:
    mov ah, 3Eh
    int 21h
    jmp RH_End

RH_NoFile:
    mov dx, OFFSET noHistMsg
    call PrintStr

RH_End:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ReadHistory ENDP


ClearHistory PROC NEAR
    push ax
    push bx
    push cx
    push dx

    mov ah, 3Ch
    xor cx, cx
    mov dx, OFFSET histName
    int 21h

    jc CH_Fail

    mov bx, ax
    mov ah, 3Eh
    int 21h

    mov lastLen, 0
    mov BYTE PTR lastExpr, 0

    mov dx, OFFSET clearOkMsg
    call PrintStr

    jmp CH_End

CH_Fail:
    mov dx, OFFSET clearFailMsg
    call PrintStr

CH_End:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ClearHistory ENDP


CopyExprToLast PROC NEAR
    push ax
    push cx
    push si
    push di

    mov si, OFFSET exprBuf
    mov di, OFFSET lastExpr
    xor cx, cx

CEL_Loop:
    mov al, [si]
    mov [di], al

    cmp al, 0
    je CEL_End

    inc si
    inc di
    inc cx

    jmp CEL_Loop

CEL_End:
    mov lastLen, cx

    pop di
    pop si
    pop cx
    pop ax
    ret
CopyExprToLast ENDP


LoadLastHistory PROC NEAR
    push ax
    push bx
    push cx
    push dx
    push di

    mov ah, 3Dh
    mov al, 00h
    mov dx, OFFSET histName
    int 21h

    jc LLH_End

    mov bx, ax
    mov tempLen, 0

LLH_ReadLoop:
    mov ah, 3Fh
    mov cx, 1
    mov dx, OFFSET fileChar
    int 21h

    jc LLH_Close

    cmp ax, 0
    je LLH_EOF

    mov al, fileChar

    cmp al, 13
    je LLH_ReadLoop

    cmp al, 10
    je LLH_LineEnd

    mov di, tempLen

    cmp di, MAXLEN-1
    jae LLH_ReadLoop

    mov tempLine[di], al
    inc di
    mov tempLen, di

    jmp LLH_ReadLoop

LLH_LineEnd:
    cmp tempLen, 0
    je LLH_ClearTemp

    mov di, tempLen
    mov BYTE PTR tempLine[di], 0

    call CopyTempToLast

LLH_ClearTemp:
    mov tempLen, 0
    jmp LLH_ReadLoop

LLH_EOF:
    cmp tempLen, 0
    je LLH_Close

    mov di, tempLen
    mov BYTE PTR tempLine[di], 0

    call CopyTempToLast

LLH_Close:
    mov ah, 3Eh
    int 21h

LLH_End:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
LoadLastHistory ENDP


CopyTempToLast PROC NEAR
    push ax
    push cx
    push si
    push di

    mov si, OFFSET tempLine
    mov di, OFFSET lastExpr
    xor cx, cx

CTL_Loop:
    mov al, [si]
    mov [di], al

    cmp al, 0
    je CTL_End

    inc si
    inc di
    inc cx

    jmp CTL_Loop

CTL_End:
    mov lastLen, cx

    pop di
    pop si
    pop cx
    pop ax
    ret
CopyTempToLast ENDP


; =========================================================
; Bonus: choose two history expressions and multiply
; =========================================================

BuildHistoryMulExpression PROC NEAR
    push ax
    push dx

    mov exprLen, 0
    mov BYTE PTR exprBuf, 0

    call LoadFirst10History

    cmp histCount, 2
    jae BHM_Show

    mov dx, OFFSET notEnoughHist
    call PrintStr
    jmp BHM_End

BHM_Show:
    mov dx, OFFSET bonusTitle
    call PrintStr

    call ShowHistTable

    mov dx, OFFSET chooseFirst
    call PrintStr

    mov ah, 01h
    int 21h
    call PrintCRLF

    sub al, '1'
    cmp al, histCount
    jae BHM_Fail

    mov sel1, al

    mov dx, OFFSET chooseSecond
    call PrintStr

    mov ah, 01h
    int 21h
    call PrintCRLF

    sub al, '1'
    cmp al, histCount
    jae BHM_Fail

    mov sel2, al

    call BuildMulExprFromSelections
    jmp BHM_End

BHM_Fail:
    mov dx, OFFSET bonusFailMsg
    call PrintStr
    mov exprLen, 0
    mov BYTE PTR exprBuf, 0

BHM_End:
    pop dx
    pop ax
    ret
BuildHistoryMulExpression ENDP


LoadFirst10History PROC NEAR
    push ax
    push bx
    push cx
    push dx
    push di

    mov histCount, 0
    mov tempLen, 0

    mov ah, 3Dh
    mov al, 00h
    mov dx, OFFSET histName
    int 21h

    jc LFH_End

    mov bx, ax

LFH_ReadLoop:
    mov ah, 3Fh
    mov cx, 1
    mov dx, OFFSET fileChar
    int 21h

    jc LFH_Close

    cmp ax, 0
    je LFH_EOF

    mov al, fileChar

    cmp al, 13
    je LFH_ReadLoop

    cmp al, 10
    je LFH_LineEnd

    mov di, tempLen

    cmp di, MAXLEN-1
    jae LFH_ReadLoop

    mov tempLine[di], al
    inc di
    mov tempLen, di

    jmp LFH_ReadLoop

LFH_LineEnd:
    call StoreTempLineToTable
    mov tempLen, 0
    jmp LFH_ReadLoop

LFH_EOF:
    cmp tempLen, 0
    je LFH_Close

    call StoreTempLineToTable

LFH_Close:
    mov ah, 3Eh
    int 21h

LFH_End:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
LoadFirst10History ENDP


StoreTempLineToTable PROC NEAR
    push ax
    push cx
    push si
    push di

    cmp histCount, 10
    jae STT_End

    cmp tempLen, 0
    je STT_End

    mov di, tempLen
    mov BYTE PTR tempLine[di], 0

    xor ax, ax
    mov al, histCount
    mov cx, MAXLEN
    mul cx

    mov di, OFFSET histTable
    add di, ax

    mov si, OFFSET tempLine

STT_Copy:
    mov al, [si]
    mov [di], al

    cmp al, 0
    je STT_Done

    inc si
    inc di
    jmp STT_Copy

STT_Done:
    inc histCount

STT_End:
    pop di
    pop si
    pop cx
    pop ax
    ret
StoreTempLineToTable ENDP


ShowHistTable PROC NEAR
    push ax
    push bx
    push cx
    push dx

    xor bx, bx

SHT_Loop:
    cmp bl, histCount
    jae SHT_End

    mov dl, bl
    add dl, '1'
    call PrintCharDL

    mov dl, '.'
    call PrintCharDL

    mov dl, ' '
    call PrintCharDL

    xor ax, ax
    mov al, bl
    mov cx, MAXLEN
    mul cx

    mov dx, OFFSET histTable
    add dx, ax

    call PrintZ
    call PrintCRLF

    inc bl
    jmp SHT_Loop

SHT_End:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ShowHistTable ENDP


BuildMulExprFromSelections PROC NEAR
    push ax
    push bx
    push cx
    push dx

    mov di, OFFSET exprBuf

    mov BYTE PTR [di], '('
    inc di

    mov al, sel1
    call CopyHistExprToDI

    mov BYTE PTR [di], ')'
    inc di

    mov BYTE PTR [di], '*'
    inc di

    mov BYTE PTR [di], '('
    inc di

    mov al, sel2
    call CopyHistExprToDI

    mov BYTE PTR [di], ')'
    inc di

    mov BYTE PTR [di], 0

    mov ax, di
    sub ax, OFFSET exprBuf
    mov exprLen, ax

    pop dx
    pop cx
    pop bx
    pop ax
    ret
BuildMulExprFromSelections ENDP


CopyHistExprToDI PROC NEAR
    push ax
    push bx
    push cx
    push si

    xor ah, ah
    mov cx, MAXLEN
    mul cx

    mov si, OFFSET histTable
    add si, ax

CHD_Copy:
    mov al, [si]

    cmp al, 0
    je CHD_End

    mov [di], al

    inc si
    inc di

    jmp CHD_Copy

CHD_End:
    pop si
    pop cx
    pop bx
    pop ax
    ret
CopyHistExprToDI ENDP


END start