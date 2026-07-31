.model small
.data
    x dw ?
    array_head dw 3,5,15,23,37,49,52,65,78,99
    array_end dw 105
    n dw 32
.stack 100h
.code
main proc far
    start:
        mov ax,@data
        mov ds,ax
        mov si,0
        mov cx,10
        mov ax,n
        cmp ax,array_end[si]
        jg insert_end
        mov bx,array_end[si]
        mov array_end[si+2],bx
    insert_loop:
        sub si,2
        cmp ax,array_end[si]
        jg insert_end
        mov bx,array_end[si]
        mov array_end[si+2],bx
        loop insert_loop
    insert_end:
        mov array_end[si+2],ax
    exit:
        mov ax,4C00h
        int 21h
main endp
end start