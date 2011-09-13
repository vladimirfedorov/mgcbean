; view mwmory dump

	org 100h

	push	fs

	push	ds
	pop	fs
	xor	si, si

	; Read command line

	cmp	byte [si+(80h+13)], '0' ; anything?
	jb	.noparam


	mov	si, 80h+13	; 'memdump.com '
	call	convert
	mov	fs, ax

	mov	si, 80h+18	; 'memdump.com xxxx:'
	call	convert
	mov	si, ax


 .noparam:

	mov	cx, 8	; number of lines
  .l1:
	call	showmem
	add	si, 16
	loop	.l1

	pop	fs

	mov	ax, 4c00h
	int	21h


num	db	"15B7";

; string to number
; in:  si - 4-byte buffer with a number (e.g., '1f00')
; out: ax - value
convert:
	push	si
	push	cx
	push	dx
	mov	cx, 4
	xor	dx, dx
  .l1:
	xor	ax, ax
	lodsb

	sub	al, 30h
	cmp	al, 9
	jna	@f
	sub	al, 7	; 42h ('A')
	cmp	al, 15
	jna	@f
	sub	al, 20h ; for lower case letters
    @@:
	shl	dx, 4
	add	dx, ax

	loop	.l1

	mov	ax, dx
	pop	dx
	pop	cx
	pop	si
	ret

; display  a string
; in: si - string to display
write:
	pusha
    .nextb:
	lodsb
	or	al, al
	jz	.msgend
	mov	ah, 0eh
	mov	bx, 0007h
	int	10h
	jmp	.nextb
    .msgend:
	popa
	ret


; display value in ax
; in: ax - number
writeax:
	pusha
	mov	cx, 4
 .hloop:
	rol	ax, 4
	push	ax
	and	al, 0Fh
	cmp	al, 0Ah
	sbb	al, 69h
	das
	mov	ah, 0eh
	mov	bx, 0007h
	int	10h
	pop	ax
	loop	.hloop
	popa
	ret


; display memory region
; IN: fs:si= address
showmem:
	push	ax
	push	bx
	push	cx
	push	si

	push	si
	mov	ax, fs
	call	writeax
	mov	si, scsp
	call	write
	pop	si

	push	si
	mov	ax, si
	call	writeax
	mov	si, scsp
	call	write
	mov	si, space
	call	write
	pop	si

	mov	cx, 16
 .mloop:
	;lodsb
	mov	al, [fs:si]
	inc	si
	jnz	@f

	mov	bx, fs
	add	bh, 10h
	mov	fs, bx
   @@:
	push	cx
	mov	cx, 2
 .hloop:
	rol	al, 4
	push	ax
	and	al, 0Fh
	cmp	al, 0Ah
	sbb	al, 69h
	das
	mov	ah, 0eh
	mov	bx, 0007h
	int	10h
	pop	ax
	loop	.hloop

	mov	ax, 0e20h
	mov	bx, 0007h
	int	10h
	pop	cx
	loop	.mloop

	mov	si, crlf
	call	write

	pop	si
	pop	cx
	pop	bx
	pop	ax
	ret

crlf		db 13,10,0
scsp		db ":",0
space		db " ",0
