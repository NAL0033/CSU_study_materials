.model small
.stack 100h
.data
    List dw 5,10,20,30,40,50
    target dw 30
.code
main proc near
    start:
    mov ax,@data
    mov ds,ax
    mov es,ax

    mov di,offset List
    mov ax,target
    mov cx,[List]
    add di,2
    cld 
    find:
    repne scasw
    jne not_found
    cmp cx,0
    je finish
delete:
    mov bx,es:[di]
    mov es:[di-2],bx
    add di,2
    loop delete
finish:
    dec [List]
not_found:
    ret
main endp
end start
    