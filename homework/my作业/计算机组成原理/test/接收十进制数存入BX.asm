.model small
.data
.stack 100h
.code
main proc far
    start:
        mov bx,0
    newchar:
        mov ah,1h
        int 21h
        sub al,30h
        jl exit
        cmp al,9
        jg exit
        mov cx,10
        xchg ax,bx
        mul cx
        add ax,bx
        xchg ax,bx
        jmp newchar
    exit:
       mov ah,4ch
       int 21h
main endp
  end start