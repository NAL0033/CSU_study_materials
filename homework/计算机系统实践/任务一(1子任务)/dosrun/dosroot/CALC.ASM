; =============================================================
; CALCULATOR PRO — Full Arithmetic Expression Evaluator
; x86 Real-mode Assembly (MASM / TASM, .MODEL SMALL)
;
; Features (90+):
;   1. One-line infix expression input with BACKSPACE + UP recall
;   2. Recursive-descent parser: correct precedence & associativity
;   3. Operators: +  -  *  /   Parentheses: ( )   Unary: + -
;   4. Integers + fixed-point decimals (scale ×100, 2 digits)
;   5. Step-by-step solution display (解题思路)
;   6. HISTORY.TXT — auto-save / read with 10-line pagination
;   7. Multiply two history expressions (history multiply)
;   8. Clear history
;   9. Expression validation — balanced parentheses, char check
;  10. Overflow & divide-by-zero detection with specific messages
;  11. Clean four-item menu, re-shown after every operation
;  12. UP-arrow recalls the last successfully evaluated expression
; =============================================================

	.MODEL  SMALL
	.STACK  100H

; -------------------------------------------------------------
MAXEXPR EQU   100             ; max expression length
MAXHIST EQU   20              ; max history entries in memory
SCALE   EQU   100             ; fixed-point scale factor
; -------------------------------------------------------------

	.DATA

; ----- Menu & prompts ----------------------------------------
menuText DB     13,10
         DB     '+==========================================+',13,10
         DB     '|        CALCULATOR PRO  v2.0             |',13,10
         DB     '+==========================================+',13,10
         DB     '|  1. Calculate                          |',13,10
         DB     '|  2. Read History                       |',13,10
         DB     '|  3. Clear History                      |',13,10
         DB     '|  4. Exit                               |',13,10
         DB     '+==========================================+',13,10
         DB     '  Choose (1-4): $'

exprPrompt DB   13,10
           DB   '============================================',13,10
           DB   '  Enter an arithmetic expression:',13,10
           DB   '  e.g.  (3.2 + 4.5) * (5.1 - 2.0) / 3.0',13,10
           DB   '  Tip: press UP arrow to recall last expr.',13,10
           DB   '> $'

; ----- Messages ----------------------------------------------
stepTitle DB    13,10,'--- Solution steps ---',13,10,'$'
resultMsg DB    13,10,'>>> Result = $'
byeMsg   DB     13,10,'Goodbye!',13,10,'$'
saveMsg  DB     13,10,'[ Saved to HISTORY.TXT ]$'

; Specific error messages
errSyntax   DB  13,10,'ERROR: Syntax error in expression.$'
errOverflow DB  13,10,'ERROR: Arithmetic overflow.$'
errDivZero  DB  13,10,'ERROR: Division by zero.$'
errParen    DB  13,10,'ERROR: Unbalanced parentheses.$'
errChar     DB  13,10,'ERROR: Invalid character in expression.$'
errEmpty    DB  13,10,'ERROR: Empty expression.$'

; History messages
histTitle    DB 13,10,'+======= HISTORY (page $'
histTitle2   DB ') =======+',13,10,'$'
noHistoryMsg DB 13,10,'[ No history records found. ]$'
clearMsg     DB 13,10,'[ History cleared. ]$'
fileErrMsg   DB 13,10,'ERROR: Cannot open history file.$'
pageMsg      DB 13,10,'--- Press ENTER for next page, Q to quit ---$'
multiAsk     DB 13,10,'Multiply two history expressions? (Y/N): $'
firstAsk     DB '  First record number : $'
secondAsk    DB '  Second record number: $'
newExprMsg   DB 13,10,'  New expression: $'
badSelectMsg DB 13,10,'ERROR: Invalid record number.$'
noMulMsg     DB 13,10,'[ Need at least 2 history entries to multiply. ]$'

; ----- File name (relative — stays beside .COM/.EXE) ---------
histName DB 'HISTORY.TXT',0

; ----- Buffers -----------------------------------------------
choiceBuf DB 8
          DB 0
          DB 9 DUP(0)

inputBuf  DB MAXEXPR
          DB 0
          DB MAXEXPR+1 DUP(0)

lastLen   DB 0
lastExpr  DB MAXEXPR+1 DUP(0)

; ----- Misc variables ----------------------------------------
readChar   DB 0
resultStr  DB 18 DUP(0)
resultLen  DW 0

endPtr     DW 0            ; pointer to end of input string
parseErr   DB 0            ; 0=ok, 1=syntax, 2=overflow, 3=div0
signFlag   DB 0            ; unary minus flag
digitSeen  DB 0
fracCount  DB 0

intPart    DW 0
fracPart   DW 0
tempLeft   DW 0
tempRight  DW 0
tempResult DW 0
result     DW 0
stepOp     DB 0            ; current operator for step display

fileHandle DW 0

; ----- History display state ---------------------------------
lineNo       DW 0
pageLines    DW 0
atLineStart  DB 0
anyByte      DB 0
historyQuit  DB 0
pageNum      DW 1

; ----- History memory for multiply feature -------------------
histCount  DW 0
histPos    DW 0
copyFlag   DB 0
lineHasData DB 0
histExprs  DB MAXHIST*MAXEXPR DUP(0)
selA       DW 0
selB       DW 0
buildLen   DW 0
buildErr   DB 0

; ----- Step buffer (for screen display only) -----------------
stepBuf    DB 600 DUP(0)
stepBufPos DW 0

; ----- Temp string buffers -----------------------------------
tmpLineBuf DB 80 DUP(0)
crlf       DB 13,10,'$'
crlfRaw    DB 13,10          ; raw CRLF for file write (AH=40h)
equalText  DB ' = $'
dotSpace   DB '. $'
scaleWord  DW SCALE          ; word-sized SCALE for IDIV divisor

	.CODE

; =============================================================
;  MAIN — menu dispatcher
; =============================================================
MAIN PROC
	MOV  AX, @DATA
	MOV  DS, AX

menu_loop:
	LEA  DX, menuText
	CALL PrintString

	LEA  DX, choiceBuf
	CALL ReadLine

	MOV  AL, [choiceBuf+2]

	CMP  AL, '1'
	JE   do_calculate
	CMP  AL, '2'
	JE   do_read_history
	CMP  AL, '3'
	JE   do_clear_history
	CMP  AL, '4'
	JE   do_exit

	; Invalid choice — re-prompt
	LEA  DX, crlf
	CALL PrintString
	JMP  menu_loop

do_calculate:
	CALL DoCalculate
	JMP  menu_loop

do_read_history:
	CALL ReadHistory
	JMP  menu_loop

do_clear_history:
	CALL ClearHistory
	JMP  menu_loop

do_exit:
	LEA  DX, byeMsg
	CALL PrintString
	MOV  AX, 4C00H
	INT  21H
MAIN ENDP

; =============================================================
;  DoCalculate — input, validate, parse, output, save
; =============================================================
DoCalculate PROC
	PUSH AX
	PUSH DX

	; Show prompt and read expression
	LEA  DX, exprPrompt
	CALL PrintString
	CALL ReadExpressionLine

	; Fall through to CalculateCurrentInput which evaluates inputBuf
	CALL CalculateCurrentInput

	POP  DX
	POP  AX
	RET
DoCalculate ENDP

; =============================================================
;  CalculateCurrentInput — evaluate expression in inputBuf
;  (called by both DoCalculate and AskHistoryMultiply)
; =============================================================
CalculateCurrentInput PROC
	PUSH AX
	PUSH BX
	PUSH SI
	PUSH DX

	; Check for empty input
	XOR  AX, AX
	MOV  AL, [inputBuf+1]
	CMP  AL, 0
	JNE  cci_not_empty
	LEA  DX, errEmpty
	CALL PrintString
	LEA  DX, crlf
	CALL PrintString
	JMP  cci_done

cci_not_empty:
	; Validate expression first
	CALL ValidateExpression
	CMP  BYTE PTR [parseErr], 0
	JE   cci_parse

	; Show specific validation error
	CMP  BYTE PTR [parseErr], 4
	JNE  cci_chk_char
	LEA  DX, errParen
	CALL PrintString
	LEA  DX, crlf
	CALL PrintString
	JMP  cci_done
cci_chk_char:
	CMP  BYTE PTR [parseErr], 5
	JNE  cci_done
	LEA  DX, errChar
	CALL PrintString
	LEA  DX, crlf
	CALL PrintString
	JMP  cci_done

cci_parse:
	; Reset parser state
	MOV  BYTE PTR [parseErr], 0
	MOV  WORD PTR [stepBufPos], 0
	MOV  SI, OFFSET inputBuf+2
	XOR  AX, AX
	MOV  AL, [inputBuf+1]
	MOV  BX, OFFSET inputBuf+2
	ADD  BX, AX
	MOV  [endPtr], BX

	; Show solution steps header
	LEA  DX, stepTitle
	CALL PrintString

	; Parse and evaluate
	CALL ParseExpression
	CMP  BYTE PTR [parseErr], 0
	JNE  cci_parse_error

	; Check entire input consumed
	CALL SkipSpaces
	CMP  SI, [endPtr]
	JNE  cci_error_syntax

	; Store result & display
	MOV  [result], AX

	LEA  DX, resultMsg
	CALL PrintString
	MOV  AX, [result]
	CALL PrintFixed
	LEA  DX, crlf
	CALL PrintString

	; Save to file, remember for UP recall
	CALL SaveHistory
	CALL CopyInputToLast
	JMP  cci_done

cci_parse_error:
	CMP  BYTE PTR [parseErr], 2
	JNE  cci_chk_div0
	LEA  DX, errOverflow
	CALL PrintString
	LEA  DX, crlf
	CALL PrintString
	JMP  cci_done
cci_chk_div0:
	CMP  BYTE PTR [parseErr], 3
	JNE  cci_error_syntax
	LEA  DX, errDivZero
	CALL PrintString
	LEA  DX, crlf
	CALL PrintString
	JMP  cci_done
cci_error_syntax:
	LEA  DX, errSyntax
	CALL PrintString
	LEA  DX, crlf
	CALL PrintString

cci_done:
	POP  DX
	POP  SI
	POP  BX
	POP  AX
	RET
CalculateCurrentInput ENDP

; =============================================================
;  ValidateExpression — check balanced parens & valid chars
;  Sets parseErr = 4 (parens) or 5 (bad char) or 0 (ok)
; =============================================================
ValidateExpression PROC
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH SI

	MOV  BYTE PTR [parseErr], 0
	XOR  CX, CX               ; CX = paren depth counter
	XOR  AX, AX
	MOV  AL, [inputBuf+1]
	MOV  SI, OFFSET inputBuf+2
	MOV  BX, SI
	ADD  BX, AX                ; BX = end pointer

ve_loop:
	CMP  SI, BX
	JAE  ve_check_balance

	MOV  AL, [SI]

	; Check valid characters
	CMP  AL, ' '
	JE   ve_next
	CMP  AL, '+'
	JE   ve_next
	CMP  AL, '-'
	JE   ve_next
	CMP  AL, '*'
	JE   ve_next
	CMP  AL, '/'
	JE   ve_next
	CMP  AL, '('
	JE   ve_open
	CMP  AL, ')'
	JE   ve_close
	CMP  AL, '.'
	JE   ve_next
	CMP  AL, '0'
	JB   ve_bad
	CMP  AL, '9'
	JBE  ve_next
	JMP  ve_bad

ve_open:
	INC  CX
	JMP  ve_next

ve_close:
	DEC  CX
	JS   ve_bad_paren          ; more closes than opens
	JMP  ve_next

ve_next:
	INC  SI
	JMP  ve_loop

ve_check_balance:
	CMP  CX, 0
	JNE  ve_bad_paren
	JMP  ve_done

ve_bad_paren:
	MOV  BYTE PTR [parseErr], 4
	JMP  ve_done

ve_bad:
	MOV  BYTE PTR [parseErr], 5

ve_done:
	POP  SI
	POP  CX
	POP  BX
	POP  AX
	RET
ValidateExpression ENDP

; =============================================================
;  DOS buffered line input  (DX → 0Ah buffer)
; =============================================================
ReadLine PROC
	PUSH AX
	PUSH BX
	PUSH SI

	MOV  AH, 0AH
	INT  21H

	; Null-terminate
	MOV  BX, DX
	XOR  AX, AX
	MOV  AL, [BX+1]
	MOV  SI, AX
	MOV  BYTE PTR [BX+SI+2], 0

	POP  SI
	POP  BX
	POP  AX
	RET
ReadLine ENDP

; =============================================================
;  PrintString — DX → $-terminated string
; =============================================================
PrintString PROC
	MOV  AH, 09H
	INT  21H
	RET
PrintString ENDP

; =============================================================
;  PrintChar — DL = character
; =============================================================
PrintChar PROC
	MOV  AH, 02H
	INT  21H
	RET
PrintChar ENDP

; =============================================================
;  PrintCRLF — convenience
; =============================================================
PrintCRLF PROC
	PUSH DX
	LEA  DX, crlf
	CALL PrintString
	POP  DX
	RET
PrintCRLF ENDP

; =============================================================
;  ReadExpressionLine — custom input with BACKSPACE + UP recall
; =============================================================
ReadExpressionLine PROC
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
	PUSH SI
	PUSH DI

	XOR  CX, CX               ; CX = chars typed
	MOV  DI, OFFSET inputBuf+2

rel_loop:
	MOV  AH, 08H              ; read char without echo
	INT  21H

	CMP  AL, 0DH              ; Enter
	JE   rel_done

	CMP  AL, 08H              ; Backspace
	JE   rel_backspace

	CMP  AL, 00H              ; extended key prefix
	JE   rel_ext
	CMP  AL, 0E0H             ; extended key prefix (alternate)
	JE   rel_ext

	; Normal character — add if room
	MOV  BL, [inputBuf]
	XOR  BH, BH
	CMP  CX, BX
	JAE  rel_loop              ; buffer full

	MOV  [DI], AL
	INC  DI
	INC  CX
	MOV  DL, AL
	CALL PrintChar
	JMP  rel_loop

rel_backspace:
	CMP  CX, 0
	JE   rel_loop
	DEC  CX
	DEC  DI
	MOV  DL, 08H
	CALL PrintChar
	MOV  DL, ' '
	CALL PrintChar
	MOV  DL, 08H
	CALL PrintChar
	JMP  rel_loop

rel_ext:
	MOV  AH, 08H              ; read scan code
	INT  21H
	CMP  AL, 48H              ; UP arrow scan code
	JNE  rel_loop

	; Only recall if buffer is empty
	CMP  CX, 0
	JNE  rel_loop
	CMP  BYTE PTR [lastLen], 0
	JE   rel_loop

	; Copy lastExpr into input buffer
	MOV  SI, OFFSET lastExpr
rel_copy_last:
	MOV  AL, [SI]
	CMP  AL, 0
	JE   rel_copy_done
	MOV  BL, [inputBuf]
	XOR  BH, BH
	CMP  CX, BX
	JAE  rel_copy_done
	MOV  [DI], AL
	INC  DI
	INC  SI
	INC  CX
	MOV  DL, AL
	CALL PrintChar
	JMP  rel_copy_last
rel_copy_done:
	JMP  rel_loop

rel_done:
	MOV  [inputBuf+1], CL
	MOV  BYTE PTR [DI], 0
	CALL PrintCRLF

	POP  DI
	POP  SI
	POP  DX
	POP  CX
	POP  BX
	POP  AX
	RET
ReadExpressionLine ENDP

; =============================================================
;  CopyInputToLast — save current input as UP-arrow recall
; =============================================================
CopyInputToLast PROC
	PUSH AX
	PUSH CX
	PUSH SI
	PUSH DI

	XOR  CX, CX
	MOV  CL, [inputBuf+1]
	MOV  [lastLen], CL
	MOV  SI, OFFSET inputBuf+2
	MOV  DI, OFFSET lastExpr
	REP  MOVSB
	MOV  BYTE PTR [DI], 0

	POP  DI
	POP  SI
	POP  CX
	POP  AX
	RET
CopyInputToLast ENDP

; =============================================================
;  SkipSpaces — advance SI past spaces
; =============================================================
SkipSpaces PROC
ss_loop:
	CMP  SI, [endPtr]
	JAE  ss_done
	CMP  BYTE PTR [SI], ' '
	JNE  ss_done
	INC  SI
	JMP  ss_loop
ss_done:
	RET
SkipSpaces ENDP

; =============================================================
;  ParseExpression → Expression = Term { (+|-) Term }
;  Returns value in AX (scaled ×100)
; =============================================================
ParseExpression PROC
	CALL ParseTerm
	CMP  BYTE PTR [parseErr], 0
	JNE  pe_done

pe_loop:
	CALL SkipSpaces
	CMP  SI, [endPtr]
	JAE  pe_done

	MOV  DL, [SI]
	CMP  DL, '+'
	JE   pe_op
	CMP  DL, '-'
	JE   pe_op
	JMP  pe_done

pe_op:
	INC  SI
	PUSH AX                  ; save left operand
	PUSH DX                  ; save operator
	CALL ParseTerm
	POP  DX                  ; DL = operator
	POP  BX                  ; BX = left operand

	CMP  BYTE PTR [parseErr], 0
	JNE  pe_done

	MOV  [tempLeft], BX
	MOV  [tempRight], AX
	MOV  [stepOp], DL

	CMP  DL, '+'
	JE   pe_add

	; Subtraction: left - right
	MOV  AX, BX
	SUB  AX, [tempRight]
	JO   pe_overflow
	JMP  pe_store

pe_add:
	MOV  AX, BX
	ADD  AX, [tempRight]
	JO   pe_overflow

pe_store:
	MOV  [tempResult], AX
	CALL PrintStep
	MOV  AX, [tempResult]
	JMP  pe_loop

pe_overflow:
	MOV  BYTE PTR [parseErr], 2
pe_done:
	RET
ParseExpression ENDP

; =============================================================
;  ParseTerm → Term = Factor { (*|/) Factor }
;  Returns value in AX (scaled ×100)
; =============================================================
ParseTerm PROC
	CALL ParseFactor
	CMP  BYTE PTR [parseErr], 0
	JNE  pt_done

pt_loop:
	CALL SkipSpaces
	CMP  SI, [endPtr]
	JAE  pt_done

	MOV  DL, [SI]
	CMP  DL, '*'
	JE   pt_op
	CMP  DL, '/'
	JE   pt_op
	JMP  pt_done

pt_op:
	INC  SI
	PUSH AX                  ; save left
	PUSH DX                  ; save operator
	CALL ParseFactor
	POP  DX                  ; DL = operator
	POP  BX                  ; BX = left

	CMP  BYTE PTR [parseErr], 0
	JNE  pt_done

	MOV  [tempLeft], BX
	MOV  [tempRight], AX
	MOV  [stepOp], DL

	CMP  DL, '*'
	JE   pt_mul

	; --- Division: (left × SCALE) / right ---
	CMP  WORD PTR [tempRight], 0
	JE   pt_div_zero

	MOV  AX, [tempLeft]
	CWD                      ; sign-extend AX → DX:AX
	MOV  BX, SCALE
	IMUL BX                  ; DX:AX = left × 100
	; Check if result fits in 16 bits after division
	; IDIV will check for overflow automatically
	IDIV WORD PTR [tempRight] ; AX = (left × 100) / right
	JMP  pt_store

pt_mul:
	; --- Multiplication: (left × right) / SCALE ---
	; Pre-check: both operands are stored ×100.
	; left×right can be up to 32767×32767 ≈ 1.07e9.
	; After /100, result must fit in signed 16-bit (-32768..32767).
	MOV  AX, [tempLeft]
	IMUL WORD PTR [tempRight]    ; DX:AX = left × right

	; Quick check: IDIV by 100 will overflow if |DX:AX| >= 100×32768
	; Positive case: DX:AX > 3,276,700 (0x0031FF5C)
	; Negative case: DX:AX < -3,276,800 (sign-extended)
	; Simpler: check if DX has "significant" bits beyond what /100 can absorb
	CMP  DX, 0
	JGE  pt_mul_pos_chk
	; DX is negative (>= 8000h). For IDIV to work, DX:AX / 100 must fit.
	; If DX < -1 (i.e., not FFFFh AND value too negative), overflow likely.
	; Check: if DX == -1 AND AX <= 8000h, result should be non-negative after /100 → ok
	CMP  DX, -1
	JNE  pt_mul_overflow         ; DX != -1, definitely overflows
	CMP  AX, 8000H
	JBE  pt_mul_ok               ; DX=-1, AX <= 8000h → quotient 0..32768, ok
	JMP  pt_mul_overflow
pt_mul_pos_chk:
	CMP  DX, 0
	JNE  pt_mul_overflow         ; DX > 0, 32-bit value > 65535, /100 could still overflow
	CMP  AX, 8000H
	JB   pt_mul_ok               ; DX=0, AX < 32768 → quotient fits
	; DX=0, AX >= 32768: need to check if AX/100 < 32768. Actually IDIV handles this.
	; But AX could be up to 65535, /100 = 655 max, so it always fits if DX=0.
	JMP  pt_mul_ok               ; If DX=0, quotient is just AX/100 which always fits in 16-bit

pt_mul_overflow:
	MOV  BYTE PTR [parseErr], 2
	JMP  pt_done

pt_mul_ok:
	IDIV WORD PTR [scaleWord]
	JMP  pt_store

pt_div_zero:
	MOV  BYTE PTR [parseErr], 3
	JMP  pt_done

pt_store:
	MOV  [tempResult], AX
	CALL PrintStep
	MOV  AX, [tempResult]
	JMP  pt_loop

pt_done:
	RET
ParseTerm ENDP

; =============================================================
;  ParseFactor → Factor = number | ( Expression ) | +Factor | -Factor
; =============================================================
ParseFactor PROC
	CALL SkipSpaces
	MOV  BYTE PTR [signFlag], 0

pf_sign_loop:
	CALL SkipSpaces
	CMP  SI, [endPtr]
	JAE  pf_error
	MOV  AL, [SI]
	CMP  AL, '+'
	JE   pf_plus
	CMP  AL, '-'
	JE   pf_minus
	JMP  pf_body

pf_plus:
	INC  SI
	JMP  pf_sign_loop

pf_minus:
	XOR  BYTE PTR [signFlag], 1
	INC  SI
	JMP  pf_sign_loop

pf_body:
	CMP  BYTE PTR [SI], '('
	JE   pf_paren

	CALL ParseNumber
	CMP  BYTE PTR [parseErr], 0
	JNE  pf_done
	CMP  BYTE PTR [signFlag], 0
	JE   pf_done
	NEG  AX
	JMP  pf_done

pf_paren:
	INC  SI                  ; skip '('
	CALL ParseExpression
	CMP  BYTE PTR [parseErr], 0
	JNE  pf_done
	CALL SkipSpaces
	CMP  SI, [endPtr]
	JAE  pf_error
	CMP  BYTE PTR [SI], ')'
	JNE  pf_error
	INC  SI                  ; skip ')'
	CMP  BYTE PTR [signFlag], 0
	JE   pf_done
	NEG  AX
	JMP  pf_done

pf_error:
	MOV  BYTE PTR [parseErr], 1
pf_done:
	RET
ParseFactor ENDP

; =============================================================
;  ParseNumber → integer [. fraction]  → AX = value × 100
; =============================================================
ParseNumber PROC
	MOV  WORD PTR [intPart], 0
	MOV  WORD PTR [fracPart], 0
	MOV  BYTE PTR [fracCount], 0
	MOV  BYTE PTR [digitSeen], 0

pn_int_loop:
	CMP  SI, [endPtr]
	JAE  pn_after_int
	MOV  AL, [SI]
	CMP  AL, '0'
	JB   pn_after_int
	CMP  AL, '9'
	JA   pn_after_int

	MOV  BYTE PTR [digitSeen], 1
	SUB  AL, '0'
	XOR  AH, AH
	PUSH AX
	MOV  AX, [intPart]
	MOV  BX, 10
	MUL  BX                   ; DX:AX = intPart × 10
	CMP  DX, 0                ; overflow if DX != 0
	JNE  pn_error
	POP  BX
	ADD  AX, BX
	JO   pn_error
	MOV  [intPart], AX
	INC  SI
	JMP  pn_int_loop

pn_after_int:
	CMP  SI, [endPtr]
	JAE  pn_make
	CMP  BYTE PTR [SI], '.'
	JNE  pn_make
	INC  SI                   ; skip '.'

pn_dec_loop:
	CMP  SI, [endPtr]
	JAE  pn_make
	MOV  AL, [SI]
	CMP  AL, '0'
	JB   pn_make
	CMP  AL, '9'
	JA   pn_make

	MOV  BYTE PTR [digitSeen], 1
	SUB  AL, '0'
	XOR  AH, AH

	CMP  BYTE PTR [fracCount], 0
	JE   pn_first_dec
	CMP  BYTE PTR [fracCount], 1
	JE   pn_second_dec
	JMP  pn_skip_extra         ; ignore digits beyond 2

pn_first_dec:
	MOV  BL, 10
	MUL  BL                    ; AL = digit × 10
	ADD  [fracPart], AX
	INC  BYTE PTR [fracCount]
	JMP  pn_skip_extra

pn_second_dec:
	ADD  [fracPart], AX        ; AX = digit (0-9)
	INC  BYTE PTR [fracCount]

pn_skip_extra:
	INC  SI
	JMP  pn_dec_loop

pn_make:
	CMP  BYTE PTR [digitSeen], 0
	JE   pn_error
	MOV  AX, [intPart]
	MOV  BX, SCALE
	MUL  BX                    ; DX:AX = intPart × 100
	CMP  DX, 0
	JNE  pn_error
	ADD  AX, [fracPart]
	RET

pn_error:
	MOV  BYTE PTR [parseErr], 1
	RET
ParseNumber ENDP

; =============================================================
;  PrintStep — display one evaluation step on screen & buffer
;  Format:  Step: left op right = result
; =============================================================
PrintStep PROC
	PUSH AX
	PUSH DX

	; Print "Step: L op R = RES" to screen
	MOV  DL, ' '
	CALL PrintChar
	MOV  DL, '-'
	CALL PrintChar
	MOV  DL, ' '
	CALL PrintChar

	MOV  AX, [tempLeft]
	CALL PrintFixed

	MOV  DL, ' '
	CALL PrintChar
	MOV  DL, [stepOp]
	CALL PrintChar
	MOV  DL, ' '
	CALL PrintChar

	MOV  AX, [tempRight]
	CALL PrintFixed

	MOV  DL, ' '
	CALL PrintChar
	MOV  DL, '='
	CALL PrintChar
	MOV  DL, ' '
	CALL PrintChar

	MOV  AX, [tempResult]
	CALL PrintFixed

	CALL PrintCRLF

	; Also buffer the step for history (informational only, not saved)
	CALL BufferStep

	POP  DX
	POP  AX
	RET
PrintStep ENDP

; =============================================================
;  BufferStep — append formatted step line to stepBuf
;  (Used only for screen display; steps are NOT written to file)
; =============================================================
BufferStep PROC
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
	PUSH DI
	PUSH SI

	LEA  DI, tmpLineBuf

	MOV  AX, [tempLeft]
	CALL AppendFixedToDI

	MOV  BYTE PTR [DI], ' '
	INC  DI
	MOV  AL, [stepOp]
	MOV  [DI], AL
	INC  DI
	MOV  BYTE PTR [DI], ' '
	INC  DI

	MOV  AX, [tempRight]
	CALL AppendFixedToDI

	MOV  BYTE PTR [DI], ' '
	INC  DI
	MOV  BYTE PTR [DI], '='
	INC  DI
	MOV  BYTE PTR [DI], ' '
	INC  DI

	MOV  AX, [tempResult]
	CALL AppendFixedToDI

	MOV  BYTE PTR [DI], 13
	INC  DI
	MOV  BYTE PTR [DI], 10
	INC  DI

	; Compute length
	MOV  CX, DI
	LEA  BX, tmpLineBuf
	SUB  CX, BX

	; Append to stepBuf
	PUSH ES
	PUSH DS
	POP  ES
	MOV  SI, OFFSET tmpLineBuf
	MOV  DI, OFFSET stepBuf
	ADD  DI, [stepBufPos]
	REP  MOVSB
	POP  ES
	ADD  [stepBufPos], CX

	POP  SI
	POP  DI
	POP  DX
	POP  CX
	POP  BX
	POP  AX
	RET
BufferStep ENDP

; =============================================================
;  AppendFixedToDI — append "XXX.XX" to buffer at DI, return
;                    updated DI; AX = value × 100
; =============================================================
AppendFixedToDI PROC
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX

	CMP  AX, 0
	JGE  afd_pos
	MOV  BYTE PTR [DI], '-'
	INC  DI
	NEG  AX

afd_pos:
	XOR  DX, DX
	MOV  BX, SCALE
	DIV  BX                    ; AX = int, DX = frac
	PUSH DX

	CMP  AX, 0
	JNE  afd_int_nz
	MOV  BYTE PTR [DI], '0'
	INC  DI
	JMP  afd_dec

afd_int_nz:
	XOR  CX, CX
	MOV  BX, 10
afd_div:
	XOR  DX, DX
	DIV  BX
	PUSH DX
	INC  CX
	CMP  AX, 0
	JNE  afd_div
afd_pop:
	POP  DX
	ADD  DL, '0'
	MOV  [DI], DL
	INC  DI
	LOOP afd_pop

afd_dec:
	MOV  BYTE PTR [DI], '.'
	INC  DI
	POP  AX                    ; frac 0..99
	XOR  AH, AH
	MOV  BL, 10
	DIV  BL                    ; AL = tens, AH = ones
	ADD  AL, '0'
	MOV  [DI], AL
	INC  DI
	MOV  AL, AH
	ADD  AL, '0'
	MOV  [DI], AL
	INC  DI

	POP  DX
	POP  CX
	POP  BX
	POP  AX
	RET
AppendFixedToDI ENDP

; =============================================================
;  PrintFixed — print AX/100 with 2 decimal places to screen
; =============================================================
PrintFixed PROC
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX

	CMP  AX, 0
	JGE  pf_positive
	MOV  DL, '-'
	CALL PrintChar
	NEG  AX

pf_positive:
	XOR  DX, DX
	MOV  BX, SCALE
	DIV  BX                    ; AX = integer part, DX = fraction
	PUSH DX
	CALL PrintUInt
	MOV  DL, '.'
	CALL PrintChar
	POP  AX                    ; fraction 0..99
	CALL PrintTwoDigits

	POP  DX
	POP  CX
	POP  BX
	POP  AX
	RET
PrintFixed ENDP

; =============================================================
;  PrintUInt — print unsigned integer in AX
; =============================================================
PrintUInt PROC
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX

	CMP  AX, 0
	JNE  pu_not_zero
	MOV  DL, '0'
	CALL PrintChar
	JMP  pu_done

pu_not_zero:
	XOR  CX, CX
	MOV  BX, 10
pu_div_loop:
	XOR  DX, DX
	DIV  BX
	PUSH DX
	INC  CX
	CMP  AX, 0
	JNE  pu_div_loop

pu_print_loop:
	POP  DX
	ADD  DL, '0'
	CALL PrintChar
	LOOP pu_print_loop

pu_done:
	POP  DX
	POP  CX
	POP  BX
	POP  AX
	RET
PrintUInt ENDP

; =============================================================
;  PrintTwoDigits — print 2-digit zero-padded number in AL
; =============================================================
PrintTwoDigits PROC
	PUSH AX
	PUSH BX
	PUSH DX

	XOR  AH, AH
	MOV  BL, 10
	DIV  BL                    ; AL = tens, AH = ones
	MOV  DH, AH
	ADD  AL, '0'
	MOV  DL, AL
	CALL PrintChar
	MOV  DL, DH
	ADD  DL, '0'
	CALL PrintChar

	POP  DX
	POP  BX
	POP  AX
	RET
PrintTwoDigits ENDP

; =============================================================
;  SaveHistory — write "expression = result" to HISTORY.TXT
;  Steps are NOT saved to file (only shown on screen).
; =============================================================
SaveHistory PROC
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX

	CALL MakeFixedString        ; resultStr ← formatted result

	; Open or create file
	MOV  AX, 3D02H             ; open for read/write
	LEA  DX, histName
	INT  21H
	JC   sh_create

	MOV  [fileHandle], AX
	JMP  sh_seek_end

sh_create:
	MOV  AH, 3CH               ; create file
	MOV  CX, 0
	LEA  DX, histName
	INT  21H
	JC   sh_file_error
	MOV  [fileHandle], AX

sh_seek_end:
	MOV  BX, [fileHandle]
	MOV  AX, 4202H             ; seek to end
	XOR  CX, CX
	XOR  DX, DX
	INT  21H

	; Write expression (from inputBuf)
	MOV  BX, [fileHandle]
	LEA  DX, inputBuf+2
	XOR  CX, CX
	MOV  CL, [inputBuf+1]
	MOV  AH, 40H
	INT  21H

	; Write " = "
	MOV  BX, [fileHandle]
	LEA  DX, equalText
	MOV  CX, 3
	MOV  AH, 40H
	INT  21H

	; Write result string
	MOV  BX, [fileHandle]
	LEA  DX, resultStr
	MOV  CX, [resultLen]
	MOV  AH, 40H
	INT  21H

	; Write CRLF
	MOV  BX, [fileHandle]
	LEA  DX, crlfRaw
	MOV  CX, 2
	MOV  AH, 40H
	INT  21H

	; Close file
	MOV  BX, [fileHandle]
	MOV  AH, 3EH
	INT  21H

	LEA  DX, saveMsg
	CALL PrintString
	LEA  DX, crlf
	CALL PrintString
	JMP  sh_done

sh_file_error:
	LEA  DX, fileErrMsg
	CALL PrintString
	LEA  DX, crlf
	CALL PrintString

sh_done:
	POP  DX
	POP  CX
	POP  BX
	POP  AX
	RET
SaveHistory ENDP

; =============================================================
;  MakeFixedString — format [result] into resultStr
; =============================================================
MakeFixedString PROC
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
	PUSH DI

	LEA  DI, resultStr
	MOV  WORD PTR [resultLen], 0
	MOV  AX, [result]

	CMP  AX, 0
	JGE  mfs_positive
	MOV  BYTE PTR [DI], '-'
	INC  DI
	INC  WORD PTR [resultLen]
	NEG  AX

mfs_positive:
	XOR  DX, DX
	MOV  BX, SCALE
	DIV  BX                    ; AX = integer, DX = fraction
	PUSH DX
	CALL AppendUIntToDI
	MOV  BYTE PTR [DI], '.'
	INC  DI
	INC  WORD PTR [resultLen]
	POP  AX
	CALL AppendTwoDigitsToDI

	MOV  BYTE PTR [DI], 0

	POP  DI
	POP  DX
	POP  CX
	POP  BX
	POP  AX
	RET
MakeFixedString ENDP

; =============================================================
;  AppendUIntToDI — append unsigned integer AX to buffer at DI
; =============================================================
AppendUIntToDI PROC
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX

	CMP  AX, 0
	JNE  au_not_zero
	MOV  BYTE PTR [DI], '0'
	INC  DI
	INC  WORD PTR [resultLen]
	JMP  au_done

au_not_zero:
	XOR  CX, CX
	MOV  BX, 10
au_div_loop:
	XOR  DX, DX
	DIV  BX
	PUSH DX
	INC  CX
	CMP  AX, 0
	JNE  au_div_loop

au_pop_loop:
	POP  DX
	ADD  DL, '0'
	MOV  [DI], DL
	INC  DI
	INC  WORD PTR [resultLen]
	LOOP au_pop_loop

au_done:
	POP  DX
	POP  CX
	POP  BX
	POP  AX
	RET
AppendUIntToDI ENDP

; =============================================================
;  AppendTwoDigitsToDI — append 2-digit fraction to DI
; =============================================================
AppendTwoDigitsToDI PROC
	PUSH AX
	PUSH BX
	PUSH DX

	XOR  AH, AH
	MOV  BL, 10
	DIV  BL
	MOV  DH, AH
	ADD  AL, '0'
	MOV  [DI], AL
	INC  DI
	INC  WORD PTR [resultLen]
	MOV  AL, DH
	ADD  AL, '0'
	MOV  [DI], AL
	INC  DI
	INC  WORD PTR [resultLen]

	POP  DX
	POP  BX
	POP  AX
	RET
AppendTwoDigitsToDI ENDP

; =============================================================
;  ReadHistory — display HISTORY.TXT with 10-line pagination,
;  then optionally multiply two selected expressions.
; =============================================================
ReadHistory PROC
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX

	LEA  DX, crlf
	CALL PrintString

	MOV  WORD PTR [lineNo], 1
	MOV  WORD PTR [pageLines], 0
	MOV  WORD PTR [pageNum], 1
	MOV  BYTE PTR [atLineStart], 1
	MOV  BYTE PTR [anyByte], 0
	MOV  BYTE PTR [historyQuit], 0

	; Open file for reading
	MOV  AX, 3D00H
	LEA  DX, histName
	INT  21H
	JC   rh_no_file
	MOV  [fileHandle], AX

	; Print page header
	LEA  DX, histTitle
	CALL PrintString
	MOV  AX, [pageNum]
	CALL PrintUInt
	LEA  DX, histTitle2
	CALL PrintString

rh_read_loop:
	MOV  BX, [fileHandle]
	LEA  DX, readChar
	MOV  CX, 1
	MOV  AH, 3FH
	INT  21H
	JC   rh_close
	CMP  AX, 0
	JE   rh_eof

	MOV  BYTE PTR [anyByte], 1
	MOV  AL, [readChar]

	; Skip LF (handle both CRLF and LF-only)
	CMP  AL, 10
	JE   rh_read_loop

	CMP  AL, 13
	JE   rh_new_line

	; Print line number at start of each line
	CMP  BYTE PTR [atLineStart], 0
	JE   rh_print_char

	PUSH AX
	PUSH DX
	MOV  AX, [lineNo]
	CALL PrintUInt
	LEA  DX, dotSpace
	CALL PrintString
	POP  DX
	POP  AX
	MOV  BYTE PTR [atLineStart], 0

rh_print_char:
	MOV  DL, [readChar]
	CALL PrintChar
	JMP  rh_read_loop

rh_new_line:
	CALL PrintCRLF
	INC  WORD PTR [lineNo]
	INC  WORD PTR [pageLines]
	MOV  BYTE PTR [atLineStart], 1

	CMP  WORD PTR [pageLines], 10
	JB   rh_read_loop

	; Page full — prompt for next page
	MOV  WORD PTR [pageLines], 0
	INC  WORD PTR [pageNum]

	LEA  DX, pageMsg
	CALL PrintString
	MOV  AH, 08H
	INT  21H

	CMP  AL, 'q'
	JE   rh_quit_page
	CMP  AL, 'Q'
	JE   rh_quit_page

	; Print next page header
	CALL PrintCRLF
	LEA  DX, histTitle
	CALL PrintString
	MOV  AX, [pageNum]
	CALL PrintUInt
	LEA  DX, histTitle2
	CALL PrintString
	JMP  rh_read_loop

rh_quit_page:
	MOV  BYTE PTR [historyQuit], 1
	JMP  rh_close

rh_eof:
	CMP  BYTE PTR [anyByte], 0
	JNE  rh_close
	LEA  DX, noHistoryMsg
	CALL PrintString
	LEA  DX, crlf
	CALL PrintString

rh_close:
	MOV  BX, [fileHandle]
	MOV  AH, 3EH
	INT  21H

	CMP  BYTE PTR [anyByte], 0
	JE   rh_done
	CMP  BYTE PTR [historyQuit], 1
	JE   rh_done

	; Offer history multiply
	CALL AskHistoryMultiply
	JMP  rh_done

rh_no_file:
	LEA  DX, noHistoryMsg
	CALL PrintString
	LEA  DX, crlf
	CALL PrintString

rh_done:
	POP  DX
	POP  CX
	POP  BX
	POP  AX
	RET
ReadHistory ENDP

; =============================================================
;  AskHistoryMultiply — load history, ask which two to multiply
; =============================================================
AskHistoryMultiply PROC
	PUSH AX
	PUSH BX
	PUSH DX

	CALL LoadHistoryMemory
	CMP  WORD PTR [histCount], 2
	JAE  ahm_ok
	LEA  DX, noMulMsg
	CALL PrintString
	LEA  DX, crlf
	CALL PrintString
	JMP  ahm_done

ahm_ok:
	LEA  DX, multiAsk
	CALL PrintString
	MOV  AH, 01H
	INT  21H
	LEA  DX, crlf
	CALL PrintString

	CMP  AL, 'Y'
	JE   ahm_yes
	CMP  AL, 'y'
	JNE  ahm_done

ahm_yes:
	; Get first record number
	LEA  DX, firstAsk
	CALL PrintString
	LEA  DX, choiceBuf
	CALL ReadLine
	CALL BufferToNumber
	MOV  [selA], AX

	; Get second record number
	LEA  DX, secondAsk
	CALL PrintString
	LEA  DX, choiceBuf
	CALL ReadLine
	CALL BufferToNumber
	MOV  [selB], AX

	; Validate selections
	MOV  AX, [selA]
	CMP  AX, 1
	JB   ahm_bad
	CMP  AX, [histCount]
	JA   ahm_bad
	MOV  AX, [selB]
	CMP  AX, 1
	JB   ahm_bad
	CMP  AX, [histCount]
	JA   ahm_bad

	; Compose and calculate
	CALL ComposeHistoryMul
	CMP  BYTE PTR [buildErr], 0
	JNE  ahm_bad

	LEA  DX, newExprMsg
	CALL PrintString
	; Show the composed expression
	PUSH AX
	PUSH CX
	PUSH SI
	XOR  CX, CX
	MOV  CL, [inputBuf+1]
	MOV  SI, OFFSET inputBuf+2
ahm_show:
	CMP  CX, 0
	JE   ahm_show_done
	MOV  DL, [SI]
	CALL PrintChar
	INC  SI
	DEC  CX
	JMP  ahm_show
ahm_show_done:
	POP  SI
	POP  CX
	POP  AX
	LEA  DX, crlf
	CALL PrintString

	CALL CalculateCurrentInput
	JMP  ahm_done

ahm_bad:
	LEA  DX, badSelectMsg
	CALL PrintString
	LEA  DX, crlf
	CALL PrintString

ahm_done:
	POP  DX
	POP  BX
	POP  AX
	RET
AskHistoryMultiply ENDP

; =============================================================
;  BufferToNumber — parse decimal number from choiceBuf → AX
; =============================================================
BufferToNumber PROC
	PUSH BX
	PUSH CX
	PUSH DX
	PUSH SI

	XOR  AX, AX
	XOR  CX, CX
	MOV  CL, [choiceBuf+1]
	MOV  SI, OFFSET choiceBuf+2
btn_loop:
	CMP  CX, 0
	JE   btn_done
	MOV  DL, [SI]
	CMP  DL, '0'
	JB   btn_next
	CMP  DL, '9'
	JA   btn_next
	SUB  DL, '0'
	PUSH DX
	MOV  BX, 10
	MUL  BX
	POP  DX
	XOR  DH, DH
	ADD  AX, DX
btn_next:
	INC  SI
	DEC  CX
	JMP  btn_loop
btn_done:
	POP  SI
	POP  DX
	POP  CX
	POP  BX
	RET
BufferToNumber ENDP

; =============================================================
;  LoadHistoryMemory — parse HISTORY.TXT into histExprs[]
;  Format per line:  expression = result
;  We extract the expression part (before " = ").
;  Sets histCount = number of entries loaded.
; =============================================================
LoadHistoryMemory PROC
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
	PUSH SI
	PUSH DI

	MOV  WORD PTR [histCount], 0

	MOV  AX, 3D00H
	LEA  DX, histName
	INT  21H
	JC   lhm_done
	MOV  [fileHandle], AX

lhm_next_line:
	CMP  WORD PTR [histCount], MAXHIST
	JAE  lhm_close

	; Calculate destination for this entry
	MOV  AX, [histCount]
	MOV  BX, MAXEXPR
	MUL  BX
	MOV  DI, OFFSET histExprs
	ADD  DI, AX
	MOV  WORD PTR [histPos], 0
	MOV  BYTE PTR [copyFlag], 1    ; 1 = copying expression
	MOV  BYTE PTR [lineHasData], 0

lhm_read:
	MOV  BX, [fileHandle]
	LEA  DX, readChar
	MOV  CX, 1
	MOV  AH, 3FH
	INT  21H
	JC   lhm_close
	CMP  AX, 0
	JE   lhm_eof

	MOV  AL, [readChar]

	; Skip LF
	CMP  AL, 10
	JE   lhm_read

	; CR = end of line
	CMP  AL, 13
	JE   lhm_finish_line

	; Mark that we have data
	MOV  BYTE PTR [lineHasData], 1

	; If we see '=' followed by space, stop copying
	; (the " = " separator between expression and result)
	CMP  BYTE PTR [copyFlag], 0
	JE   lhm_read

	CMP  AL, '='
	JNE  lhm_copy_char

	; We hit '=' — peek ahead to confirm " = " pattern, then stop
	MOV  BYTE PTR [copyFlag], 0

	; Trim trailing spaces from expression
lhm_trim:
	MOV  BX, [histPos]
	CMP  BX, 0
	JE   lhm_trim_done
	MOV  SI, DI
	ADD  SI, BX
	DEC  SI
	CMP  BYTE PTR [SI], ' '
	JNE  lhm_trim_done
	DEC  WORD PTR [histPos]
	JMP  lhm_trim
lhm_trim_done:
	MOV  BX, [histPos]
	MOV  BYTE PTR [DI+BX], 0
	JMP  lhm_read

lhm_copy_char:
	CMP  WORD PTR [histPos], MAXEXPR-1
	JAE  lhm_read
	MOV  [DI], AL
	INC  DI
	INC  WORD PTR [histPos]
	JMP  lhm_read

lhm_finish_line:
	CMP  BYTE PTR [lineHasData], 0
	JE   lhm_next_line
	; Ensure null termination
	MOV  BX, [histPos]
	MOV  BYTE PTR [DI+BX], 0
	INC  WORD PTR [histCount]
	JMP  lhm_next_line

lhm_eof:
	CMP  BYTE PTR [lineHasData], 0
	JE   lhm_close
	MOV  BX, [histPos]
	MOV  BYTE PTR [DI+BX], 0
	INC  WORD PTR [histCount]

lhm_close:
	MOV  BX, [fileHandle]
	MOV  AH, 3EH
	INT  21H

lhm_done:
	POP  DI
	POP  SI
	POP  DX
	POP  CX
	POP  BX
	POP  AX
	RET
LoadHistoryMemory ENDP

; =============================================================
;  ComposeHistoryMul — build "(exprA)*(exprB)" in inputBuf
; =============================================================
ComposeHistoryMul PROC
	PUSH AX
	PUSH BX
	PUSH SI
	PUSH DI

	MOV  BYTE PTR [buildErr], 0
	MOV  WORD PTR [buildLen], 0
	MOV  DI, OFFSET inputBuf+2

	MOV  AL, '('
	CALL AppendCharInput

	MOV  AX, [selA]
	CALL GetHistPtr
	CALL AppendZInput

	MOV  AL, ')'
	CALL AppendCharInput

	MOV  AL, '*'
	CALL AppendCharInput

	MOV  AL, '('
	CALL AppendCharInput

	MOV  AX, [selB]
	CALL GetHistPtr
	CALL AppendZInput

	MOV  AL, ')'
	CALL AppendCharInput

	MOV  AX, [buildLen]
	MOV  [inputBuf+1], AL
	MOV  BYTE PTR [DI], 0

	POP  DI
	POP  SI
	POP  BX
	POP  AX
	RET
ComposeHistoryMul ENDP

; =============================================================
;  GetHistPtr — returns SI = pointer to histExprs[AX-1]
; =============================================================
GetHistPtr PROC
	DEC  AX
	MOV  BX, MAXEXPR
	MUL  BX
	MOV  SI, OFFSET histExprs
	ADD  SI, AX
	RET
GetHistPtr ENDP

; =============================================================
;  AppendCharInput — append AL to inputBuf build area
; =============================================================
AppendCharInput PROC
	CMP  WORD PTR [buildLen], MAXEXPR-2
	JAE  aci_error
	MOV  [DI], AL
	INC  DI
	INC  WORD PTR [buildLen]
	RET
aci_error:
	MOV  BYTE PTR [buildErr], 1
	RET
AppendCharInput ENDP

; =============================================================
;  AppendZInput — append null-terminated string at SI to inputBuf
; =============================================================
AppendZInput PROC
azi_loop:
	CMP  BYTE PTR [buildErr], 0
	JNE  azi_done
	MOV  AL, [SI]
	CMP  AL, 0
	JE   azi_done
	CALL AppendCharInput
	INC  SI
	JMP  azi_loop
azi_done:
	RET
AppendZInput ENDP

; =============================================================
;  ClearHistory — truncate HISTORY.TXT to 0 bytes
; =============================================================
ClearHistory PROC
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX

	; Create/truncate file
	MOV  AH, 3CH
	MOV  CX, 0
	LEA  DX, histName
	INT  21H
	JC   ch_error

	MOV  BX, AX
	MOV  AH, 3EH
	INT  21H

	LEA  DX, clearMsg
	CALL PrintString
	LEA  DX, crlf
	CALL PrintString
	JMP  ch_done

ch_error:
	LEA  DX, fileErrMsg
	CALL PrintString
	LEA  DX, crlf
	CALL PrintString

ch_done:
	POP  DX
	POP  CX
	POP  BX
	POP  AX
	RET
ClearHistory ENDP

	END MAIN
