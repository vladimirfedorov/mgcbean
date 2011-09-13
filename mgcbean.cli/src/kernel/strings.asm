; strings lib
; for asciiz strings
; ds:esi - source string
; es:edi - destination string

; string length
;  IN:  ds:esi - string
;  OUT: ecx - string length
strlen:
	push	eax
	push	edi
	push	esi

	mov	edi, esi

	xor	eax, eax
	mov	ecx, eax
	not	ecx
	cld
	repnz	scasb
	not	ecx	; neg ecx :)
	dec	ecx	;

	pop	esi
	pop	edi
	pop	eax
	ret

; copy one string to another
;  IN:  ds:esi - source
;       es:edi - destination
;  OUT: -
strcopy:
	push	ecx
	push	esi
	push	edi

	call	strlen
	inc	ecx	; copy 0
	cld
	rep	movsb

	pop	edi
	pop	esi
	pop	ecx
	ret


; to uppercase - for ascii table only!
;  IN:  ds:esi - source string
;       es:edi - destination (may be = source)
;  OUT: -
strtoupper:
	push	eax
	push	ecx
	push	edi
	push	esi

	xor	eax, eax
	mov	ecx, eax
	not	ecx
	cld
   .l1: lodsb
	or	al, al
	jz	.exit
	cmp	al, 'a'
	jb	.l2
	cmp	al, 'z'
	ja	.l2
	sub	al, ('a'-'A')
   .l2: stosb
	loop	.l1
   .exit:
	pop	esi
	pop	edi
	pop	ecx
	pop	eax
	ret

; to lowercase - for ascii table only!
;  IN:  ds:esi - source string
;       es:edi - destination (may be = source)
;  OUT: -
strtolower:
	push	eax
	push	ecx
	push	edi
	push	esi

	xor	eax, eax
	mov	ecx, eax
	not	ecx
	cld
   .l1: lodsb
	or	al, al
	jz	.exit
	cmp	al, 'A'
	jb	.l2
	cmp	al, 'Z'
	ja	.l2
	add	al, ('a'-'A')
   .l2: stosb
	loop	.l1
   .exit:
	pop	esi
	pop	edi
	pop	ecx
	pop	eax
	ret

; compares two strings (case sensitive)
;  IN:  ds:esi - string1
;       es:edi - string2
;  OUT: flags for j-condition (ja,je,...)
strcmp:
	push	eax
	push	edi
	push	esi

	cld
   .l1: lodsb
	scasb
	jne	.exit
	or	al, al
	jnz	.l1
   .exit:
	pop	esi
	pop	edi
	pop	eax
	ret

; searches one string for another
;  IN:  ds:esi - string to look in
;       es:edi - string to search for
;  OUT: edx - position (-1 if not found)
strpos:
	push	esi
	push	edi
	push	eax
	push	ebx
	push	ecx

	call	strlen
	mov	eax, ecx	; eax = str1.Length;
	xchg	esi, edi
	call	strlen
	cmp	eax, ecx
	jb	.notfound	; exit if str2.Length > str1.Length;

	mov	ebx, ecx	; ebx = str2.Length
	sub	eax, ebx	; last possible index
	xchg	esi, edi
	xor	edx, edx

   .l1: mov	cl, [ebx+esi]		; save byte
	mov	byte[ebx+esi], 0	; end of string
	call	strcmp			; compare
	mov	[ebx+esi], cl		; restore byte
	je	.exit
	inc	esi
	inc	edx
	cmp	eax, edx	; end of str1
	jne	.l1

   .notfound:
	xor	edx, edx
	dec	edx		; -1 - not found

   .exit:
	pop	ecx
	pop	ebx
	pop	eax
	pop	edi
	pop	esi
	ret




