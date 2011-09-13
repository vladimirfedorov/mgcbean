; _____________________________________________________________________________
;
; scroll 1 line
SCROLL_TOP	equ	1	; 1st line - info/menu/etc.
SCROLL_BOTTOM	equ	24	; last line to scroll

scroll_top	db 1
scroll_bottom	db 24

kscroll1:
	push	esi, edi, ecx, eax

	mov	esi, 0b8000h+160+(SCROLL_TOP)*160
	mov	edi, 0b8000h+(SCROLL_TOP)*160
	mov	ecx, 160*(SCROLL_TOP+SCROLL_BOTTOM)/4
	rep	movsd

	xor	eax, eax
	mov	ah, [kprintf_attr]
	shl	eax, 16
	mov	ah, [kprintf_attr]
	mov	ecx, 160/4
	mov	edi, 0b8000h+(SCROLL_BOTTOM)*160      ; clear bottom line
	rep	stosd

	pop	eax, ecx, edi, esi
	ret

; _____________________________________________________________________________
;
; Output string (text mode)
; String format:
;  \n = line feed           \\ = \    %i - print decimal (from stack)
;  \r = carriage return     \' = '    %x - print hex value
;  \b = backspace           \" = "    %s - string (ptr in stack)
;                                     %% = %
;
; IN:  esi - string to print

kprintf_buff	dd 0,0,0,0	; buffer for convert functions
kprintf_col	db 0		; cursor col
kprintf_row	db 0		; cursor row
kprintf_attr	db 07h		; character attribute (bg+color)
kprintf_flags	db 0

SKIPSCROLLCHK	equ 1		; skip scrolling checks when printing

; ernel mode printf
; printf(char* string, param1, param2, ...);
kprintf:

	push	eax, ebp, edi, esi, ebx

	mov	ebp, esp	; kprintf params
	add	ebp, 4 +4*5	; pushed registers

	mov	esi, [ss:ebp]

  .next:
	lodsb
	or	al, al
	jz	.exit

	cmp	al, '%'
	jnz	.c2

	lodsb
	or	al, al
	jz	.c3	; print "%"
	cmp	al, '%'
	je	.c3

	; more checks...
	cmp	al, 'i'
	jne	@f
	xor	eax, eax
	add	ebp, 4
	mov	eax, [ss:ebp]
	mov	edi, kprintf_buff
	call	__kprintf_clear_buffer
	call	convert.toString
	call	__kprintf_print_buffer

	jmp	.ce
    @@:

	cmp	al, 'u'
	jne	@f
	xor	eax, eax
	add	ebp, 4
	mov	eax, [ss:ebp]
	mov	edi, kprintf_buff
	call	__kprintf_clear_buffer
	call	convert.toStringUnsigned
	call	__kprintf_print_buffer

	jmp	.ce
    @@:

	cmp	al, 'x'
	jne	@f
	xor	eax, eax
	add	ebp, 4
	mov	eax, [ss:ebp]
	mov	edi, kprintf_buff
	call	__kprintf_clear_buffer
	call	convert.toHex
	call	__kprintf_print_buffer

	jmp	.ce
    @@:


	; if nothing interesting, print % and the next character
	mov	al, '%'
	dec	esi
	jmp	.c3

  .c2:
	cmp	al, '\'
	jnz	.c3

	lodsb
	or	al, al
	jz	.c3
	cmp	al, '\'
	je	.c3
	cmp	al, '"'
	je	.c3
	cmp	al, "'"
	je	.c3

	cmp	al, 'n'
	jne	@f
	mov	byte [kprintf_col], 0
	inc	byte [kprintf_row]
	jmp	.next
    @@:
	cmp	al, 'r'
	jne	@f
	mov	byte [kprintf_col], 0
	jmp	.next
    @@:
	cmp	al, 'b'
	jne	@f
	dec	byte [kprintf_col]

	jmp	.next
    @@:


	mov	al, '\'
	dec	esi
	; jmp .c3


  .c3:
	; ordinary symbol

	call	__kprintf_writechar
  .ce:

	jmp	.next


  .exit:
	call	__kprintf_chk_range	; check at the end
	pop	ebx, esi, edi, ebp, eax
	ret


; _____________________________________________________________________________
;
; print 1 character (al)

kprintch_text	db 0,0

kprintch:
	push	edi
	call	__kprintf_writechar
	pop	edi
	ret


; _____________________________________________________________________________
;
__kprintf_chk_range:
  .chk1:				; over right margin
	cmp	byte [kprintf_col], 79
	jle	.chk2
	sub	byte [kprintf_col], 80
	inc	byte [kprintf_row]
	jmp	.chk1

  .chk2:
	cmp	byte [kprintf_col], 0
	jge	.chk3
	dec	byte [kprintf_row]
	add	byte [kprintf_col], 80
	jmp	.chk2

;        test    [kprintf_flags], SKIPSCROLLCHK
;        jnz     .exit

  .chk3:
	cmp	byte [kprintf_row], SCROLL_TOP
	jge	.chk4
	mov	byte [kprintf_row], SCROLL_TOP

  .chk4:
	cmp	byte [kprintf_row], SCROLL_BOTTOM
	jle	.exit
	dec	byte [kprintf_row]
	mov	byte [kprintf_row], SCROLL_BOTTOM
	call	kscroll1

  .exit:
	ret

; _____________________________________________________________________________
;
; converts current row:column address to edi offset
__kprintf_getxy:
	push	ebx
	xor	ebx, ebx
	mov	bl, [kprintf_row]
	mov	edi, ebx		;
	shl	edi, 7			;   edi = row * 160 = row * (128 + 32)
	shl	ebx, 5			;
	add	edi, ebx		;
	xor	ebx, ebx
	mov	bl, [kprintf_col]	;
	shl	ebx, 1			;   + col * 2
	add	edi, ebx		;
	add	edi, 0b8000h
	pop	ebx
	ret

; _____________________________________________________________________________
;
; puts character in al to screen and moves cursor

__kprintf_writechar:
	call	__kprintf_chk_range
	call	__kprintf_getxy
	mov	ah, [kprintf_attr]
	mov	[edi], ax
	inc	byte [kprintf_col]
	ret
; _____________________________________________________________________________
;
; puts character in al to screen; doesn't move cursor

__kprintf_putchar:
	call	__kprintf_chk_range
	call	__kprintf_getxy
	mov	ah, [kprintf_attr]
	mov	[edi], ax
	ret

; _____________________________________________________________________________
;
__kprintf_clear_buffer:
	mov	dword [kprintf_buff    ], 0
	mov	dword [kprintf_buff  +4], 0
	mov	dword [kprintf_buff  +8], 0
	mov	dword [kprintf_buff +12], 0
	ret

; _____________________________________________________________________________
;
__kprintf_print_buffer:
	push	esi, ecx
	mov	esi, kprintf_buff
	xor	ecx, ecx
	mov	cl, 16
  .l1:
	lodsb
	or	al, al
	jz	@f
	call	__kprintf_writechar
   @@:
	loop	.l1

	pop	ecx, esi
	ret


; _____________________________________________________________________________
;
; Get string
; IN:  edi - string to write to
kgets:
	push	eax, esi, edi

	mov	esi, edi
  .next:
	call	kgetch
	cmp	al, 13		; Enter
	jne	@f
	xor	al, al
	stosb
	mov	byte [kprintf_col], 0
	inc	byte [kprintf_row]
	jmp	.exit
   @@:
	cmp	al, 8		; Backspace
	jne	@f
	cmp	esi, edi
	je	.next
	dec	edi
	mov	byte [edi], 0
	dec	[kprintf_col]
	xor	eax, eax
	push	edi
	call	__kprintf_putchar
	pop	edi
	jmp	.next
   @@:
	cmp	al, 32
	jb	.next

	stosb
	push	edi
	call	__kprintf_writechar
	pop	edi
	jmp	.next

  .exit:
	pop	edi, esi, eax
	ret



; _____________________________________________________________________________
;
; converter functions
; convert.toString
; convert.toHex
; convert.toNumber

; _____________________________________________________________________________
;
; number to string (decimal)
; eax - number
; edi - buffer (at least 16 characters long)
convert.toString:
	push	ebx
	mov	ebx, -10
	call	__convert_uni
	pop	ebx
	ret

; _____________________________________________________________________________
;
; number to string (decimal)
; eax - number
; edi - buffer (at least 16 characters long)
convert.toStringUnsigned:
	push	ebx
	mov	ebx, 10
	call	__convert_uni
	pop	ebx
	ret


; _____________________________________________________________________________
;
; number to string (hex)
; eax - number
; edi - buffer (at least 16 characters long)
; ecx - format/num of characters
convert.toHex:
	push	ebx
	mov	ebx, 16
	call	__convert_uni
	pop	ebx
	ret

; _____________________________________________________________________________
;
; OPTIMIZATION REQUIRED!!!
; convert string to number
; default format - decimal, if ends with 'h' or starts with '0x' - hexadecimal
; esi - source buffer
; OUT: eax - number
convert.toNumber:
	push	ebx, ecx, edx, esi
	call	__convert_skipspaces
	mov	ebx, 10 		; default radix and check function
	mov	[__convert_chkdigit], __convert_chkdigit10
	mov	byte [__convert_signb], 0

	cmp	byte [esi], '+'
	jne	@f
	inc	esi
    @@:

	cmp	byte [esi], '-'
	jne	@f
	mov	byte [__convert_signb], -1
	inc	esi
    @@:
	cmp	word [esi], '0x'
	jne	@f
	mov	ebx, 16
	add	esi, 2
	jmp	.rdxdef
    @@:
	push	esi
  .l01:
	xor	eax, eax
	lodsb
	cmp	al, 0
	je	.l0z
	call	__convert_chkdigit16
	jc	.l01

	cmp	al, 'h'
	jne	.l02
	mov	ebx, 16
	mov	[__convert_chkdigit], __convert_chkdigit16
  .l02:
	cmp	al, 'H'
	jne	.l0z
	mov	ebx, 16
	mov	[__convert_chkdigit], __convert_chkdigit16
  .l0z:
	pop	esi

  .rdxdef:			; radix is defined
	xor	ecx, ecx	; accumulator
  .l11:
	xor	eax, eax
	lodsb
	call	[__convert_chkdigit]
	jnc	.exit

	push	eax
	mov	eax, ecx
	xor	edx, edx
	mul	ebx
	mov	ecx, eax
	pop	eax

	sub	al, 30h
	cmp	al, 9
	jna	@f
	sub	al, 7	; 42h ('A')
	cmp	al, 15
	jna	@f
	sub	al, 20h ; for lower case letters
    @@:
	add	ecx, eax
	jmp	.l11

  .exit:
	mov	eax, ecx
	cmp	byte [__convert_signb], -1
	jne	@f
	neg	eax
    @@:
	pop	esi, edx, ecx, ebx
	ret


__convert_chkdigit	dd 0
__convert_signb 	db 0

; _____________________________________________________________________________
;
; check if a byte is a hexadecimal digit
; IN:  al - byte
; OUT: cf set if true, clear otherwise
__convert_chkdigit16:
	cmp	al, '0'
	jb	.notadigit
	cmp	al, '9'
	ja	.hex1
	stc
	ret
  .hex1:
	cmp	al, 'A'
	jb	.notadigit
	cmp	al, 'F'
	ja	.hex2
	stc
	ret
  .hex2:
	cmp	al, 'a'
	jb	.notadigit
	cmp	al, 'f'
	ja	.notadigit
	stc
	ret
  .notadigit:
	clc
	ret

; _____________________________________________________________________________
;
; check if a byte is a decimal digit
; IN:  al - byte
; OUT: cf set if true, clear otherwise
__convert_chkdigit10:
	cmp	al, '0'
	jb	.notadigit
	cmp	al, '9'
	ja	.notadigit
	stc
	ret
  .notadigit:
	clc
	ret


; _____________________________________________________________________________
;
; skip spaces
; IN:  esi - string
; OUT: esi - 1st byte > 32
__convert_skipspaces:
	cmp	byte[esi], 32
	ja	@f
	inc	esi
	jmp	__convert_skipspaces
    @@: ret

; _____________________________________________________________________________
;
; IN: edi - 16-byte buffer
;     ebx - radix
;     eax - number

__convert_hexnumbers	db "0123456789ABCDEF"
__convert_sign		db 0

__convert_uni:
	push	eax, edx, edi, ebp

	mov	[__convert_sign], 0
	cmp	ebx, -10
	jne	.l0
	neg	ebx
	bt	eax, 31
	jnc	.l0
	neg	eax
	mov	[__convert_sign], '-'

   .l0:
	;mov     edi, __convert_buffer
	add	edi, 15
   .l1: xor	edx, edx
	mov	ebp, __convert_hexnumbers
	div	ebx
	add	ebp, edx
	mov	dl, [ds:ebp]
	mov	[edi], dl
	dec	edi
	or	eax, eax
	jnz	.l1
	mov	al, [__convert_sign]
	stosb
	pop	ebp, edi, edx, eax
	ret



; _____________________________________________________________________________
;
; Memory dump
; memdump(char* command);
memdump:
	push	ebp, esi, eax, ecx, ebx, edx
	mov	ebp, esp
	add	ebp, 4+6*4
	mov	esi, [ss:ebp]
	inc	esi		; skip leading "d"
	call	convert.toNumber

	mov	esi, eax
	mov	edx, 8		; number of rows to print

  .l00:
	call	__kprintf_chk_range
	call	__kprintf_getxy

	mov	eax, esi
	mov	ecx, 4
	call	printeax	; memory address

	mov	ebx, 16 	; bytes per row
	add	edi, 12*2
	mov	cl, 1
	push	esi
  .l01: 			; hex view
	lodsb
	call	printeax
	add	edi, 3*2
	dec	ebx
	jnz	.l01

	mov	byte[edi-(3*8*2+2)], '-'
	pop	esi
	add	edi, 3*2
	mov	ecx, 16

	mov	[kprintf_col], 80-16
  .l02: 			; left side
	lodsb
	or	al, al
	jnz	@f
	mov	al, '.'
    @@:
	stosb
	inc	edi
	loop	.l02

	inc	[kprintf_row]
	mov	[kprintf_col], 0
	dec	edx
	jnz	.l00



	pop	edx, ebx, ecx, eax, esi, ebp
	ret
