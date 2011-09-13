; This functions can be used not only for kernel heap memory allocation,
; but for allocation any memory block. Create memory pointer structure:
; (pointers descriptor)
;
;   +00h dd pointer_to_structure  - pointer to pointer structure
;   +04h dd structure_size        - structure size (8*n bytes, n - max. blocks)
;   +08h dd memory_block_start    - memory block for allocation
;   +0ch dd memory_block_size     - size of memory for allocation (0 - up to 4GB)
;   +10h dd 0 (1st free block)
;   +14h dd 0 (1st unused block)  - for optimization, leave it empty
;   +18h dd 0 (reserved)
;   +1ch dd 0 (reserved)
;
; Pointers structure:
;
;   dd pointer  - pointer to a memory location
;   dd size     - size of allocated memory
;
; Functions:
;
;  malloc : allocate memory
;   IN:  eax - amount of memory
;        esi - pointer to pointers descriptor
;   OUT: eax - pointer to memory block
;
;  mfree : free memory block
;   IN:  eax - pointer to memory location
;        esi - pointer to pointers descriptor
;   OUT: -


; insert pointer to memory block
; IN: eax - offset
;     esi - pointer to pointer structure
kmem_insert_pointer:

	ret

; delete pointer to memory block
;
kmem_delete_pointer:

	ret

; in: ecx - ptr to insertion point. element with this address will be moved higher
;     esi - ptr to pointer descriptor
kmem_ptrs_move_up:

	mov	ebx, [esi+4] ; end of pointers
	add	ebx, [esi]



	ret

; in: ecx - ptr to deleted element
;     esi - ptr to pointer descriptor
kmem_ptrs_mov_down:
	push	eax
	push	ebx
	push	edi

	; if ecx < 1st free block, save ecx
	cmp	ecx, [esi+10h]
	jae	.@f
	mov	[esi+10h], ecx	; save new 1st free block
    @@:

	mov	ebx, [esi+4]	; ebx = end of pointers
	add	ebx, [esi]

	mov	eax, [esi+14h]	; eax = 1st unused block
	or	eax, eax	; if(eax==0) initialize structure
	jnz	.found

	mov	eax, [esi]	; pointers start
   .l1:
	cmp	[eax], 0
	jz	.found
	add	eax, 8
	cmp	eax, ebx
	jb	.l1

   .found:
	; eax = end of region to move down
	mov	ebx, eax	; ebx = end of region
	xchg	eax, ecx	; eax = deleted, ecx = end of region
	sub	ecx, eax
	shr	ecx, 2		; ecx = ecx / 4 - num of dwords to move
	push	esi
	mov	esi, eax
	mov	edi, eax
	add	esi, 8
	rep	movsd
	pop	esi

	sub	ebx, 8		; erase the last element
	mov	[ebx], 0
	mov	[ebx+4], 0
	mov	[esi+14], ebx	; save the 1st unused

	pop	edi
	pop	ebx
	pop	eax
	ret

