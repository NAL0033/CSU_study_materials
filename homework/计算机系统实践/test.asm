.MODEL SMALL
.STACK 100H

.DATA
msg1    DB '=======================',13,10,'$'
msg2    DB '  ASM test is running!  ',13,10,'$'
msg3    DB '  Hello, World!         ',13,10,'$'
msg4    DB '=======================',13,10,'$'
msg5    DB 13,10,'Press any key to exit...$'

.CODE
MAIN PROC
    MOV AX,@DATA
    MOV DS,AX

    LEA DX,msg1
    MOV AH,09H
    INT 21H

    LEA DX,msg2
    MOV AH,09H
    INT 21H

    LEA DX,msg3
    MOV AH,09H
    INT 21H

    LEA DX,msg4
    MOV AH,09H
    INT 21H

    LEA DX,msg5
    MOV AH,09H
    INT 21H

    ; Wait for key press
    MOV AH,01H
    INT 21H

    ; Exit to DOS
    MOV AX,4C00H
    INT 21H
MAIN ENDP
END MAIN