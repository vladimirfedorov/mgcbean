; -----------------------------------------------------------------------------
; Memory manager


vmm.init:
	push	ecx
	push	edi
	push	eax

	mov	ecx, (KHEAP_PTRS_END-KHEAP_PTRS_BASE+1)/4
	mov	edi, KHEAP_PTRS_BASE
	xor	eax, eax
	rep	stosd

	pop	eax
	pop	edi
	pop	ecx

	ret


vmm.range	dd 120000h, 130000h, 0E0000000h, 0F8000000h


; -----------------------------------------------------------------------------
; Functions for memory allocation/deallocation
; allocates heap memory
;  in:  eax = memory block size
;  out: eax = memory block address, 0 and cf set if error
kernel.malloc:

	push	ecx
	push	ebx


;        call    insert_pointer
	jc	.error
	push	eax	; eax = address of a block
	shr	ecx, 12 ; num of pages
	xor	ebx, ebx
	or	bl, 111b
  .l1:
	call	pte_set_page
	add	eax, 4096
	loop	.l1
	clc
	jmp	.exit

	pop	eax

  .error:
	xor	eax, eax
	stc

  .exit:
	pop	ebx
	pop	ecx

	ret

; free kernel heap memory block
;  in:  eax = memory block address
;  out: cf if error (block with address in eax not found)
kfree:

	push	eax
	push	ecx
	push	esi

;        call    find_pointer
	mov	ecx, [esi+4]	; block size-1
	inc	ecx
	shr	ecx, 12 	; num of pages to free

  .l1:
	call	pte_clear_page
	add	eax, 4096
	loop	.l1

	pop	esi
	pop	ecx
	pop	eax

	ret


; -----------------------------------------------------------------------------
; Functions for used memory map, PDT and PTEs
;

; create used memory map
create_umm:
    ; clear memory map
	mov	ecx, 128*1024/4 ; 128 k for 4G of memory
	mov	edi, UMM_BASE
	xor	eax, eax
	cld
	push	edi
	rep	stosd
    ; set used blocks
	not	eax
	mov	ecx, UMM_USED_SIZE/8/4	; in pages / pages in byte / bytes in dword
	pop	edi
	rep	stosd
	ret


; clears bit in UMM
;   IN:  eax - page address
umm_clear_page:
	push	eax
	push	ecx
	push	edi

	mov	ecx, eax
	and	ecx, 7000h
	shr	eax, 12+3
	shr	ecx, 12
	mov	edi, UMM_BASE
	add	edi, eax
	xor	eax, eax
	inc	eax
	shl	eax, cl
	not	eax
	and	[edi], eax

	pop	edi
	pop	ecx
	pop	eax
	ret


; searches the 1st available page and sets umm bit
;  OUT: eax - page address
umm_find_page:
	push	ebx
	push	ecx
	push	esi
	mov	esi, UMM_BASE
	mov	ebx, 128*1024/4 ; should be physical memory size /4096/4
	cld
    .nextd:
	lodsd
	cmp	eax, -1
	je	.nextd
	mov	ecx, 32
    .nextb:
	shr	eax, 1
	jnc	.found
	loop	.nextb
	dec	ebx
	jnz	.nextd
    ; free page was not found. we are out of memory :(
	xor	eax, eax
	not	eax
	jmp	.exit
    .found:
    ; set found bit
	sub	ecx, 32
	neg	ecx
	mov	eax, 1
	shl	eax, cl
	sub	esi, 4
	or	[esi], eax
    ; get page address
	mov	eax, esi
	sub	eax, UMM_BASE
	shl	eax, 12+3
	shl	ecx, 12
	add	eax, ecx
    .exit:
	pop	esi
	pop	ecx
	pop	ebx
	ret


; preset system memory
set_system_ptes:
; system base memory
; 0-8M
	mov	ecx, 1024*8
	mov	edi, PTE_BASE
	xor	eax, eax
	or	al, 111b
    @@: stosd
	add	eax, 4096
	loop	@b

; video memory
; map physical address to VIDEO_FB - system frame buffer base address
	mov	ecx, 1024*256
	mov	eax, [screen_buff]
	mov	edi, VIDEO_FB
	shr	edi, 10
	add	edi, PTE_BASE
	or	al, 111b
    @@: stosd
	add	eax, 4096
	loop	@b

	ret




; looks for the 1st available page in umm and sets page present
; IN:  eax - page address
;      bx  - page attributes
; changes eax
pte_set_page:
	push	edi
	push	eax

	shr	eax, 12
	mov	edi, eax
	call	umm_find_page
	and	eax, 0FFFFF000h
	and	ebx, 0FFFh
	or	eax, ebx
	shl	edi, 2
	add	edi, PTE_BASE
	stosd

	pop	eax
	pop	edi
	ret


; clears presence bit           - unused
; IN:  eax - page address
;pte_clear_page:
;        push    edi
;        push    eax
;
;        mov     edi, eax        ; offset
;        shr     edi, 10         ; page number
;        add     edi, PTE_BASE
;        or      byte[edi], 0FEh
;
;        pop     eax
;        pop     edi
;        ret


; clears page and sets memory page free in UMM
; IN:  eax - page address
pte_clear_page:
	push	edi
	push	eax

	mov	edi, eax	; offset
	shr	edi, 10 	; page number
	add	edi, PTE_BASE

	mov	eax, [edi]
	and	eax, 0fffff000h ; page bits
	call	umm_clear_page

	mov	dword [edi], 0	; free page

	pop	eax
	pop	edi
	ret


; creates PDT structure
create_pdt:
    ; for all ptes set 4k pages available from any pl, rw
    ; all PTEs are set present
	mov	edi, PDT_BASE
	mov	eax, PTE_BASE
	or	al, 00000111b	; 4k/0/0/cache enabled/wt/user/rw/present
	mov	ecx, 1024
    @@: stosd
	add	eax, 4096
	loop	@b
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  DEBUG FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
vmm_test.malloc:
	push	ebp, esi, eax, ecx, ebx, edx
	mov	ebp, esp
	add	ebp, 4+6*4
	mov	esi, [ss:ebp]
	inc	esi		; skip leading "d"
	call	convert.toNumber
	mov	edx, vmm_memory

	call	__ptrlist_insert_element

	pop	edx, ebx, ecx, eax, esi, ebp
	ret

vmm_test.free:
	push	ebp, esi, eax, ecx, ebx, edx
	mov	ebp, esp
	add	ebp, 4+6*4
	mov	esi, [ss:ebp]
	inc	esi		; skip leading "d"
	call	convert.toNumber
	mov	edx, vmm_memory

	call	__ptrlist_delete_element

	pop	edx, ebx, ecx, eax, esi, ebp
	ret


