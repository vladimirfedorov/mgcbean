; checks if a pixel can be drawn in an object
;  cf is set if pixel isn't covered with other windows/controls
; in: esi - window structure offset
;     edi - xxxxyyyyh
; out: CF clear if can draw pixel
gfx_chkregion:
	push	eax
	push	ebx
	mov	eax, edi

	cmp	ax, 0
	jb	.dontdraw
	cmp	ax, [esi+WND_HEIGHT]
	jae	.dontdraw

	add	ax, [esi+WND_TOP]
	cmp	ax, 0
	jb	.dontdraw
	cmp	ax, [screen_height]
	jae	.dontdraw

	ror	eax, 16

	cmp	ax, 0
	jb	.dontdraw
	cmp	ax, [esi+WND_WIDTH]
	jae	.dontdraw

	add	ax, [esi+WND_LEFT]
	cmp	ax, 0
	jb	.dontdraw
	cmp	ax, [screen_width]
	jae	.dontdraw

	ror	eax, 16
	; now eax contains screen coordinates xxxxyyyyh

	mov	bx, [esi+WND_Z]
	push	esi
	mov	esi, [wnd_struc]
   .l1:
	cmp	bx, [esi+WND_Z]
	jbe	.next
	ror	eax, 16
	cmp	ax, [esi+WND_TOP]
	jae	.next
	cmp	ax, [esi+WND_BOTTOM]
	ror	eax, 16
	cmp	ax, [esi+WND_LEFT]
	jb	.next
	cmp	ax, [esi+WND_RIGHT]
	jae	.next
	jmp	.dontdraw
   .next:
	add	esi, WND_RECSIZE
	cmp	esi, [wnd_last]
	jbe	.l1

	; everything should be ok..
	clc
	jmp	.exit

   .dontdraw:
	stc

   .exit:
	pop	ebx
	pop	eax
	ret



; convert edi = xxxxyyyyh --> to address
gfx_xy2addr_edi:
	push	ecx

	mov	ecx, edi
	xor	edi, edi
	mov	di, cx
	mov	cl, [screen_shift]
	shl	edi, cl
	shr	ecx, 16
	add	edi, ecx
	add	edi, VIDEO_FB;[screen_buff]

	pop	ecx
	ret

; convert esi = xxxxyyyyh --> to address
gfx_xy2addr_esi:
	push	ecx

	mov	ecx, esi
	xor	esi, esi
	mov	si, cx
	mov	cl, [screen_shift]
	shl	esi, cl
	shr	ecx, 16
	add	esi, ecx
	add	esi, VIDEO_FB;[screen_buff]

	pop	ecx
	ret


; put pixel
; ebx - x
; ecx - y
; edx - color
gfx_putpixel:
	push	edi
	push	ecx

	xor	edi, edi
	mov	di, cx
	mov	cl, [screen_shift]
	shl	edi, cl
	add	edi, ebx
	add	edi, VIDEO_FB;[screen_buff]

	mov	[edi], dl

	pop	ecx
	pop	edi
	ret


; put pixel
; ecx - xxxxyyyyh
; edx - color
gfx_putpixel_ch:
	push	edi
	push	ecx

	xor	edi, edi
	mov	di, cx
	mov	cl, [screen_shift]
	shl	edi, cl
	shr	ecx, 16
	add	edi, ecx
	add	edi, VIDEO_FB;[screen_buff]

	mov	[edi], dl

	pop	ecx
	pop	edi
	ret

; putch
; eax = char
; ebx = x
; ecx = y
; edx = color
gfx_putch:
	pusha

	shl	ebx, 16
	and	ecx, 0ffffh
	add	ecx, ebx

	push	edx
	mov	esi, SYSFONT
	xor	ebx, ebx
	xor	edx, edx
	mov	bl, [SYSFONT_BUF+8]
	mul	ebx
	add	esi, eax
	pop	edx
	xor	eax, eax

	mov	bh, [SYSFONT_BUF+6]

   .lh:
	mov	bl, [SYSFONT_BUF+7]
	lodsb
	push	ecx
   .ll:
	rcl	al, 1
	jnc	@f
	call	gfx_putpixel_ch
    @@:
	add	ecx, 10000h
	dec	bl
	jnz	.ll

	pop	ecx
	inc	ecx
	dec	bh
	jnz	.lh

	popa
	ret

; drawstring
; ebx = x
; ecx = y
; edx = color
; esi = string
gfx_drawstring:
	push	eax
	push	ebx
	push	esi

    @@:
	lodsb
	or	al, al
	jz	@f
	call	gfx_putch
	add	ebx, 8; [SYSFONT_BUF+7]
	jmp	@b
    @@:
	pop	esi
	pop	ebx
	pop	eax

	ret

; copies square region from video memory to buffer
; IN: esi - xxxxyyyy (left*10000h+top)
;     ebx - wwwwhhhh (width*10000h+height)
;     edi - buffer to copy to
gfx_copyregion:
	push	ecx
	push	ebx
	push	esi
	push	edi

	call	gfx_xy2addr_esi
	mov	ecx, ebx
	shr	ecx, 16
	and	ebx, 0ffffh
	cld
   .l1:
	push	ecx
	push	esi

	rep	movsb	; depends on video mode

	pop	esi
	add	esi, [screen_lwidth] ; logical width
	pop	ecx
	dec	ebx
	jnz	.l1

	pop	edi
	pop	esi
	pop	ebx
	pop	ecx
	ret

; pastes square region from buffer to video memory
; IN: edi - xxxxyyyy (left*10000h+top)
;     ebx - wwwwhhhh (width*10000h+height)
;     esi - buffer to copy from
gfx_pasteregion:
	push	ecx
	push	ebx
	push	esi
	push	edi

	call	gfx_xy2addr_edi
	mov	ecx, ebx
	shr	ecx, 16
	and	ebx, 0ffffh
	cld
   .l1:
	push	ecx
	push	edi

	rep	movsb	; depends...

	pop	edi
	add	edi, [screen_lwidth]
	pop	ecx
	dec	ebx
	jnz	.l1

	pop	edi
	pop	esi
	pop	ebx
	pop	ecx
	ret

; draws image with transparent color
; IN: esi - &image
;     ebx - wwwwhhhh (width*10000h+height)
;     edx - transparent color
;     edi - xxxxyyyy (left*10000h+top)
gfx_drawsprite:
	push	ecx
	push	ebx
	push	esi
	push	edi

	call	gfx_xy2addr_edi
	mov	ecx, ebx
	shr	ecx, 16
	and	ebx, 0ffffh
	cld
   .l1:
	push	ecx
	push	edi

   .l2:
	lodsb
	cmp	eax, edx
	jz	.inc_edi
	stosb
	jmp	@f
   .inc_edi :
	inc	edi
    @@:
	loop	.l2

	pop	edi
	add	edi, [screen_lwidth]
	pop	ecx
	dec	ebx
	jnz	.l1

	pop	edi
	pop	esi
	pop	ebx
	pop	ecx
	ret

