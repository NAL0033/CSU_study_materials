        .MODEL  SMALL
        .STACK  200H

MAXEXPR EQU   120
MAXHIST EQU   50
SCALE   EQU   100
PGLEN   EQU   10

        .DATA

; ===== Menu =====
mt1     DB      13,10
        DB      '+========================================+',13,10
        DB      '|       CALCULATOR PRO v3.0             |',13,10
        DB      '+========================================+',13,10
        DB      '|  1. Calculate                         |',13,10
        DB      '|  2. Read History                      |',13,10
        DB      '|  3. Clear History                     |',13,10
        DB      '|  4. Exit                              |',13,10
        DB      '+========================================+',13,10
        DB      '  Select (1-4): $'

prmpt   DB      13,10
        DB      '+----------------------------------------+',13,10
        DB      '  Enter expression:',13,10
        DB      '  e.g. (3.2+4.5)*(5.1-2.0)/3.0',13,10
        DB      '  UP=recall last  BKSP=delete',13,10
        DB      '+----------------------------------------+',13,10
        DB      '> $'

; ===== Messages =====
sTitle  DB      13,10,'--- Solution steps ---',13,10,'$'
rMsg    DB      13,10,'>>> Result = $'
byeMsg  DB      13,10,'  Goodbye!',13,10,'$'
saveOk  DB      '[OK] Saved to HISTORY.TXT',13,10,'$'

eSyntax DB      13,10,'[ERROR] Syntax error.$'
eOvf    DB      13,10,'[ERROR] Overflow.$'
eDiv0   DB      13,10,'[ERROR] Division by zero.$'
eParen  DB      13,10,'[ERROR] Unbalanced parentheses.$'
eBadCh  DB      13,10,'[ERROR] Invalid character.$'
eEmpty  DB      13,10,'[ERROR] Empty expression.$'

hTitle  DB      13,10,'======= HISTORY (Page $'
hTitle2 DB      ') =======',13,10,'$'
hNone   DB      13,10,'[INFO] No history records.$'
hClear  DB      13,10,'[OK] History cleared.$'
hFileE  DB      13,10,'[ERROR] Cannot access HISTORY.TXT.$'
hPage   DB      13,10,'-- ENTER=next, Q=quit --$'
hMulAsk DB      13,10,'Multiply two history records? (Y/N): $'
hAsk1   DB      '  First  record #: $'
hAsk2   DB      '  Second record #: $'
hBadSel DB      13,10,'[ERROR] Invalid record number.$'
hNeed2  DB      13,10,'[INFO] Need at least 2 records.$'
hCompo  DB      13,10,'  Composed: $'

; ===== File name =====
fn      DB      'HISTORY.TXT',0

; ===== Buffers =====
chBuf   DB      8, 0, 9 DUP(0)
inBuf   DB      MAXEXPR, 0, MAXEXPR+1 DUP(0)
llen    DB      0
lexpr   DB      MAXEXPR+1 DUP(0)

; ===== Parser state =====
eptr    DW      0
perr    DB      0          ; 0=ok 1=syntax 2=overflow 3=div0 4=paren 5=badchar
sgnFlg  DB      0
dSeen   DB      0
fcnt    DB      0
intP    DW      0
fracP   DW      0

tL      DW      0
tR      DW      0
tRes    DW      0
res     DW      0
sOp     DB      0
sNum    DW      0

; ===== Display =====
rs      DB      20 DUP(0)
rlen    DW      0
fHnd    DW      0
rc      DB      0
sWord   DW      SCALE

; ===== History pagination =====
anyB    DB      0
pNum    DW      1
pLines  DW      0
lNo     DW      0
isLSt   DB      0
quitH   DB      0

; ===== History multiply =====
hCnt    DW      0
cf      DB      0
lhd     DB      0
hbPos   DW      0
hBuf    DB      MAXHIST*MAXEXPR DUP(0)
sel1    DW      0
sel2    DW      0
blen    DW      0
berr    DB      0

; ===== Temp =====
crlf    DB      13,10,'$'
crRaw   DB      13,10
eText   DB      ' = '
dotSp   DB      '. $'

        .CODE

MAIN    PROC
        MOV     AX, @DATA
        MOV     DS, AX

mloop:  LEA     DX, mt1
        CALL    PSTR
        LEA     DX, chBuf
        CALL    RLINE

        MOV     AL, [chBuf+2]
        CMP     AL, '1'
        JE      dcalc
        CMP     AL, '2'
        JE      dhist
        CMP     AL, '3'
        JE      dclr
        CMP     AL, '4'
        JE      dexit
        LEA     DX, crlf
        CALL    PSTR
        JMP     mloop

dcalc:  CALL    DOCALC
        JMP     mloop
dhist:  CALL    DOHIST
        JMP     mloop
dclr:   CALL    DOCLEAR
        JMP     mloop
dexit:  LEA     DX, byeMsg
        CALL    PSTR
        MOV     AX, 4C00H
        INT     21H
MAIN    ENDP

; ============================================================
DOCALC  PROC
        PUSH    AX
        PUSH    BX
        PUSH    SI

        LEA     DX, prmpt
        CALL    PSTR
        CALL    RDEXPR

        XOR     AX, AX
        MOV     AL, [inBuf+1]
        CMP     AL, 0
        JNE     dc1
        LEA     DX, eEmpty
        CALL    PSTR
        JMP     dcRet
dc1:    CALL    VALIDATE
        CMP     BYTE PTR [perr], 4
        JE      dcPe
        CMP     BYTE PTR [perr], 5
        JE      dcCe

        MOV     BYTE PTR [perr], 0
        MOV     WORD PTR [sNum], 0
        MOV     SI, OFFSET inBuf+2
        XOR     AX, AX
        MOV     AL, [inBuf+1]
        MOV     BX, OFFSET inBuf+2
        ADD     BX, AX
        MOV     [eptr], BX

        LEA     DX, sTitle
        CALL    PSTR

        CALL    PARSEXPR
        CMP     BYTE PTR [perr], 0
        JNE     dcPe2

        CALL    SKPSP
        CMP     SI, [eptr]
        JNE     dcSyn

        MOV     [res], AX
        LEA     DX, rMsg
        CALL    PSTR
        MOV     AX, [res]
        CALL    PFIX
        CALL    PCRLF

        CALL    SAVEH
        CALL    STLAST
        JMP     dcRet

dcPe:   LEA     DX, eParen
        CALL    PSTR
        JMP     dcRet
dcCe:   LEA     DX, eBadCh
        CALL    PSTR
        JMP     dcRet
dcPe2:  CMP     BYTE PTR [perr], 2
        JNE     dcD0
        LEA     DX, eOvf
        CALL    PSTR
        JMP     dcRet
dcD0:   CMP     BYTE PTR [perr], 3
        JNE     dcSyn
        LEA     DX, eDiv0
        CALL    PSTR
        JMP     dcRet
dcSyn:  LEA     DX, eSyntax
        CALL    PSTR
dcRet:  POP     SI
        POP     BX
        POP     AX
        RET
DOCALC  ENDP

; ============================================================
VALIDATE PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    SI
        MOV     BYTE PTR [perr], 0
        XOR     CX, CX
        XOR     AX, AX
        MOV     AL, [inBuf+1]
        MOV     SI, OFFSET inBuf+2
        MOV     BX, SI
        ADD     BX, AX
vdLoop: CMP     SI, BX
        JAE     vdBal
        MOV     AL, [SI]
        CMP     AL, ' '
        JE      vdNxt
        CMP     AL, '+'
        JE      vdNxt
        CMP     AL, '-'
        JE      vdNxt
        CMP     AL, '*'
        JE      vdNxt
        CMP     AL, '/'
        JE      vdNxt
        CMP     AL, '.'
        JE      vdNxt
        CMP     AL, '('
        JE      vdOp
        CMP     AL, ')'
        JE      vdCl
        CMP     AL, '0'
        JB      vdBad
        CMP     AL, '9'
        JBE     vdNxt
        JMP     vdBad
vdOp:   INC     CX
        JMP     vdNxt
vdCl:   DEC     CX
        JS      vdBadP
        JMP     vdNxt
vdNxt:  INC     SI
        JMP     vdLoop
vdBal:  CMP     CX, 0
        JNE     vdBadP
        JMP     vdDone
vdBadP: MOV     BYTE PTR [perr], 4
        JMP     vdDone
vdBad:  MOV     BYTE PTR [perr], 5
vdDone: POP     SI
        POP     CX
        POP     BX
        POP     AX
        RET
VALIDATE ENDP

; ============================================================
RLINE   PROC
        PUSH    AX
        PUSH    BX
        PUSH    SI
        MOV     AH, 0AH
        INT     21H
        MOV     BX, DX
        XOR     AX, AX
        MOV     AL, [BX+1]
        MOV     SI, AX
        MOV     BYTE PTR [BX+SI+2], 0
        POP     SI
        POP     BX
        POP     AX
        RET
RLINE   ENDP

PSTR    PROC
        MOV     AH, 09H
        INT     21H
        RET
PSTR    ENDP

PCHAR   PROC
        MOV     AH, 02H
        INT     21H
        RET
PCHAR   ENDP

PCRLF   PROC
        PUSH    DX
        LEA     DX, crlf
        CALL    PSTR
        POP     DX
        RET
PCRLF   ENDP

; ============================================================
; Custom input: BACKSPACE + UP arrow recall via INT 16h
RDEXPR  PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        XOR     CX, CX
        MOV     DI, OFFSET inBuf+2
rdLp:   MOV     AH, 00H
        INT     16H
        CMP     AL, 0DH
        JE      rdDon
        CMP     AL, 08H
        JE      rdBksp
        CMP     AL, 00H
        JE      rdExt
        CMP     AL, 0E0H
        JE      rdExt
        CMP     CX, MAXEXPR-1
        JAE     rdLp
        MOV     [DI], AL
        INC     DI
        INC     CX
        MOV     DL, AL
        CALL    PCHAR
        JMP     rdLp
rdBksp: CMP     CX, 0
        JE      rdLp
        DEC     CX
        DEC     DI
        MOV     DL, 08H
        CALL    PCHAR
        MOV     DL, ' '
        CALL    PCHAR
        MOV     DL, 08H
        CALL    PCHAR
        JMP     rdLp
rdExt:  CMP     AH, 48H          ; UP arrow
        JNE     rdLp
        CMP     CX, 0
        JNE     rdLp
        CMP     BYTE PTR [llen], 0
        JE      rdLp
        MOV     SI, OFFSET lexpr
rdCpy:  MOV     AL, [SI]
        CMP     AL, 0
        JE      rdCpyD
        CMP     CX, MAXEXPR-1
        JAE     rdCpyD
        MOV     [DI], AL
        INC     DI
        INC     SI
        INC     CX
        MOV     DL, AL
        CALL    PCHAR
        JMP     rdCpy
rdCpyD: JMP     rdLp
rdDon:  MOV     [inBuf+1], CL
        MOV     BYTE PTR [DI], 0
        CALL    PCRLF
        POP     DI
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
RDEXPR  ENDP

STLAST  PROC
        PUSH    AX
        PUSH    CX
        PUSH    SI
        PUSH    DI
        XOR     CX, CX
        MOV     CL, [inBuf+1]
        MOV     [llen], CL
        MOV     SI, OFFSET inBuf+2
        MOV     DI, OFFSET lexpr
        CLD
        REP     MOVSB
        MOV     BYTE PTR [DI], 0
        POP     DI
        POP     SI
        POP     CX
        POP     AX
        RET
STLAST  ENDP

; ============================================================
SKPSP   PROC
skLoop: CMP     SI, [eptr]
        JAE     skDone
        CMP     BYTE PTR [SI], ' '
        JNE     skDone
        INC     SI
        JMP     skLoop
skDone: RET
SKPSP   ENDP

; ============================================================
; Expr = Term { (+|-) Term }
PARSEXPR PROC
        CALL    PTERM
        CMP     BYTE PTR [perr], 0
        JNE     peDone
peLoop: CALL    SKPSP
        CMP     SI, [eptr]
        JAE     peDone
        MOV     DL, [SI]
        CMP     DL, '+'
        JE      peOp
        CMP     DL, '-'
        JE      peOp
        JMP     peDone
peOp:   INC     SI
        PUSH    AX
        PUSH    DX
        CALL    PTERM
        POP     DX
        POP     BX
        CMP     BYTE PTR [perr], 0
        JNE     peDone
        MOV     [tL], BX
        MOV     [tR], AX
        MOV     [sOp], DL
        CMP     DL, '+'
        JE      peAdd
        MOV     AX, BX
        SUB     AX, [tR]
        JO      peOvf
        JMP     peSto
peAdd:  MOV     AX, BX
        ADD     AX, [tR]
        JO      peOvf
peSto:  MOV     [tRes], AX
        CALL    PSTEP
        MOV     AX, [tRes]
        JMP     peLoop
peOvf:  MOV     BYTE PTR [perr], 2
peDone: RET
PARSEXPR ENDP

; ============================================================
; Term = Factor { (*|/) Factor }
; Fixed-point: all values ×100
;   Mul: (A*100)*(B*100)/100 = A*B*100
;   Div: (A*100)*100/(B*100) = A/B*100
PTERM   PROC
        CALL    PFACTOR
        CMP     BYTE PTR [perr], 0
        JNE     ptDone
ptLoop: CALL    SKPSP
        CMP     SI, [eptr]
        JAE     ptDone
        MOV     DL, [SI]
        CMP     DL, '*'
        JE      ptOp
        CMP     DL, '/'
        JE      ptOp
        JMP     ptDone
ptOp:   INC     SI
        PUSH    AX
        PUSH    DX
        CALL    PFACTOR
        POP     DX
        POP     BX
        CMP     BYTE PTR [perr], 0
        JNE     ptDone
        MOV     [tL], BX
        MOV     [tR], AX
        MOV     [sOp], DL
        CMP     DL, '*'
        JE      ptMul

        ; ---- Division ----
        CMP     WORD PTR [tR], 0
        JE      ptD0
        MOV     AX, [tL]
        CWD
        MOV     BX, SCALE
        IMUL    BX
        IDIV    WORD PTR [tR]
        JMP     ptSto

ptMul:  ; ---- Multiplication ----
        MOV     AX, [tL]
        IMUL    WORD PTR [tR]      ; DX:AX = L * R (signed 32-bit)
        ; |DX:AX| / 100 must fit in signed 16-bit [-32768,32767]
        ; Safe range: |DX:AX| <= 3276700 = 0x31FF9C
        ; Positive check:
        CMP     DX, 0
        JL      ptNeg              ; DX negative
        CMP     DX, 31H            ; DX == 0x31 = 49
        JB      ptDiv              ; DX < 49, safe
        JA      ptOvf              ; DX > 49, unsafe
        CMP     AX, 0FF9CH         ; DX == 49, check low word
        JBE     ptDiv
        JMP     ptOvf
ptNeg:  ; negative: value in [0xFFCE0000, 0xFFFFFFFF]
        CMP     DX, 0FFCEH         ; DX == -50
        JG      ptDiv              ; DX > -50 (i.e. -49..-1), safe
        JL      ptOvf              ; DX < -50, unsafe
        CMP     AX, 0064H          ; DX == -50, AX must be >= 100
        JAE     ptDiv
        JMP     ptOvf
ptDiv:  IDIV    WORD PTR [sWord]
        JMP     ptSto

ptD0:   MOV     BYTE PTR [perr], 3
        JMP     ptDone
ptOvf:  MOV     BYTE PTR [perr], 2
        JMP     ptDone
ptSto:  MOV     [tRes], AX
        CALL    PSTEP
        MOV     AX, [tRes]
        JMP     ptLoop
ptDone: RET
PTERM   ENDP

; ============================================================
; Factor = number | ( Expr ) | +Factor | -Factor
PFACTOR PROC
        CALL    SKPSP
        MOV     BYTE PTR [sgnFlg], 0
pfSgn:  CALL    SKPSP
        CMP     SI, [eptr]
        JAE     pfErr
        MOV     AL, [SI]
        CMP     AL, '+'
        JE      pfPls
        CMP     AL, '-'
        JE      pfMns
        JMP     pfBody
pfPls:  INC     SI
        JMP     pfSgn
pfMns:  XOR     BYTE PTR [sgnFlg], 1
        INC     SI
        JMP     pfSgn
pfBody: CMP     BYTE PTR [SI], '('
        JE      pfParen
        CALL    PNUM
        CMP     BYTE PTR [perr], 0
        JNE     pfDone
        CMP     BYTE PTR [sgnFlg], 0
        JE      pfDone
        NEG     AX
        JMP     pfDone
pfParen:INC     SI
        CALL    PARSEXPR
        CMP     BYTE PTR [perr], 0
        JNE     pfDone
        CALL    SKPSP
        CMP     SI, [eptr]
        JAE     pfErr
        CMP     BYTE PTR [SI], ')'
        JNE     pfErr
        INC     SI
        CMP     BYTE PTR [sgnFlg], 0
        JE      pfDone
        NEG     AX
        JMP     pfDone
pfErr:  MOV     BYTE PTR [perr], 1
pfDone: RET
PFACTOR ENDP

; ============================================================
; ParseNumber -> [0-9]+ [ '.' {0-2} [0-9] ]
; Returns AX = value * 100
PNUM    PROC
        MOV     WORD PTR [intP], 0
        MOV     WORD PTR [fracP], 0
        MOV     BYTE PTR [fcnt], 0
        MOV     BYTE PTR [dSeen], 0

pnIntL: CMP     SI, [eptr]
        JAE     pnAfI
        MOV     AL, [SI]
        CMP     AL, '0'
        JB      pnAfI
        CMP     AL, '9'
        JA      pnAfI
        MOV     BYTE PTR [dSeen], 1
        SUB     AL, '0'
        XOR     AH, AH
        PUSH    AX
        MOV     AX, [intP]
        MOV     BX, 10
        MUL     BX
        CMP     DX, 0
        JNE     pnErr
        POP     BX
        ADD     AX, BX
        JO      pnErr
        MOV     [intP], AX
        INC     SI
        JMP     pnIntL

pnAfI:  CMP     SI, [eptr]
        JAE     pnMake
        CMP     BYTE PTR [SI], '.'
        JNE     pnMake
        INC     SI

pnFrac: CMP     SI, [eptr]
        JAE     pnMake
        MOV     AL, [SI]
        CMP     AL, '0'
        JB      pnMake
        CMP     AL, '9'
        JA      pnMake
        MOV     BYTE PTR [dSeen], 1
        SUB     AL, '0'
        XOR     AH, AH
        CMP     BYTE PTR [fcnt], 0
        JE      pnF1
        CMP     BYTE PTR [fcnt], 1
        JE      pnF2
        JMP     pnFSk
pnF1:   MOV     BL, 10
        MUL     BL
        ADD     [fracP], AX
        INC     BYTE PTR [fcnt]
        JMP     pnFSk
pnF2:   ADD     [fracP], AX
        INC     BYTE PTR [fcnt]
pnFSk:  INC     SI
        JMP     pnFrac

pnMake: CMP     BYTE PTR [dSeen], 0
        JE      pnErr
        MOV     AX, [intP]
        MOV     BX, SCALE
        MUL     BX
        CMP     DX, 0
        JNE     pnErr
        ADD     AX, [fracP]
        RET
pnErr:  MOV     BYTE PTR [perr], 1
        RET
PNUM    ENDP

; ============================================================
; Print step: "Step 1: L op R = RES"
PSTEP   PROC
        PUSH    AX
        PUSH    DX
        INC     WORD PTR [sNum]

        MOV     DL, 'S'
        CALL    PCHAR
        MOV     DL, 't'
        CALL    PCHAR
        MOV     DL, 'e'
        CALL    PCHAR
        MOV     DL, 'p'
        CALL    PCHAR
        MOV     DL, ' '
        CALL    PCHAR
        MOV     AX, [sNum]
        CALL    PUINT
        MOV     DL, ':'
        CALL    PCHAR
        MOV     DL, ' '
        CALL    PCHAR

        MOV     AX, [tL]
        CALL    PFIX
        MOV     DL, ' '
        CALL    PCHAR
        MOV     DL, [sOp]
        CALL    PCHAR
        MOV     DL, ' '
        CALL    PCHAR
        MOV     AX, [tR]
        CALL    PFIX
        MOV     DL, ' '
        CALL    PCHAR
        MOV     DL, '='
        CALL    PCHAR
        MOV     DL, ' '
        CALL    PCHAR
        MOV     AX, [tRes]
        CALL    PFIX
        CALL    PCRLF
        POP     DX
        POP     AX
        RET
PSTEP   ENDP

; ============================================================
; Print AX/100 to screen (always 2 decimal places)
PFIX    PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        CMP     AX, 0
        JGE     pfPos
        MOV     DL, '-'
        CALL    PCHAR
        NEG     AX
pfPos:  XOR     DX, DX
        MOV     BX, SCALE
        DIV     BX
        PUSH    DX
        CALL    PUINT
        MOV     DL, '.'
        CALL    PCHAR
        POP     AX
        CALL    P2DIG
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
PFIX    ENDP

PUINT   PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        CMP     AX, 0
        JNE     puNz
        MOV     DL, '0'
        CALL    PCHAR
        JMP     puDone
puNz:   XOR     CX, CX
        MOV     BX, 10
puDiv:  XOR     DX, DX
        DIV     BX
        PUSH    DX
        INC     CX
        CMP     AX, 0
        JNE     puDiv
puPop:  POP     DX
        ADD     DL, '0'
        CALL    PCHAR
        LOOP    puPop
puDone: POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
PUINT   ENDP

P2DIG   PROC
        PUSH    AX
        PUSH    BX
        PUSH    DX
        XOR     AH, AH
        MOV     BL, 10
        DIV     BL
        MOV     DH, AH
        ADD     AL, '0'
        MOV     DL, AL
        CALL    PCHAR
        MOV     DL, DH
        ADD     DL, '0'
        CALL    PCHAR
        POP     DX
        POP     BX
        POP     AX
        RET
P2DIG   ENDP

; ============================================================
SAVEH   PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX

        CALL    MKRS

        MOV     AX, 3D02H
        LEA     DX, fn
        INT     21H
        JC      shCr
        MOV     [fHnd], AX
        JMP     shSeek
shCr:   MOV     AH, 3CH
        MOV     CX, 0
        LEA     DX, fn
        INT     21H
        JC      shErr
        MOV     [fHnd], AX

shSeek: MOV     BX, [fHnd]
        MOV     AX, 4202H
        XOR     CX, CX
        XOR     DX, DX
        INT     21H

        MOV     BX, [fHnd]
        LEA     DX, inBuf+2
        XOR     CX, CX
        MOV     CL, [inBuf+1]
        MOV     AH, 40H
        INT     21H

        MOV     BX, [fHnd]
        LEA     DX, eText
        MOV     CX, 3
        MOV     AH, 40H
        INT     21H

        MOV     BX, [fHnd]
        LEA     DX, rs
        MOV     CX, [rlen]
        MOV     AH, 40H
        INT     21H

        MOV     BX, [fHnd]
        LEA     DX, crRaw
        MOV     CX, 2
        MOV     AH, 40H
        INT     21H

        MOV     BX, [fHnd]
        MOV     AH, 3EH
        INT     21H

        LEA     DX, saveOk
        CALL    PSTR
        JMP     shDone
shErr:  LEA     DX, hFileE
        CALL    PSTR
shDone: POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
SAVEH   ENDP

MKRS    PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    DI
        LEA     DI, rs
        MOV     WORD PTR [rlen], 0
        MOV     AX, [res]
        CMP     AX, 0
        JGE     mkPos
        MOV     BYTE PTR [DI], '-'
        INC     DI
        INC     WORD PTR [rlen]
        NEG     AX
mkPos:  XOR     DX, DX
        MOV     BX, SCALE
        DIV     BX
        PUSH    DX
        CALL    APUINT
        MOV     BYTE PTR [DI], '.'
        INC     DI
        INC     WORD PTR [rlen]
        POP     AX
        CALL    AP2DIG
        MOV     BYTE PTR [DI], 0
        POP     DI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
MKRS    ENDP

APUINT  PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        CMP     AX, 0
        JNE     auNz
        MOV     BYTE PTR [DI], '0'
        INC     DI
        INC     WORD PTR [rlen]
        JMP     auDone
auNz:   XOR     CX, CX
        MOV     BX, 10
auDiv:  XOR     DX, DX
        DIV     BX
        PUSH    DX
        INC     CX
        CMP     AX, 0
        JNE     auDiv
auPop:  POP     DX
        ADD     DL, '0'
        MOV     [DI], DL
        INC     DI
        INC     WORD PTR [rlen]
        LOOP    auPop
auDone: POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
APUINT  ENDP

AP2DIG  PROC
        PUSH    AX
        PUSH    BX
        PUSH    DX
        XOR     AH, AH
        MOV     BL, 10
        DIV     BL
        MOV     DH, AH
        ADD     AL, '0'
        MOV     [DI], AL
        INC     DI
        INC     WORD PTR [rlen]
        MOV     AL, DH
        ADD     AL, '0'
        MOV     [DI], AL
        INC     DI
        INC     WORD PTR [rlen]
        POP     DX
        POP     BX
        POP     AX
        RET
AP2DIG  ENDP

; ============================================================
DOHIST  PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX

        CALL    PCRLF
        MOV     WORD PTR [lNo], 1
        MOV     WORD PTR [pLines], 0
        MOV     WORD PTR [pNum], 1
        MOV     BYTE PTR [isLSt], 1
        MOV     BYTE PTR [anyB], 0
        MOV     BYTE PTR [quitH], 0

        MOV     AX, 3D00H
        LEA     DX, fn
        INT     21H
        JC      dhNoF
        MOV     [fHnd], AX

        LEA     DX, hTitle
        CALL    PSTR
        MOV     AX, [pNum]
        CALL    PUINT
        LEA     DX, hTitle2
        CALL    PSTR

dhRd:   MOV     BX, [fHnd]
        LEA     DX, rc
        MOV     CX, 1
        MOV     AH, 3FH
        INT     21H
        JC      dhClose
        CMP     AX, 0
        JE      dhEOF
        MOV     BYTE PTR [anyB], 1
        MOV     AL, [rc]
        CMP     AL, 10
        JE      dhRd
        CMP     AL, 13
        JE      dhNL

        CMP     BYTE PTR [isLSt], 0
        JE      dhPr
        PUSH    AX
        PUSH    DX
        MOV     AX, [lNo]
        CALL    PUINT
        LEA     DX, dotSp
        CALL    PSTR
        POP     DX
        POP     AX
        MOV     BYTE PTR [isLSt], 0

dhPr:   MOV     DL, [rc]
        CALL    PCHAR
        JMP     dhRd

dhNL:   CALL    PCRLF
        INC     WORD PTR [lNo]
        INC     WORD PTR [pLines]
        MOV     BYTE PTR [isLSt], 1
        CMP     WORD PTR [pLines], PGLEN
        JB      dhRd

        MOV     WORD PTR [pLines], 0
        INC     WORD PTR [pNum]
        LEA     DX, hPage
        CALL    PSTR
        MOV     AH, 08H
        INT     21H
        CMP     AL, 'q'
        JE      dhQ
        CMP     AL, 'Q'
        JE      dhQ
        CALL    PCRLF
        LEA     DX, hTitle
        CALL    PSTR
        MOV     AX, [pNum]
        CALL    PUINT
        LEA     DX, hTitle2
        CALL    PSTR
        JMP     dhRd

dhQ:    MOV     BYTE PTR [quitH], 1
        JMP     dhClose

dhEOF:  CMP     BYTE PTR [anyB], 0
        JNE     dhClose
        LEA     DX, hNone
        CALL    PSTR

dhClose:MOV     BX, [fHnd]
        MOV     AH, 3EH
        INT     21H

        CMP     BYTE PTR [anyB], 0
        JE      dhDone
        CMP     BYTE PTR [quitH], 1
        JE      dhDone

        CALL    ASKMUL

dhDone: CALL    PCRLF
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET

dhNoF:  LEA     DX, hNone
        CALL    PSTR
        JMP     dhDone
DOHIST  ENDP

; ============================================================
ASKMUL  PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI

        CALL    LDHIST
        CMP     WORD PTR [hCnt], 2
        JAE     amOk
        LEA     DX, hNeed2
        CALL    PSTR
        JMP     amDone

amOk:   LEA     DX, hMulAsk
        CALL    PSTR
        MOV     AH, 01H
        INT     21H
        CALL    PCRLF
        CMP     AL, 'Y'
        JE      amYes
        CMP     AL, 'y'
        JNE     amDone

amYes:  LEA     DX, hAsk1
        CALL    PSTR
        LEA     DX, chBuf
        CALL    RLINE
        CALL    BTONUM
        MOV     [sel1], AX

        LEA     DX, hAsk2
        CALL    PSTR
        LEA     DX, chBuf
        CALL    RLINE
        CALL    BTONUM
        MOV     [sel2], AX

        MOV     AX, [sel1]
        CMP     AX, 1
        JB      amBad
        CMP     AX, [hCnt]
        JA      amBad
        MOV     AX, [sel2]
        CMP     AX, 1
        JB      amBad
        CMP     AX, [hCnt]
        JA      amBad

        CALL    COMPOSE
        CMP     BYTE PTR [berr], 0
        JNE     amBad

        LEA     DX, hCompo
        CALL    PSTR
        XOR     CX, CX
        MOV     CL, [inBuf+1]
        MOV     SI, OFFSET inBuf+2
amShow: JCXZ    amShD
        MOV     DL, [SI]
        CALL    PCHAR
        INC     SI
        DEC     CX
        JMP     amShow
amShD:  CALL    PCRLF

        ; evaluate composed expression
        MOV     BYTE PTR [perr], 0
        MOV     WORD PTR [sNum], 0
        MOV     SI, OFFSET inBuf+2
        XOR     AX, AX
        MOV     AL, [inBuf+1]
        MOV     BX, OFFSET inBuf+2
        ADD     BX, AX
        MOV     [eptr], BX
        LEA     DX, sTitle
        CALL    PSTR
        CALL    PARSEXPR
        CMP     BYTE PTR [perr], 0
        JNE     amPerr
        CALL    SKPSP
        CMP     SI, [eptr]
        JNE     amPerr
        MOV     [res], AX
        LEA     DX, rMsg
        CALL    PSTR
        MOV     AX, [res]
        CALL    PFIX
        CALL    PCRLF
        CALL    SAVEH
        JMP     amDone

amPerr: LEA     DX, eSyntax
        CALL    PSTR
        JMP     amDone

amBad:  LEA     DX, hBadSel
        CALL    PSTR

amDone: POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
ASKMUL  ENDP

; ============================================================
BTONUM  PROC
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        XOR     AX, AX
        XOR     CX, CX
        MOV     CL, [chBuf+1]
        MOV     SI, OFFSET chBuf+2
bnLoop: JCXZ    bnDone
        MOV     DL, [SI]
        CMP     DL, '0'
        JB      bnNxt
        CMP     DL, '9'
        JA      bnNxt
        SUB     DL, '0'
        PUSH    DX
        MOV     BX, 10
        MUL     BX
        POP     DX
        XOR     DH, DH
        ADD     AX, DX
bnNxt:  INC     SI
        DEC     CX
        JMP     bnLoop
bnDone: POP     SI
        POP     DX
        POP     CX
        POP     BX
        RET
BTONUM  ENDP

; ============================================================
LDHIST  PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        MOV     WORD PTR [hCnt], 0
        MOV     AX, 3D00H
        LEA     DX, fn
        INT     21H
        JC      lhDone
        MOV     [fHnd], AX

lhNext: CMP     WORD PTR [hCnt], MAXHIST
        JAE     lhClose
        MOV     AX, [hCnt]
        MOV     BX, MAXEXPR
        MUL     BX
        MOV     DI, OFFSET hBuf
        ADD     DI, AX
        MOV     WORD PTR [hbPos], 0
        MOV     BYTE PTR [cf], 1
        MOV     BYTE PTR [lhd], 0

lhRd:   MOV     BX, [fHnd]
        LEA     DX, rc
        MOV     CX, 1
        MOV     AH, 3FH
        INT     21H
        JC      lhClose
        CMP     AX, 0
        JE      lhEOF
        MOV     AL, [rc]
        CMP     AL, 10
        JE      lhRd
        CMP     AL, 13
        JE      lhFinL
        MOV     BYTE PTR [lhd], 1
        CMP     BYTE PTR [cf], 0
        JE      lhRd
        CMP     AL, '='
        JNE     lhCopy
        MOV     BYTE PTR [cf], 0
lhTrim: MOV     BX, [hbPos]
        CMP     BX, 0
        JE      lhTrimD
        MOV     SI, DI
        ADD     SI, BX
        DEC     SI
        CMP     BYTE PTR [SI], ' '
        JNE     lhTrimD
        DEC     WORD PTR [hbPos]
        JMP     lhTrim
lhTrimD:MOV     BX, [hbPos]
        MOV     BYTE PTR [DI+BX], 0
        JMP     lhRd
lhCopy: CMP     WORD PTR [hbPos], MAXEXPR-1
        JAE     lhRd
        MOV     [DI], AL
        INC     DI
        INC     WORD PTR [hbPos]
        JMP     lhRd

lhFinL: CMP     BYTE PTR [lhd], 0
        JE      lhNext
        MOV     BX, [hbPos]
        MOV     BYTE PTR [DI+BX], 0
        INC     WORD PTR [hCnt]
        JMP     lhNext

lhEOF:  CMP     BYTE PTR [lhd], 0
        JE      lhClose
        MOV     BX, [hbPos]
        MOV     BYTE PTR [DI+BX], 0
        INC     WORD PTR [hCnt]

lhClose:MOV     BX, [fHnd]
        MOV     AH, 3EH
        INT     21H
lhDone: POP     DI
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
LDHIST  ENDP

; ============================================================
COMPOSE PROC
        PUSH    AX
        PUSH    BX
        PUSH    SI
        PUSH    DI
        MOV     BYTE PTR [berr], 0
        MOV     WORD PTR [blen], 0
        MOV     DI, OFFSET inBuf+2

        MOV     AL, '('
        CALL    APCHAR
        MOV     AX, [sel1]
        CALL    GETHP
        CALL    APZSTR
        MOV     AL, ')'
        CALL    APCHAR
        MOV     AL, '*'
        CALL    APCHAR
        MOV     AL, '('
        CALL    APCHAR
        MOV     AX, [sel2]
        CALL    GETHP
        CALL    APZSTR
        MOV     AL, ')'
        CALL    APCHAR

        MOV     AX, [blen]
        MOV     [inBuf+1], AL
        MOV     BYTE PTR [DI], 0
        POP     DI
        POP     SI
        POP     BX
        POP     AX
        RET
COMPOSE ENDP

GETHP   PROC
        DEC     AX
        MOV     BX, MAXEXPR
        MUL     BX
        MOV     SI, OFFSET hBuf
        ADD     SI, AX
        RET
GETHP   ENDP

APCHAR  PROC
        CMP     WORD PTR [blen], MAXEXPR-2
        JAE     acErr
        MOV     [DI], AL
        INC     DI
        INC     WORD PTR [blen]
        RET
acErr:  MOV     BYTE PTR [berr], 1
        RET
APCHAR  ENDP

APZSTR  PROC
azLoop: CMP     BYTE PTR [berr], 0
        JNE     azDone
        MOV     AL, [SI]
        CMP     AL, 0
        JE      azDone
        CALL    APCHAR
        INC     SI
        JMP     azLoop
azDone: RET
APZSTR  ENDP

; ============================================================
DOCLEAR PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        MOV     AH, 3CH
        MOV     CX, 0
        LEA     DX, fn
        INT     21H
        JC      clErr
        MOV     BX, AX
        MOV     AH, 3EH
        INT     21H
        LEA     DX, hClear
        CALL    PSTR
        JMP     clDone
clErr:  LEA     DX, hFileE
        CALL    PSTR
clDone: POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
DOCLEAR ENDP

        END     MAIN
