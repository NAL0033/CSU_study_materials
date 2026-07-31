.MODEL SMALL
.STACK 200H

.DATA

; ================= 菜单 =================
menu DB 13,10,'====== CALCULATOR V3 (90+ VERSION) ======$'
m1   DB 13,10,'1. Calculate$'
m2   DB 13,10,'2. History$'
m3   DB 13,10,'3. Clear History$'
m4   DB 13,10,'4. Exit$'
sel  DB 13,10,'Choose: $'

; ================= 输入 =================
expr DB 100
     DB 0
     DB 100 DUP('$')

buf DB 100 DUP('$')

; ================= 文件 =================
fileName DB 'HISTORY.TXT',0

; ================= 栈 =================
numStack DW 50 DUP(0)
opStack  DB 50 DUP(0)

numTop DW 0
opTop  DW 0

; ================= 状态 =================
i DW 0
err DB 0
result DW 0

; ================= 临时 =================
a DW 0
b DW 0
op DB 0

.CODE

; ==================================================
MAIN PROC
    MOV AX,@DATA
    MOV DS,AX

MAIN_LOOP:
    CALL SHOW_MENU
    CALL GET_KEY

    CMP AL,'1'
    JE CALC
    CMP AL,'2'
    JE HISTORY
    CMP AL,'3'
    JE CLEAR
    CMP AL,'4'
    JE EXIT

    JMP MAIN_LOOP

; ==================================================
SHOW_MENU PROC
    MOV DX,OFFSET menu
    MOV AH,09H
    INT 21H

    MOV DX,OFFSET m1
    INT 21H

    MOV DX,OFFSET m2
    INT 21H

    MOV DX,OFFSET m3
    INT 21H

    MOV DX,OFFSET m4
    INT 21H

    MOV DX,OFFSET sel
    INT 21H
    RET
SHOW_MENU ENDP

GET_KEY PROC
    MOV AH,01H
    INT 21H
    RET
GET_KEY ENDP

; ==================================================
CALC:
    MOV err,0
    CALL NEWLINE

    MOV DX,OFFSET expr
    MOV AH,0AH
    INT 21H

    CALL INIT_STACKS

    LEA SI,expr+2
    CALL PARSE_EXPR

    CMP err,1
    JE ERROR

    CALL EVAL_STACK

    CMP err,1
    JE ERROR

    CALL PRINT_RESULT
    CALL SAVE_HISTORY

    JMP MAIN_LOOP

ERROR:
    MOV DX,OFFSET menu
    MOV AH,09H
    INT 21H
    JMP MAIN_LOOP

; ==================================================
; 初始化栈
INIT_STACKS PROC
    MOV numTop,0
    MOV opTop,0
    RET
INIT_STACKS ENDP

; ==================================================
; ================= PARSER =================
PARSE_EXPR PROC

NEXT:
    MOV AL,[SI]
    CMP AL,0DH
    JE END_PARSE

    CMP AL,' '
    JE SKIP

    ; 数字
    CMP AL,'0'
    JB CHECK_OP
    CMP AL,'9'
    JA CHECK_OP

    CALL READ_NUMBER
    CALL PUSH_NUM
    JMP NEXT

CHECK_OP:
    CMP AL,'('
    JE PUSH_LEFT

    CMP AL,')'
    JE POP_BRACKET

    CALL HANDLE_OP

SKIP:
    INC SI
    JMP NEXT

PUSH_LEFT:
    CALL PUSH_OP
    INC SI
    JMP NEXT

POP_BRACKET:
    CALL POP_UNTIL_LEFT
    INC SI
    JMP NEXT

END_PARSE:
    RET
PARSE_EXPR ENDP

; ==================================================
; 读取多位数
READ_NUMBER PROC
    XOR AX,AX

R1:
    MOV BL,[SI]

    CMP BL,'0'
    JB RD_END
    CMP BL,'9'
    JA RD_END

    SUB BL,'0'
    MOV CX,10
    MUL CX
    ADD AX,BX

    INC SI
    JMP R1

RD_END:
    RET
READ_NUMBER ENDP

; ==================================================
; 数字栈 push
PUSH_NUM PROC
    MOV BX,numTop
    SHL BX,1
    MOV numStack[BX],AX
    INC numTop
    RET
PUSH_NUM ENDP

POP_NUM PROC
    DEC numTop
    MOV BX,numTop
    SHL BX,1
    MOV AX,numStack[BX]
    RET
POP_NUM ENDP

; ==================================================
; 运算符栈 push
PUSH_OP PROC
    MOV BX,opTop
    MOV opStack[BX],AL
    INC opTop
    RET
PUSH_OP ENDP

POP_OP PROC
    DEC opTop
    MOV BX,opTop
    MOV AL,opStack[BX]
    RET
POP_OP ENDP

TOP_OP PROC
    MOV BX,opTop
    DEC BX
    MOV AL,opStack[BX]
    RET
TOP_OP ENDP

; ==================================================
; 优先级
PRIORITY PROC
    CMP AL,'+'
    JE P1
    CMP AL,'-'
    JE P1
    CMP AL,'*'
    JE P2
    CMP AL,'/'
    JE P2
    MOV AX,0
    RET
P1:
    MOV AX,1
    RET
P2:
    MOV AX,2
    RET
PRIORITY ENDP

; ==================================================
; 运算处理
HANDLE_OP PROC

H1:
    CMP opTop,0
    JE PUSH_IT

    CALL TOP_OP
    MOV BL,AL

    MOV AL,[SI]
    CALL PRIORITY
    MOV CX,AX

    MOV AL,BL
    CALL PRIORITY
    MOV DX,AX

    CMP DX,CX
    JL PUSH_IT

    CALL DO_CALC
    JMP H1

PUSH_IT:
    MOV AL,[SI]
    CALL PUSH_OP
    INC SI
    RET
HANDLE_OP ENDP

; ==================================================
; 括号处理
POP_UNTIL_LEFT PROC

P1:
    CMP opTop,0
    JE ENDP

    CALL TOP_OP
    CMP AL,'('
    JE REMOVE_LEFT

    CALL DO_CALC
    JMP P1

REMOVE_LEFT:
    CALL POP_OP

ENDP:
    RET
POP_UNTIL_LEFT ENDP

; ==================================================
; 核心计算
DO_CALC PROC
    CALL POP_OP
    MOV op,AL

    CALL POP_NUM
    MOV b,AX

    CALL POP_NUM
    MOV a,AX

    CMP op,'+'
    JE ADD
    CMP op,'-'
    JE SUB
    CMP op,'*'
    JE MUL
    CMP op,'/'
    JE DIVV

ADD:
    MOV AX,a
    ADD AX,b
    JMP PUSH_R

SUB:
    MOV AX,a
    SUB AX,b
    JMP PUSH_R

MUL:
    MOV AX,a
    IMUL b
    JMP PUSH_R

DIVV:
    CMP b,0
    JE ERR
    MOV AX,a
    CWD
    IDIV b
    JMP PUSH_R

PUSH_R:
    CALL PUSH_NUM
    RET

ERR:
    MOV err,1
    RET
DO_CALC ENDP

; ==================================================
EVAL_STACK PROC
E1:
    CMP opTop,0
    JE DONE

    CALL DO_CALC
    JMP E1

DONE:
    CALL POP_NUM
    MOV result,AX
    RET
EVAL_STACK ENDP

; ==================================================
PRINT_RESULT PROC
    MOV AX,result
    CALL PRINT_INT
    RET
PRINT_RESULT ENDP

PRINT_INT PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    CMP AX,0
    JGE P

    MOV DL,'-'
    MOV AH,02H
    INT 21H
    NEG AX

P:
    XOR CX,CX
    MOV BX,10

L1:
    XOR DX,DX
    DIV BX
    PUSH DX
    INC CX
    CMP AX,0
    JNE L1

L2:
    POP DX
    ADD DL,'0'
    MOV AH,02H
    INT 21H
    LOOP L2

    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_INT ENDP

; ==================================================
SAVE_HISTORY PROC
    MOV AH,3DH
    MOV AL,1
    LEA DX,fileName
    INT 21H
    JC CREATE

    MOV BX,AX
    JMP WRITE

CREATE:
    MOV AH,3CH
    XOR CX,CX
    LEA DX,fileName
    INT 21H
    MOV BX,AX

WRITE:
    MOV AH,40H
    MOV CX,expr+1
    LEA DX,expr+2
    INT 21H

    MOV AH,3EH
    INT 21H
    RET
SAVE_HISTORY ENDP

; ==================================================
HISTORY PROC
    MOV AH,3DH
    MOV AL,0
    LEA DX,fileName
    INT 21H
    JC BACK

    MOV BX,AX

READ:
    MOV AH,3FH
    MOV CX,100
    LEA DX,buf
    INT 21H
    CMP AX,0
    JE CLOSE

    MOV DX,OFFSET buf
    MOV AH,09H
    INT 21H
    JMP READ

CLOSE:
    MOV AH,3EH
    INT 21H

BACK:
    JMP MAIN_LOOP
HISTORY ENDP

; ==================================================
CLEAR PROC
    MOV AH,3CH
    XOR CX,CX
    LEA DX,fileName
    INT 21H
    MOV AH,3EH
    INT 21H
    JMP MAIN_LOOP
CLEAR ENDP

NEWLINE PROC
    MOV DL,13
    MOV AH,02H
    INT 21H
    MOV DL,10
    INT 21H
    RET
NEWLINE ENDP

EXIT:
    MOV AH,4CH
    INT 21H

MAIN ENDP
END MAIN