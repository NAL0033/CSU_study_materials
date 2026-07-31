.model small
.stack 100h
.data
    num dw 3456h
.code
main proc far
    start:
    mov ax,@data
    mov ds,ax
    