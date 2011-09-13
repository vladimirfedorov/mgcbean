; put white pixel 8-bit mode
; debug text output routines
; ebx - x
; ecx - y
; edx - color
_Dbg_PutPixel8XY:
	push	edi
	push	ecx

	xor	edi, edi
	mov	di, cx
	mov	cl, [screen_shift]
	shl	edi, cl
	add	edi, ebx
	add	edi, [screen_buff]

	mov	[edi], dl

	pop	ecx
	pop	edi
	ret

; ebx - x, ecx - y
_Dbg_PrintCh8XY:
	pusha
	mov	esi, letterA
	xor	eax, eax
	mov	ax, [screen_width]
	mul	ecx
	add	eax, ebx
	mov	edi, [screen_buff]
	add	edi, eax

	xor	ecx, ecx
	mov	ebx, ecx
	mov	bl, 8
   .l0:
	mov	cl, 8
	lodsb
   .l1:
	rcl	al, 1
	jnc	@f
	mov	[edi], byte 63
    @@: inc	edi
	loop	.l1
	add	edi, 640-8
	dec	bl
	jnz	.l0

	popa
	ret


_Dbg_PutPixel:

	ret

__putpixel_lfb_8:

	ret

__putpixel_lfb_15:

	ret

__putpixel_lfb_16:

	ret

__putpixel_lfb_24:

	ret

__putpixel_lfb_32:

	ret


_Dbg_PrintCh:

	ret

_Dbg_Print:

	ret

_Dbg_GetCh:

	ret

_Dbg_GetMouseXY:

	ret

_Dbg_GetMouseClick:

	ret


