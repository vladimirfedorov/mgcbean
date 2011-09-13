; keyboard interrupt handler

SCANBUF_SIZE	equ 32	; buffer size (for 2-byte scancodes)
SCANBUF_MASK	equ 1Fh ; size mask (1Fh - 32)

IRQ01_Init:
; modifies esi, eax, edx
	mov	esi, IRQ01_struc
	call	add_sys_task
	mov	dx, ax
	mov	eax, 32+1
	call	set_idt_task

	mov	eax, SCANBUF_SIZE
	call	sys_malloc
	mov	[ksb_start], eax
	mov	[ksb_head], eax
	mov	[ksb_tail], eax
	add	eax, SCANBUF_SIZE
	dec	eax
	mov	[ksb_end], eax
	ret


align 4
IRQ01_struc:
	dd IRQ01
	dd IRQ01_End - IRQ01
	dd 4096
	dd keyb_name
	dd 0,0



align 4
IRQ01:

	cli

	xor	eax, eax
	in	al, 60h

	cmp	al, 0E1h	; 3-byte scancode
	jne	@f
	mov	[ext_scan], al
	mov	[kbd_scwait], 2 ; wait for 2 bytes
	jmp	.exit

   @@:	cmp	al, 0E0h	; 2-byte scancode
	jne	@f
	mov	[ext_scan], al
	mov	[kbd_scwait], 1 ; wait for 1 more byte
	jmp	.exit

   @@:	cmp	[kbd_scwait], 2
	jne	@f
	dec	[kbd_scwait]
	jmp	.exit

   @@:	mov	ah, [ext_scan]

	; catch some special codes
	; caps lock
	cmp	al, 3Ah
	jne	@f
	xor	byte [kbd_state], 4
	call	kbd_setled

	; num lock
   @@:	cmp	al, 45h
	jne	@f
	xor	byte [kbd_state], 2
	call	kbd_setled

	; scroll lock
   @@:	cmp	al, 46h
	jne	@f
	xor	byte [kbd_state], 1
	call	kbd_setled

	; Ctrl pressed
   @@:	cmp	al, 1Dh
	jne	@f
	or	byte [kbd_state], 10000000b

	; Ctrl released
   @@:	cmp	al, 9dh
	jne	@f
	and	byte [kbd_state], 01111111b

	; Alt pressed
   @@:	cmp	al, 38h
	jne	@f
	or	byte [kbd_state], 01000000b

	; Alt released
   @@:	cmp	al, 0b8h
	jne	@f
	and	byte [kbd_state], 10111111b

	; Left shift pressed
   @@:	cmp	al, 2ah
	jne	@f
	or	byte [kbd_state], 00100000b

	; Left shift released
   @@:	cmp	al, 0aah
	jne	@f
	and	byte [kbd_state], 11011111b

	; Right shift pressed
   @@:	cmp	al, 36h
	jne	@f
	or	byte [kbd_state], 00100000b

	; Right shift released
   @@:	cmp	al, 0b6h
	jne	@f
	and	byte [kbd_state], 11011111b

	; Left Win pressed
   @@:	cmp	al, 5bh
	jne	@f
	or	byte [kbd_state], 00010000b

	; Left Win released
   @@:	cmp	al, 0dbh
	jne	@f
	and	byte [kbd_state], 11101111b

	; Right Win pressed
   @@:	cmp	al, 5ch
	jne	@f
	or	byte [kbd_state], 00010000b

	; Right Win released
   @@:	cmp	al, 0dch
	jne	@f
	and	byte [kbd_state], 11101111b

	; These scancodes are for kernel only
	; Ctrl+Alt+Del check
   @@:	cmp	al, 52h
	jne	@f
	mov	dl, [kbd_state]
	and	dl, 11000000b
	cmp	dl, 11000000b
	jne	@f
	call	OnCtrlAltDel
	jmp	.exit

   @@:
	; everything checked
	call	kbd_putscan
	mov	word [ext_scan], 0	; clear both ext and scwait

  .exit:

	in	al,61H
	mov	ah,al
	or	al,80h
	out	61H,al
	xchg	ah,al
	out	61H,al

	push	eax
	mov	al, 20h
	out	20h, al
	pop	eax
	sti

	iret

	jmp IRQ01


align 4

ksb_start	dd 0
ksb_end 	dd 0
ksb_head	dd 0
ksb_tail	dd 0

; kbd_state format
; [ctrl |alt  |shift|win  | 0   |caps |num  |scroll]
;   7     6     5     4     3     2     1     0
kbd_state	db 0	; keyboard caps/scrol/num state
KBD_CTRL_BIT	equ 7
KBD_ALT_BIT	equ 6
KBD_SHIFT_BIT	equ 5
KBD_WIN_BIT	equ 4
KBD_CAPS_BIT	equ 2
KBD_NUM_BIT	equ 1
KBD_SCROLL_BIT	equ 0

ext_scan	db 0
kbd_scwait	db 0


align 4
OnCtrlAltDel:
	ret

align 4
; reads scancode in keyboard buffer
; OUT:  ax - scancode
kbd_getscan:
	push	edx

	xor	eax, eax
	mov	edx, [ksb_head]
	cmp	edx, [ksb_tail]
	je	.exit			; buffer is empty

	sub	edx, [ksb_start]
	add	edx, 2
	and	edx, SCANBUF_MASK
	add	edx, [ksb_start]

	mov	[ksb_head], edx
	mov	ax, [edx]

  .exit:
	pop	edx
	ret


align 4
; writes scancode to keyboard buffer
; IN: ax = scancode
kbd_putscan:
	push	edx

	mov	edx, [ksb_tail]
	sub	edx, [ksb_start]
	add	edx, 2
	and	edx, SCANBUF_MASK
	add	edx, [ksb_start]

	cmp	edx, [ksb_head]
	je	.exit			; no free space
	mov	[ksb_tail], edx
	mov	[edx], ax


  .exit:
	pop	edx
	ret


align 4
; set kbd led status
kbd_setled:
	push	eax
	push	ecx
	mov	al, 0edh
	out	60h, al
	call	.kWait
	mov	al, byte[kbd_state]
	and	al, 00000111b
	out	60h, al
	pop	ecx
	pop	eax
	ret

    .kWait:
	mov	cx,0ffffh
   .l1: in	al, 64h
	test	al, 10b
	loopnz	.l1
	ret


;khexnumbers     db "0123456789ABCDEF"
;kbd_printeax:
;        pusha
;        mov     ebx, 10h
;        shl     ecx, 3
;        ror     eax, cl
;        ror     eax, 4
;        shr     ecx, 2
;   .l1: xor     edx, edx
;        mov     ebp, khexnumbers
;        rol     eax, 8
;        div     ebx
;        add     ebp, edx
;        mov     dl, [ds:ebp]
;        mov     [es:edi], dl
;        add     edi,2
;        loop    .l1
;        popa
;        ret



IRQ01_End:

align 4
keyb_name	db 'keyboard'
