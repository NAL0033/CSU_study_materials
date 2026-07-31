.model small
.stack 100h
.data
.data
    x dw 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
    y dw 10, 9, 8, 7, 6, 5, 4, 3, 2, 1
    z dw 10 dup(0)
    logic_rule dw 0DCh
.code
    main proc
start:
    push ds
    mov ax,@data
    mov ds,ax

    mov cx,10
    mov dx,logic_rule

    mov si,0
loop_start:
    mov ax, x[si]
    mov bx, y[si]
    shr dx, 1
    jc subtract
    add ax, bx
    jmp store

subtract:
    sub ax, bx
store:
    mov z[si], ax
    add si, 2
    loop loop_start

    pop ds
    mov ax, 4C00h
    int 21h
main endp
end start