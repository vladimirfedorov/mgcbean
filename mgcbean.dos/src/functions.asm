include 'common.inc'

	



; fdd.readsect(fdd_num, sector_num, *far_ptr)
; 
fdd.readsect:
	push	ax, bx, cx, dx, es
	mov	di, 3  ; retry 3 times

  .try: push	di

	call	fdd.reset
	xor	dx, dx
	div	word [sptrack] ; ax=lba/sptrack, dx=sec. number
	mov	cx, dx	; cl=sec. number
	inc	cx
	xor	dx, dx
	div	word [heads] ; dx - head, ax - cylinder
	mov	ch, al
	mov	dh, dl
	mov	dl, [bootdrv]
	mov	ax, bp ; al = bp
	mov	ah, 2
	int	13h
	pop	di

	jnc	.r_ok

	dec	di
	jnz	.try

	mov	si, err
	call	write
	jmp	$
 .r_ok: 
 	pop	es, dx, cx, bx, ax
	ret

; fdd.reset(fdd_num)
fdd.reset:
	push	ax, bx
	xor 	ax, ax  	; reset disk
	movzx 	bx, [sp+2+2*2]	; ret+2*push 
	int 	13h
	pop	bx, ax
	ret

; ----------------
; returns next file cluster or 0fffh in ax if EOF
; IN: ax - 1st cluster of a file
; OUT: ax - next file cluster, or  0fffh if EOF

fat12.getnextcluster:
	push	bx
	push	dx
	push	si
	push	ds
	mov	bx, 07e0h
	mov	ds, bx
	mov	bx, 2
	xor	dx, dx
	div	bx
	mov	bx, 3
	mul	bl
	mov	si, ax
	lodsw
	ror	eax, 16
	lodsb
	rol	eax, 16
	or	dx, dx
	jz	.exit
	shr	eax, 12
 .exit: and	eax, 00000fffh
	pop	ds
	pop	si
	pop	dx
	pop	bx
	ret

; ----------------
; find file
; IN:  es:di - file name
; OUT: ax = 1st cluster or ax=0FFFFh if file not found
;      si - file entry
fat12.finddir:
	mov	byte[fat12.findfile.cond], 74h ; jnz = 74h
	jmp	fat12.findfile.find
fat12.findfile:
	mov	byte[.cond], 75h ; jz = 45h
 .find: push	cx
	mov	cx, 4096/32 ; - max # of files
	mov	si, 9000h
 .scan: push	di
	push	si
	push	cx
	mov	cx, 0bh
	repe	cmpsb
	pop	cx
	pop	si
	pop	di
	je	.found
 .c1:	add	si, 20h     ; go to the next entry
	cmp	byte[si],0  ; last dir entry
	je	.notfnd
	loop	.scan
 .notfnd:
	mov	ax, 0ffffh
	jmp	.exit

 .found:
	test	byte[si+0bh],10h ; subdirectory bit
 .cond: jz	.c1		; jz = 74h, jnz = 75h
	mov	ax, [si+1ah]	; 1st cluster of the file
				; ax - 1st cluster of file
 .exit:
	pop	cx
	ret

; ----------------
; Load file into memory
; IN: ax - 1st cluster
;     bx - where to load (seg)
;     cx - # of secs - 1 to read (within); 1 - 1 sect, 0 - 64k sect.

fat12.loadfile:

	push	es
	push	cx
	mov	es, bx
	xor	bx, bx
	mov	bp, 1
.readf: push	ax
	add	ax, 31
	call	readsect
	pop	ax
	call	fat12.getnextcluster
	add	bx, 200h

	cmp	bx, 0
	jne	.c1
	mov	bx, es
	add	bx, 1000h
	mov	es, bx
	xor	bx, bx
   .c1: cmp	ax, 0ff8h
	jae	.exit
	loop	.readf
 .exit: pop	cx
	pop	es
	ret


; ----------------
cnosole.write:
	lodsb
	or	al, al
	jz	.msgend
	mov	ah, 0eh
	mov	bx, 0007h
	int	10h
	jmp	write
    .msgend:
	ret


