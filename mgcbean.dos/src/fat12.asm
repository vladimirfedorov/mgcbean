fat12.sectors	dw 9	; sectors
fat12.offset	dw 19	;
fat12_dirsize	dw 4096


; read fat12 block (4096 bytes) starting from n sector
; fat12.read(n)
fat12.read:
	push	ax, cx, di
	
	mov	cx, 9*512/2
	xor	ax, ax
	mov	di, FAT_buffer
	rep	stosw
	
	ccall	fdd.readsect, 1, 9, ds, FAT_buffer
	
	pop	di, cx, ax
	ret

fat12.readdir:
	push	ax, cx, di
	
	mov	cx, 4096/2
	xor	ax, ax
	mov	di, FAT_dir
	rep	stosw

	ccall	fdd.readsect, 19, 1, ds, FAT_dir

	pop	di, cx, ax
	ret

; fat12.findfile(*fname)
; returns 1st file cluster
fat12.findfile:
	push	es,di,bp
	mov	bp, sp
	add	bp, (2+2*3)
	
	mov	ax, [bp]
	mov	es, ax
	mov	di, [bp+2]
	
	call	fat12_findfile
	
	pop	bp,di,es
	ret

; fat12.findfile(*fname)
; returns 1st file cluster
fat12.finddir:
	push	es,di,bp
	mov	bp, sp
	add	bp, (2+2*3)
	
	mov	ax, [bp]
	mov	es, ax
	mov	di, [bp+2]
	
	call	fat12_finddir
	
	pop	bp,di,es
	ret


; fat12.readfile()
fat12.readfile:

	
	ret

; fat12.cd(*dirname)
fat12.cd:
	push	bx, di, bp, ds, es
	mov	bp, sp
	add	bp, (2+2*5)
	mov	di, [bp]

	call	fat12_finddir
	
;       ccall   console.writehex, ax
;       ccall   console.writech, 13
;       ccall   console.writech, 10
	
	cmp	ax, -1
	je	.exit

	cmp	ax, 0	; ".." points to a root dir
	jne	@f
	call	fat12.readdir
	mov	ax, 4096
	mov	[fat12_dirsize], ax
	jmp	.exit
    @@:
	push	ax
	mov	ax, [si+28]
	mov	[fat12_dirsize], ax
	pop	ax

	ccall	bytes.fill, ds, FAT_dir, 0, 4096
	
	;mov    bx, 0900h
	xor	ebx, ebx
	mov	bx, ds
	shl	ebx, 4
	add	bx, FAT_dir 
	shr	ebx, 4
	
	mov	cx, 8
	call	fat12_loadfile

  .exit:
	pop	es, ds, bp, di, bx
	ret
	


; ----------------
; returns next file cluster or 0fffh in ax if EOF
; IN: ax - 1st cluster of a file
; OUT: ax - next file cluster, or  0fffh if EOF

fat12_getnextcluster:
	push	bx
	push	dx
	push	si
	push	ds
	
	xor	ebx, ebx
	mov	bx, ds
	shl	ebx, 4
	add	bx, FAT_buffer
	shr	ebx, 4		; segment
	
	mov	ds, bx		; ds=FAT12 entities
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
; Load file into memory
; IN: ax - 1st cluster
;     bx - where to load (seg)
;     cx - # of secs - 1 to read (within); 1 - 1 sect, 0 - 64k sect.

fat12_loadfile:

	push	es
	push	cx
	mov	es, bx
	xor	bx, bx
	mov	bp, 1
.readf: push	ax
	add	ax, 31
	call	fdd_readsect
	pop	ax
	call	fat12_getnextcluster
	
;        ccall   console.writehex, ax
;        ccall   console.writech, ' '
	
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

;        ccall   console.writech, 13
;        ccall   console.writech, 10

	ret


; ----------------
; find file
; IN:  es:di - file name
; OUT: ax = 1st cluster or ax=0FFFFh if file not found
;      si - file entry

fat12_finddir:
 .find: push	cx
	mov	cx, 4096/32 ; - max # of files
	mov	si, FAT_dir
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

fat12_findfile:
 .find: push	cx
	mov	cx, 4096/32 ; - max # of files
	mov	si, FAT_dir
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
 .cond: jnz	.c1		; jz = 74h, jnz = 75h
	mov	ax, [si+1ah]	; 1st cluster of the file
				; ax - 1st cluster of file
 .exit:
	pop	cx
	ret	
	
; ds:si - filename (e.g. "read.me",0)
; es:di - filename plate - eleven spaces ("           ");
fat12_preparefilename:
	push	ax, dx, cx, di, si

	mov	dx, di

	mov	al, ' '
	mov	cx, 11
	rep	stosb

	mov	di, dx
	add	dx, 8
	mov	cx, 8

	cmp	byte [si], "."
	jne	.name
	movsb
	cmp	byte [si], "."
	jne	.exit
	movsb
	jmp	.exit	


    .name:
	lodsb
	cmp	al, "."
	je	.copyext
	cmp	al, 0
	je	.exit
	stosb
	loop	.name
    .copyext:
	cmp	byte [si], "."	; for 8-ch f names
	jne	@f
	inc	si
    @@:
	mov	di, dx
	mov	cx, 3
    .ext:
	lodsb
	cmp	al, 0
	je	.exit
	stosb
	loop	.ext
    .exit:	
	pop	si, di, cx, dx, ax
	ret	
	
	