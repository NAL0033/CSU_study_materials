data SEGMENT
    X dw 1234H
    Y dw 2345H
    Z dw -1234H
    w dw ?
data ENDS

stack SEGMENT
stack ENDS

code SEGMENT
    assume ds:data,ss:stack,cs:code
    main:
    mov ax,data
    mov ds,ax

    mov ax,X
    cmp ax,Y
    jge done;ax>=y
    mov ax,Y;x<y
done:
    cmp ax,Z
    jge done2;ax>=z
    mov ax,Z;ax<z
done2:
    mov w,ax

    mov ah,4CH
    INT 21H 
code ENDS
END main
