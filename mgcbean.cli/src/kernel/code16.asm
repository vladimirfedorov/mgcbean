; ==============================================================
; Read fd to memory
; ==============================================================

readfdd:
	mov	si, loadingmsg-$$
	call	write-$$
	mov	ah, 3
	mov	bh, 0
	int	10h
	sub	dl, 21	; inside progress bar
	mov	ah, 2
	int	10h

	call	reset-$$
	push	es

	mov	cx, 2880
	mov	ax, 0
 .next: pusha

	pusha
	mov	ax, cx
	xor	dx, dx
	mov	bx, 2880/20
	div	bx
	or	dx, dx
	jnz	.skip-$$
	mov	si, pt-$$
	call	write-$$
 .skip: popa

	push	word 08000h	; where to read to - use gr.card mem
	pop	es		; 8000:0000h
	xor	bx, bx

	mov	di, 5  ; retry 5 times
  .try: push	ds
	xor	dx, dx
	mov	ds, dx
	div	word [ds:7c00h+18h] ; ax=lba/sptrack, dx=sec. number
	mov	cx, dx	; cl=sec. number
	inc	cx
	xor	dx, dx
	div	word [ds:7c00h+1ah] ; dx - head, ax - cylinder
	mov	ch, al
	mov	dh, dl
	mov	dl, [ds:7c00h+24h]
	mov	ax, 0201h
	int	13h
	pop	ds
	jnc	.r_ok-$$

	call	reset-$$
	dec	di
	jnz	.try-$$

	mov	si, 1000h
	mov	ds, si
	mov	si, dsk_err-$$
	call	write-$$
	jmp	$-$$

 .r_ok:
	pusha
	mov	ax, 8700h
	mov	cx, 512/2
	push	word 1000h
	pop	es
	mov	si, umgdt-$$
	int	15h
	jnc	.c1-$$
	cmp	ah, 0
	je	.c1-$$
;        jmp     .c1             ;
	mov	si, 1000h
	mov	ds, si
	mov	si, mem_err-$$
	call	write-$$
	jmp	$-$$
   .c1: add	dword[es:umgdt-$$+1ah],512
	popa

	popa
	add	ax, 1;64/4
	dec	cx
	jnz	.next-$$	; loop .next (out of range)

	pop	es

; turn fdd motor off

	mov	dx, 03f2h
	out	dx, al



; ==============================================================
; Init VESA fuctions
; ==============================================================

	push	ds
	push	es
  ; get vesa version information
	mov	ax, (VESA_INFO/10h) ; segment
	mov	es, ax
	xor	di, di
	mov	ax, 4F00h
	int	10h

  ; get default mode information
	mov	ax, (VESA_MODE/10h) ; segment
	mov	es, ax
	xor	di, di
	mov	cx, GUI_MODE
	mov	ax, 4F01h
	int	10h

	xor	di, di
	mov	ax, [es:di]
	or	ax, 1		; mode supported?
	jnz	@f-$$

	mov	si, gui_err-$$
	call	write-$$
	jmp	$-$$

    @@: or	ax, 10000000b	; lfb supported?
	jnz	@f-$$

	mov	si, gui_err-$$
	call	write-$$
	jmp	$-$$

    @@:
	push	es	; mode info
	pop	ds

	mov	ax, (SYS_VARS/10h)
	mov	es, ax
	mov	di, (screen_buff - SYS_VARS)

  ; ds:si - default mode information
  ; es:di - system screen info

	mov	si, 28h
	movsd
	mov	si, 19h
	movsb
	xor	al, al
	stosb
	mov	ax, GUI_MODE
	stosw
	mov	si, 12h
	movsw
	movsw


	pop	es
	pop	ds

  ; hide cursor
	mov	ax, 2
	mov	bx, 19h
	int	10h

  ; entering default graphic mode

	mov	ax, 4F02h
	mov	bx, GUI_MODE
	;int     10h

  ; setting logical width

	mov	ax, 4f06h
	mov	bl, 0
	mov	cx, GUI_MODE_WIDTH
	;int     10h

  ; save parameters
	mov	ax, (SYS_VARS/10h)
	mov	es, ax

	mov	di, (screen_shift-SYS_VARS)
	mov	ax, GUI_MODE_WIDTH
	stosw

	mov	di, (screen_shift-SYS_VARS)
	mov	al, GUI_MODE_SHIFT
	stosb

	mov	di, (screen_lwidth-SYS_VARS)
	mov	ax, GUI_MODE_WIDTH
	stosw
; ==============================================================
; ready to start
; ==============================================================

	jmp	continue_booting-$$

loadingmsg	db "Loading system, please wait... [                    ]",0
pt		db 0feh,0
mem_err 	db "Memory error",0
dsk_err 	db "Disk read error",0
gui_err 	db "Default video mode is not supported",0
lfb_err 	db "LFB is not supported",0

umgdt:
times 16 db 0
dw	01ffh	       ; 32 k
db	00,00,08h,93h  ; source: 080000h
dw	0
dw	0ffffh
db	00,00,(RAMDRV_BASE/10000h),93h	; destination
dw	0
times 18 db 0

; -----------------------------------
; write
; IN: ds:si - string to write
write:
	push	bx
	lodsb
	or	al, al
	jz	.msgend-$$
	mov	ah, 0eh
	mov	bx, 0007h
	int	10h
	jmp	write+1-$$
    .msgend:
	pop	bx
	ret

reset:
	pusha
	xor	ax, ax	; reset disk
	mov	bx, 0
	int	13h
	popa
	ret

 continue_booting: