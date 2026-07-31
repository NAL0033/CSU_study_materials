.model small
.stack 100h
.data
    addr dw number
    number dw 'Y'
    count dw ?
.code
main proc far
  start:
    push ds
    sub ax,ax
    push ax
    mov ax, @data
    mov ds, ax
    mov cx, 0
    mov bx, offset addr
    mov ax,[bx]
repeat:
    test ax, 0ffffh
    jz exit
    jns shift
    inc cx
shift:
    shl ax,1
    jmp repeat
exit:
    mov count,cx
    mov dx, count
    mov ax,2h
    int 21h
    mov ax,4C00h
    int 21h
    ret
main endp
end start