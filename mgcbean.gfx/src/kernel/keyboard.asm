; keyboard driver
; functions for converting scancodes-characters and so on

; flags

; constants from irq01.asm
KBD_CTRL_BIT	equ 7
KBD_ALT_BIT	equ 6
KBD_SHIFT_BIT	equ 5
KBD_WIN_BIT	equ 4
KBD_CAPS_BIT	equ 2
KBD_NUM_BIT	equ 1
KBD_SCROLL_BIT	equ 0


; character tables
__chtable1:
	;   0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F         normal
	db  0 , 27,'1','2','3','4','5','6','7','8','9','0','-','=', 8 , 9	; 0x
	db 'q','w','e','r','t','y','u','i','o','p','[',']', 13, 0 ,'a','s'	; 1x
	db 'd','f','g','h','j','k','l',';',"'",'`', 0 ,'\','z','x','c','v'	; 2x
	db 'b','n','m',',','.','/', 0 , 0 , 0 ,' ', 0 , 0 , 0 , 0 , 0 , 0	; 3x
	db  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0	; 4x
	db  0 , 0 , 0 , 0 , 0 , 0 ,'\', 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0	; 5x
__chtable2:
	;   0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F         SHIFT
	db  0 , 27,'!','@','#','$','%','^','&','*','(',')','_','+', 8 , 9	; 0x
	db 'Q','W','E','R','T','Y','U','I','O','P','{','}', 13, 0 ,'A','S'	; 1x
	db 'D','F','G','H','J','K','L',':','"','~', 0 ,'|','Z','X','C','V'	; 2x
	db 'B','N','M','<','>','?', 0 , 0 , 0 ,' ', 0 , 0 , 0 , 0 , 0 , 0	; 3x
	db  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0	; 4x
	db  0 , 0 , 0 , 0 , 0 , 0 ,'|', 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0	; 5x
__chtable3:
	;   0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F         CAPS
	db  0 , 27,'1','2','3','4','5','6','7','8','9','0','-','=', 8 , 9	; 0x
	db 'Q','W','E','R','T','Y','U','I','O','P','[',']', 13, 0 ,'A','S'	; 1x
	db 'D','F','G','H','J','K','L',';',"'",'`', 0 ,'\','Z','X','C','V'	; 2x
	db 'B','N','M',',','.','/', 0 , 0 , 0 ,' ', 0 , 0 , 0 , 0 , 0 , 0	; 3x
	db  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0	; 4x
	db  0 , 0 , 0 , 0 , 0 , 0 ,'\', 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0	; 5x
__chtable4:
	;   0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F         SHIFT+CAPS
	db  0 , 27,'!','@','#','$','%','^','&','*','(',')','_','+', 8 , 9	; 0x
	db 'q','w','e','r','t','y','u','i','o','p','{','}', 13, 0 ,'a','s'	; 1x
	db 'd','f','g','h','j','k','l',';',"'",'~', 0 ,'|','z','x','c','v'	; 2x
	db 'b','n','m','<','>','?', 0 , 0 , 0 ,' ', 0 , 0 , 0 , 0 , 0 , 0	; 3x
	db  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0	; 4x
	db  0 , 0 , 0 , 0 , 0 , 0 ,'|', 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0	; 5x


; out: ax - character code
kgetch:
	push	edi, ebx
	call	kbd_getscan

	xor	ebx, ebx
	mov	bl, [kbd_state]

	cmp	al, 2ah 	; left shift
	jne	@f
	bts	ebx, KBD_SHIFT_BIT
    @@:
	cmp	al, 36h 	; right shift
	jne	@f
	bts	ebx, KBD_SHIFT_BIT
    @@:
	cmp	al, 0aah	; left shift released
	jne	@f
	btr	ebx, KBD_SHIFT_BIT
    @@:
	cmp	al, 0b6h	; left shift released
	jne	@f
	btr	ebx, KBD_SHIFT_BIT
    @@:
	mov	[kbd_state], bl


	and	eax, 0ffh
	cmp	al, (__chtable2-__chtable1)
	jae	.set0
	or	al, al
	jz	.set0


	mov	edi, __chtable1
	bt	ebx, KBD_SHIFT_BIT
	jnc	@f
	add	edi, (__chtable2-__chtable1)
    @@:
	bt	ebx, KBD_CAPS_BIT
	jnc	@f
	add	edi, (__chtable3-__chtable1)
    @@:

	add	edi, eax
	mov	al, [edi]

	jmp	.exit
  .set0:
	xor	eax, eax
  .exit:
	pop	ebx, edi
	ret


