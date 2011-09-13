; fdd.readsect(LBAnum, sectors, seg, offset)
fdd.readsect:
	push	ax, bx, es, bp
	mov	bp, sp
	add	bp, (2+2*4)
	mov	ax, [bp+4]
	mov	es, ax
	mov	bx, [bp+6]
	mov	ax, [bp]
	mov	bp, [bp+2]
	
	call	fdd_readsect

	pop	bp, es, bx, ax
	ret

fdd.spfat	dw 9
fdd.sptrack	dw 12h
fdd.drive	db 0
fdd.heads	dw 2

fdd.cantread	db "Can't read FDD", 0

; ----------------
; readsec - read sector
; in: es:bx - buffer for a sector
;     ax - LBA # of sector (0-2879)
;     bp - number of sectors to read (1-255)


fdd_readsect:
	pusha
	mov	di, 3  ; retry 3 times

  .try: push	di

	call	fdd_reset
	xor	dx, dx
	div	word [fdd.sptrack] ; ax=lba/sptrack, dx=sec. number
	mov	cx, dx	; cl=sec. number
	inc	cx
	xor	dx, dx
	div	word [fdd.heads] ; dx - head, ax - cylinder
	mov	ch, al
	mov	dh, dl
	mov	dl, [fdd.drive]
	mov	ax, bp ; al = bp
	mov	ah, 2
	int	13h
	pop	di

	jnc	.r_ok

	dec	di
	jnz	.try

	;mov    si, err
	;call   write
	;jmp    $
 .r_ok: popa
	ret

fdd_reset:
	push	ax, bx
	xor	ax, ax		; reset disk
	mov	bh, ah
	mov	bl, [fdd.drive]  
	int	13h
	pop	bx, ax
	ret
