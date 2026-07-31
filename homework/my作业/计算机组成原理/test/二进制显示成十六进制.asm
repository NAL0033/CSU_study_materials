.model small
.code
main proc far
start:
    mov bx,1101010100010010b
    mov ch,4
rotate:
    mov cl,4
    rol bx,cl
    mov al,bl
    and al,0fh
    add al,30h
    cmp al,3ah
    jl print
    add al,7h
print:
    mov dl,al
    mov ah,2h
    int 21h
    dec ch
jnz rotate
    mov ah,4ch
    int 21h
main endp
end start