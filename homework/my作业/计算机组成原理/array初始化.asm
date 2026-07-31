data segment
     arr db 100 dup(?)
data ends

sseg segment
sseg ends

code segment
           assume cs:code,ds:data,ss:sseg
        start:
           mov ax,data
           mov ds,ax;起始地址
           lea si,arr

           mov cx,100
           sub dl,dl
        main:
           mov [si],dl
           inc si
           inc dl
           loop main

           mov ah,4ch
           int 21h
code ends
end start