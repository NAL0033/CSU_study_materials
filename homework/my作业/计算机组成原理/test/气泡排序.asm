.model small
.data
    array db 32,85,16,15,8
.stack 100h
.code
main proc far
  start:
       mov ax,@data
       mov ds,ax
       mov cx,length array
       dec cx
    loop1:
       mov bx,cx
       mov si,0
    loop2:
       mov al,array[si]
       cmp array[si+1],al
       jg nochange
       mov dl,array[si+1]
       mov array[si],dl
       mov array[si+1],al
    nochange:
       inc si
       dec bx
    jnz loop2
       dec cx
    jnz loop1
    mov ah,4ch
    int 21h 
main endp
end start