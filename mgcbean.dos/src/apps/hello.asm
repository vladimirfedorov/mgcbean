	org	100h
	mov	ah, 09
	mov	dx, hello
	int	21h

        ;int	20h	; exit com
       
        ;ret		; the same

        push	0
        push 	10

        mov	ax, 4c00h
        int	21h	; again the same

hello	db "Hello world!$"