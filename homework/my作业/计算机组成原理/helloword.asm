.model small
.stack 100h
.data
    num dw 100101111000b   ; 0978h
.code
main proc
    mov ax, @data
    mov ds, ax

    mov ax, num
    mov cl, 4              ; 左移4位
    mov ch, 4             ; 3次

next:
    rol ax, cl             ; 把高4位循环移到低4位
    push ax                ; 保存 ax
    and al, 0Fh            ; 取低4位

    add al, 30h
    cmp al, 3Ah
    jle ok
    add al, 7h
ok:
    mov dl, al
    mov ah, 2
    int 21h

    pop ax                 ; 恢复 ax（rol 已经完成移位）
    dec ch
    jnz next

    mov ah, 4Ch
    int 21h
main endp
end main