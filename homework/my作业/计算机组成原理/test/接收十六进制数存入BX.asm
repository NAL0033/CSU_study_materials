.model small
.data
.stack 100h
.code
main proc far
   start:
         mov ax,@data
         mov ds,ax
         mov bx,0
    newchar:
         mov ah,01h
         int 21h
         cmp al,'0'
         jl exit
         cmp al,'9'
         jle done
         cmp al,'a'
         jl exit
         cmp al,'f'
         jg exit
         sub al,27h
    done:
         sub al,30h
         mov cl,4
         shl bx,cl
         mov ah,0
         add bx,ax
         jmp newchar
    exit:
        mov ah,4ch
        int 21h
main endp
end start