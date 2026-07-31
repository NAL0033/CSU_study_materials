.model small
.stack 100h
.data 
    x dw ?
    array_head dw 3,5,15,23,37,49,52,65,78,99
    array_end dw 105
    n dw 32
.code
    main proc far
        start:
            mov ax,@data
            mov ds,ax
            lea si,array_head
            mov ax,n
            mov array_head-2,0ffffh 
            mov si,0
        next:
            cmp array_end[si],ax
            jle insert
            mov bx,array_end[si]
            mov array_end[si+2],bx
            sub si,2
            jmp next

        insert:
            mov array_end[si+2],ax
            ret
    main endp
    end start