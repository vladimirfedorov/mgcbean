; mouse commands:
; E6h reset scaling
; E7h scaling 2:1
; E8h set resolution
; E9h status request
; EAh set stream mode
; EBh read data
; ECh reset wrap mode
; EDh set wrap mode
; F0h set remote mode
; F2h read device type
; F3h set sampling rate
; F4h enable
; F5h disable
; F6h set default
; FEh resend
; FFh reset

; mouse functions

IRQ12_Init:

	call	mouse_wait8042empty
	mov	al, 0a8h
	out	64h, al
	call	mouse_waitdata

	; enable mouse
	mov	al, 0f4h
	call	mouse_senddata
	call	mouse_getdata

	; enable mouse interrupt
	call	mouse_wait8042empty
	mov	al, 020h
	out	64h, al
	in	al, 60h
	mov	ah, al
	call	mouse_wait8042empty
	mov	al, 060h
	out	64h, al
	mov	al, ah
	or	al, 10b
	out	60h, al

	; enable mouse task
	mov	esi, IRQ12_struc
	call	add_sys_task

	mov	dx, ax
	mov	eax, 32+12	; 20h exceptions +0Ch
	call	set_idt_task

	xor	eax, eax
	mov	word [mouse_byte_cnt], ax
	mov	[mouse_B], al
	mov	[mouse_xB], al
	mov	[mouse_Z], ax

	mov	ax, [screen_width]
	shr	ax, 1
	mov	[mouse_X], ax

	mov	ax, [screen_height]
	shr	ax, 1
	mov	[mouse_Y], ax

	mov	byte  [mouse_max_bytes], 3


	ret

; driver task structure
align 4
IRQ12_struc:
	dd	IRQ12
	dd	IRQ12_End - IRQ12
	dd	4096
	dd	mouse_name
	dd	0,0


; PS/2 mouse driver
align 4
IRQ12:
	cli
	call	mouse_wait8042empty
	xor	eax, eax
	in	al, 60h
	cbw

	mov	bx, word [mouse_byte_cnt] ; bh = mouse_max_bytes

	cmp	bl, 0
	ja	.b1

	; syncronization test
	test	al, 1000b
	jnz	.ok
	; syncronization error
	; wait for the byte
	mov	bl, -1
	jmp	.ready
   .ok: ; the 1st byte indeed


	mov	[mouse_B], al
	jmp	.ready
   .b1:
	cmp	bl, 1
	ja	.b2
	add	[mouse_X], ax
	jmp	.ready
   .b2:
	cmp	bl, 2
	ja	.b3
	sub	[mouse_Y], ax
	jmp	.ready
   .b3:
	cmp	bl, 3
	ja	.b4
	mov	[mouse_xB], al
	and	al, 0fh
	add	[mouse_Z], ax
	jmp	.ready
   .b4:
	; more than 3 bytes
  .ready:

	mov	ax, [mouse_X]
	cmp	ax, 0
	jge	@f
	xor	ax, ax
    @@: cmp	ax, [screen_width]
	jl	@f
	mov	ax, [screen_width]
    @@: mov	[mouse_X], ax

	mov	ax, [mouse_Y]
	cmp	ax, 0
	jge	@f
	xor	ax, ax
    @@: cmp	ax, [screen_height]
	jl	@f
	mov	ax, [screen_height]
    @@: mov	[mouse_Y], ax

	inc	bl
	cmp	bl, bh
	jb	@f
	xor	bl, bl
    @@:
	mov	[mouse_byte_cnt], bl


	call	cursor_restore
	call	cursor_save
	call	cursor_draw

  .exit:
	mov	al, 20h
	out	0a0h, al
	out	20h, al
	sti

	iret
	jmp	IRQ12
align 4

mouse_byte_cnt	db 0
mouse_max_bytes db 0

mouse_name db 'mouse',0

; system variables
; mouse_B         db ?
; mouse_xB        db ?
; mouse_X         dw ?
; mouse_Y         dw ?
; mouse_Z         dw ?


; send mouse a byte
; IN:  al
mouse_senddata:

	push	eax
	call	mouse_wait8042empty
	mov	al, 0d4h	; send mouse
	out	64h, al
	call	mouse_wait8042empty

	pop	eax
	out	60h, al

	ret

; get mouse data
; OUT: al
mouse_getdata:

	call	mouse_waitdata
	in	al, 60h
	ret

; wait kbd buffer is empty
mouse_wait8042empty:

	push	ecx
	xor	ecx, ecx
	not	cx
    @@:
	in	al, 64h
	test	al, 10b
	loopnz	@b

	pop	ecx
	ret

; wait mouse data
mouse_waitdata:

	push	ecx
	xor	ecx, ecx
	not	cx
    @@:
	in	al, 64h
	test	al, 100000b
	loopz	@b
	pop	ecx
	ret

IRQ12_End:


; -----------------------------------------------------------------------------
; mouse cursor subroutines
; cursor area 32x32
; restore - save - draw
; -----------------------------------------------------------------------------

; cursor memory and pointer primary initialization
cursor_init:
	; here special kmalloc should be used
	ret

; save screen image under the cursor
cursor_save:
	push	eax
	push	esi
	push	edi

	mov	eax, dword [mouse_X]	      ; saves both X and Y
	mov	dword [csr_oldx], eax

	xor	esi, esi
	mov	si, [mouse_X]
	shl	esi, 16
	mov	si, [mouse_Y]
	mov	edi, cursor_old
	mov	ebx, 080008h
	call	gfx_copyregion

	pop	edi
	pop	esi
	pop	eax
	ret

; draw mouse cursor
cursor_draw:
	push	ecx
	push	edx

	mov	di, [mouse_X]
	shl	edi, 16
	mov	di, [mouse_Y]
	mov	edx, 0
	mov	ebx, 080008h
	mov	esi, cursor_data
	call	gfx_drawsprite



	pop	edx
	pop	ecx
	ret

; resore previous image under the mouse cursor
cursor_restore:
	push	eax
	push	edi
	push	esi

	xor	edi, edi
	mov	di, [csr_oldx]
	shl	edi, 16
	mov	di, [csr_oldy]
	mov	esi, cursor_old
	mov	ebx, 080008h
	call	gfx_pasteregion

	pop	esi
	pop	edi
	pop	eax
	ret

cursor_data:
	db	63, 0, 0, 0, 0, 0, 0, 0
	db	63,63, 0, 0, 0, 0, 0, 0
	db	63,63,63, 0, 0, 0, 0, 0
	db	63,63,63,63, 0, 0, 0, 0
	db	63,63,63,63,63, 0, 0, 0
	db	63, 0,63,63, 0, 0, 0, 0
	db	 0, 0, 0,63,63, 0, 0, 0
	db	 0, 0, 0,63,63, 0, 0, 0


cursor_old:
	dd	0,0,0,0,0,0,0,0 , 0,0,0,0,0,0,0,0 , 0,0,0,0,0,0,0,0 , 0,0,0,0,0,0,0,0