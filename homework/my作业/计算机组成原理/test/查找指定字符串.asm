.model small
.data
    mess db'COMPUTER'
.stack 100h
.code
main proc FAR
    start:
       lea di,mess
       mov al,'T'
       mov cx,8
       CLD
       repne scasb
       mov ah,4ch
       int 21h
main endp
    end start