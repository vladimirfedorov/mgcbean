; Pointer lists - sorted structures of pointers for memory allocation
; Pointer:
;       dd pointer
;       dd size
;
; List of structures must be described with a pointer list descriptor
; Pointer list descriptor
;   +0  dd pointer to a list
;   +4  dd pointer to end of a list
;   +8  dd heap base address
;   +C  dd heap size
;

PTRLIST_SIZE		equ	8	; element size
PTRLIST_SHR		equ	3	; shr 3 - to get number of elements to move
PTRLIST_REPMOVE 	equ	2	; shr 2 - to get number of dwords to move

PTRLIST_LISTBASE	equ	0
PTRLIST_LISTEND 	equ	4
PTRLIST_HEAPBASE	equ	8
PTRLIST_HEAPEND 	equ	12

; insert pointer into list
; IN:  eax - size of element
;      edx - pointer list descriptor
__ptrlist_insert_element:
	push	esi, edi, ecx, ebp
	mov	ecx, [edx+PTRLIST_LISTEND]
	sub	ecx, [edx+PTRLIST_LISTBASE]
	shr	ecx, PTRLIST_SHR
	sub	ecx, 1				; leave the last element untouched
	mov	esi, [edx+PTRLIST_LISTBASE]
	mov	ebx, [edx+PTRLIST_HEAPBASE]	; ebx contains (address+size) of the previous element
						; so to get a gap we should subtract ebx from the next pointer address
  .l1:
	cmp	dword [esi], 0
	je	.found_empty

	mov	edi, [esi]
	sub	edi, ebx
	cmp	edi, eax
	jae	.found

	mov	ebx, [esi]
	add	ebx, [esi+4]
	add	esi, PTRLIST_SIZE
	loop	.l1
	; no gap!
	stc
	jmp	.exit

  .found_empty:
	call	__ptrlist_can_add_pointer	; is there enough heap space?
	jc	.exit
	jmp	.ok

  .found:
	call	__ptrlist_move_up		; is there enough pointers?
	jc	.exit
  .ok:
	mov	[esi], ebx
	mov	[esi+4], eax
	clc
  .exit:
	pop	ebp, ecx, edi, esi
	ret


; delete pointer from list
; IN:  eax - memory address
;      edx - pointer list descriptor
__ptrlist_delete_element:
	push	esi, edi, ecx
	mov	ecx, [edx+PTRLIST_LISTEND]
	sub	ecx, [edx+PTRLIST_LISTBASE]
	shr	ecx, PTRLIST_SHR
	mov	esi, [edx]
  .l1:
	cmp	eax, [esi]
	je	.found
	add	esi, PTRLIST_SIZE
	loop	.l1
	; nothing found...
	stc
	jmp	.exit
  .found:
	call	__ptrlist_move_down
	clc
  .exit:
	pop	ecx, edi, esi
	ret


; move block of pointers up
; IN:  esi - address to insert to
;      edx - pointer list descriptor
__ptrlist_move_up:
	push	esi, edi, ecx
	call	__ptrlist_can_move_up
	jc	.exit
	mov	ecx, [edx+PTRLIST_LISTEND]
	sub	ecx, esi
	sub	ecx, PTRLIST_SIZE*1	; we cannot fill the last element
	shr	ecx, PTRLIST_REPMOVE
	mov	edi, [edx+PTRLIST_LISTEND]
	sub	edi, PTRLIST_SIZE
	mov	esi, edi
	sub	esi, PTRLIST_SIZE

	std
	rep	movsd
	cld
  .exit:
	pop	ecx, edi, esi
	ret



; move block of pointers down
; IN:  esi - address of element to delete
;      edx - pointer list descriptor
__ptrlist_move_down:
	push	esi, edi, ecx
	mov	edi, esi
	add	esi, PTRLIST_SIZE
	mov	ecx, [edx+4]
	sub	ecx, esi
	shr	ecx, PTRLIST_REPMOVE	; number of elements to move

	cld
	rep	movsd
	pop	ecx, edi, esi
	ret

; check if we can move block up
; IN:  edx - pointer list descritor
; OUT: cf set if no free element
__ptrlist_can_move_up:
	push	esi
	mov	esi, [edx+PTRLIST_LISTEND]
	sub	esi, PTRLIST_SIZE*2
	cmp	dword [esi], 0
	je	.ok
	stc
	jmp	.exit
  .ok:
	clc
  .exit:
	pop	esi
	ret

; check if there is enough heap space to allocate memory
; check when a new pointer is created
; IN:  esi - address of a new pointer
;      edx - pointer list descriptor
;      eax - size of a new block
;      ebx - address+size of a previous element
__ptrlist_can_add_pointer:
	push	esi, edi
	sub	esi, PTRLIST_SIZE
	mov	edi, [edx+PTRLIST_HEAPEND]
	sub	edi, ebx
	cmp	edi, eax

	jae	.ok
	stc
	jmp	.exit
  .ok:
	clc
  .exit:
	pop	edi, esi
	ret




