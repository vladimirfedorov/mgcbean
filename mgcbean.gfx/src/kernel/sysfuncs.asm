; DESCRIPTION
;
; constants: GDT_BASE, GDT_SIZE, IDT_BASE, IDT_SIZE
;
; add_gdt_desc - adds new descriptor
;     IN:  eax - offset
;          edx - limit
;          bl  - access
;     OUT: eax = descriptor (8,10h,18h,etc.) 0 if no free space in gdt
;
; set_desc - update descriptor data
;     IN:  esi - descriptor address
;          eax - offset
;          edx - limit
;          bl  - access
;
; del_gdt_desc - deletes descriptor
;     IN:  ax  - descriptor
;
; add_task - adds task in memory to list
;            a task MUST has 64k space before pointer (used for stack)
;     IN:  eax - task address
;
; clear_task_record - clears task record
;     IN:  edi - task record offset
;
; create_tss - creates tss structure
;     IN:  eax = program offset
;          edi - task list entry address
;
; set_idt_int - creates interrupt in IDT
;     IN:  eax - int number
;          edx - offset
;
; set_idt_task - creates task gate in IDT
;     IN:  eax - int num
;           dx - task selector
;
; sys_malloc
;     IN:   eax - memory to allocate (bytes)
;     OUT:  eax - pointer to memoy block, 0 if not enough memory




; ------------------------------------------------------------------------------
; adds 32-bit 4k granularity  descriptor to GDT
; pl = 0
; IN: eax - offset
;     edx - limit
;     bl  - access
; return: ax - descriptor index, 0 - no free descriptor, 8-1, 10h-2, etc

add_gdt_desc:
	push	esi
	push	edx
	push	ecx
	pushf
	mov	ecx, eax
	mov	esi, GDT_BASE+8+4
 .next:
	lodsd
	or	eax, eax
	jz	.found
	add	esi, 4
	cmp	esi, GDT_BASE+GDT_SIZE
	jb	.next
; can't found free descriptor
	xor	eax, eax
	jmp	.exit

 .found:
	mov	eax, ecx
	sub	esi, 8
	mov	[esi+2], ax
	mov	[esi], dx
	shr	eax, 16
	mov	[esi+5], bl
	mov	[esi+4], al
	shr	edx, 16
	and	dl, 0fh
	or	dl, 11000000b
	mov	[esi+6], dl
	mov	[esi+7], ah
	mov	eax, esi
	sub	eax, GDT_BASE
 .exit:
	popf
	pop	ecx
	pop	edx
	pop	esi
	ret


add_gdt_ldtdesc:
	push	esi
	push	edx
	push	ecx
	pushf
	mov	ecx, eax
	mov	esi, GDT_BASE+8+4
 .next:
	lodsd
	or	eax, eax
	jz	.found
	add	esi, 4
	cmp	esi, GDT_BASE+GDT_SIZE
	jb	.next
; can't found free descriptor
	xor	eax, eax
	jmp	.exit

 .found:
	mov	eax, ecx
	sub	esi, 8
	mov	[esi+2], ax
	mov	[esi], dx
	shr	eax, 16
	mov	[esi+5], bl
	mov	[esi+4], al
	shr	edx, 16
	and	dl, 0fh
	mov	[esi+6], dl
	mov	[esi+7], ah
	mov	eax, esi
	sub	eax, GDT_BASE
 .exit:
	popf
	pop	ecx
	pop	edx
	pop	esi
	ret

; ------------------------------------------------------------------------------
; IN: eax - offset
;     edx - limit (4k pages)
;     bl  - access
;     esi - descriptor address

set_desc:
	push	eax
	push	edx
	mov	[esi], dx
	mov	[esi+2], ax
	shr	eax, 16
	mov	[esi+5], bl
	mov	[esi+4], al
	shr	edx, 16
	and	dl, 0fh
	or	dl, 11000000b ; 4k pages
	mov	[esi+6], dl
	mov	[esi+7], ah
	pop	edx
	pop	eax
	ret


; ------------------------------------------------------------------------------
; IN: eax - offset
;     edx - limit (bytes)
;     bl  - access
;     bh  - GDXU0000
;     edi - descriptor address

set_sys_ldt_desc:
	push	eax
	push	edx
	mov	[edi], dx
	mov	[edi+2], ax
	shr	eax, 16
	mov	[edi+5], bl
	mov	[edi+4], al
	shr	edx, 16
	and	dl, 0fh
	or	dl, bh		; bh = GDXU0000
	mov	[edi+6], dl
	mov	[edi+7], ah
	pop	edx
	pop	eax
	ret

; ------------------------------------------------------------------------------
; deletes descriptor
; IN: ax - descriptor

del_gdt_desc:
	push	eax
	push	edi
	and	eax, 0fff8h
	cmp	eax, GDT_SIZE
	ja	.exit
	add	eax, GDT_BASE
	mov	edi, eax
	xor	eax, eax
	stosd
	stosd
 .exit:
	pop	edi
	pop	eax
	ret

; ------------------------------------------------------------------------------
; adds system task (mouse driver, keyboard, etc. use it)
;   system task allocates memory for stack in system heap
; IN: esi - task structure
;  system task structure (doesn't create its own window)
;   +00 dd task_ptr
;   +04 dd task_size (bytes)
;   +08 dd task_stack_size (bytes)
;   +0C dd task_name_ptr
;   +10 dd attributes (reserved)
;   +14 dd reserved
; OUT: ax = task selector
;

add_sys_task:
	push	ebx
	push	ecx
	push	edx
	push	edi


	call	get_free_task
	or	edi, edi
	jz	.exit

	call	clear_task_record

      ; Initialize LDT descriptors
	mov	word [edi+TASK_TSS+TSS_CS],  8	+100b	; system ldt descriptor
	mov	word [edi+TASK_TSS+TSS_SS], 18h +100b	; system stack - sys_malloc
	mov	word [edi+TASK_TSS+TSS_ES], 10h +100b	; data 0..0xffffffff
	mov	word [edi+TASK_TSS+TSS_DS], 10h +100b	;
	mov	word [edi+TASK_TSS+TSS_FS], 10h +100b	;
	mov	word [edi+TASK_TSS+TSS_GS], 10h +100b	;
	mov	dword [edi+TASK_TSS+TSS_EFLAGS], 202h	 ; eflags
	mov	eax, 800h
	mov	dword [edi+TASK_TSS+TSS_ESP], eax

	mov	dword [edi+TASK_TSS+TSS_CR3], PDT_BASE

      ; GDT descriptor for tss
	mov    eax, edi
	add    eax, TASK_TSS
	mov    edx, 103  ; 104b tss size
	mov    bl, tss_acc
	call   add_gdt_desc
	mov    [edi+TASK_TSS_DESC], ax		; save TSS descriptor

      ; GDT descriptor for task LDT
	mov	eax, edi
	add	eax, TASK_LDT
	mov	edx, 127 ; 128b LDT size
	mov	bl, ldt_acc
	call	add_gdt_desc
	mov	[edi+TASK_LDT_DESC], ax 	; save LDT descriptor
	mov	[edi+TASK_TSS+TSS_LDTR], ax	; move to task LDTR

	push	edi ; task entry

      ; LDT code
	mov	eax, [esi]   ; task offset
	mov	edx, [esi+4] ; task size (bytes)
	mov	bl, code_acc
	mov	bh, 11000000b
	add	edi, (TASK_LDT+8)
	call	set_sys_ldt_desc

      ; LDT data
	xor	eax, eax
	mov	edx, -1
	mov	bl, data_acc
	mov	bh, 11000000b
	add	edi, 8
	call	set_sys_ldt_desc

      ; LDT stack
	mov	eax, [esi+8] ; stack size in bytes
	mov	edx, eax
      ;  mov     dword[edi+TASK_TSS+TSS_ESP], eax
      ; allocate memory from system heap
	call	sys_malloc
	or	eax, eax
	jz	.exit

	mov	bl, data_acc
	mov	bh, 01000000b
	add	edi, 8
	call	set_sys_ldt_desc

	pop	edi ; task entry again

	call	get_PID
	mov	[edi+TASK_PID], ax

	xor	eax, eax
	mov	ax, [edi+TASK_TSS_DESC]

  .exit:
	pop	edi
	pop	edx
	pop	ecx
	pop	ebx
	ret



; ------------------------------------------------------------------------------
; returns edi=TASK structure entry
get_free_task:
	mov	edi, TASK_LIST
    @@: cmp	dword [edi], 0
	jz	.found
	add	edi, TASK_RECSIZE
	cmp	edi, (TASK_LIST+TASK_LIST_SIZE)
	jb	@b
	xor	edi, edi	; if(!found)edi=0
   .found:
	ret

; ------------------------------------------------------------------------------
; returns eax=PID
get_PID:
	mov	eax, [PID_counter]
	inc	eax
	mov	[PID_counter], eax
	ret

; ------------------------------------------------------------------------------
; IN: eax - task offset
;     task size is 1M for testing
add_task:
	pusha

	mov	edi, TASK_LIST
 .next:
	cmp	dword [edi], 0
	je	.found
	cmp	edi, TASK_LIST+TASK_LIST_SIZE
	jb	.next


; messages that can't create more tasks, etc...
	jmp	.exit

 .found:
	; edi = task list entry
	call   clear_task_record

	call   create_tss

	push	eax

	mov    eax, edi
	add    eax, TASK_TSS
	mov    edx, 103
	mov    bl, tss_acc
	call   add_gdt_desc

	mov    [edi+TASK_TSS_DESC], ax		; save TSS descriptor

	mov	eax, edi
	add	eax, TASK_LDT
	mov	edx, 127
	mov	bl, ldt_acc
	call	add_gdt_desc

	mov	[edi+TASK_LDT_DESC], ax 	; save LDT descriptor
	mov	[edi+TASK_TSS+TSS_LDTR], ax	; move to task LDTR

	push	edi
	pop	esi

	pop	eax

	add	esi, TASK_LDT+8
	mov	edx, 100000h/4096    ; !!!!! for testing - task size 1M
	mov	bl, code_acc
	call	set_desc

	push	eax
	add	esi, 8
	sub	eax, 64*1024/4096    ; stack 64k
	mov	edx, 64*1024/4096
	mov	bl, data_acc
	call	set_desc

	pop	eax
	add	esi, 8
	mov	edx, 100000h/4096
	call	set_desc

	add	esi, 8
	mov	eax, 0b8000h
	mov	dx, 1
	call	set_desc

	; set active
	;  !!!

 .exit:
	popa
	ret

; ------------------------------------------------------------------------------
; fills task record with 0s
; IN:  edi - task record offset

clear_task_record:
	push	eax
	push	ecx
	push	edi
	xor	eax, eax
	mov	ecx, TASK_RECSIZE/4
	rep	stosd
	pop	edi
	pop	ecx
	pop	eax
	ret

; ------------------------------------------------------------------------------
; creates TSS with predefined data
; eax = program offset
; edi - task list entry address

PID_counter	dd 0

create_tss:
	pusha
	inc	[PID_counter]
	mov	ebx, [PID_counter]
	mov	[edi+TASK_PID], bx
	mov	dword[edi+TASK_TSS+TSS_EIP], 0;
	mov	word [edi+TASK_TSS+TSS_CS], LDT_CODE
	mov	word [edi+TASK_TSS+TSS_SS], LDT_STACK
	mov	word [edi+TASK_TSS+TSS_ES], LDT_DATA
	mov	word [edi+TASK_TSS+TSS_DS], LDT_DATA
	mov	word [edi+TASK_TSS+TSS_FS], LDT_SCR
	mov	word [edi+TASK_TSS+TSS_GS], LDT_SCR
	mov	dword[edi+TASK_TSS+TSS_EFLAGS], 202h
	mov	dword[edi+TASK_TSS+TSS_ESP],8000h
	mov	dword[edi+TASK_TSS+TSS_CR3],PDT_BASE
	popa
	ret

; ------------------------------------------------------------------------------
; eax = int num
; edx = offset
set_idt_int:
	push	eax
	push	edx
	shl	eax, 3
	add	eax, IDT_BASE
	mov	[eax], dx
	mov	word[eax+2], OSCODESEL
	mov	word[eax+4], 08e00h	; 10001110 - interrupt
	shr	edx, 16
	mov	[eax+6], dx
	pop	edx
	pop	eax
	ret


; ------------------------------------------------------------------------------
; eax - int num
;  dx - task selector
set_idt_task:
	push	eax
	shl	eax, 3
	add	eax, IDT_BASE
	mov	word[eax], 0
	mov	[eax+2], dx
	mov	word[eax+4], 08500h	; 10000101 - task gate
	mov	word[eax+6], 0
	pop	eax
	ret

; ------------------------------------------------------------------------------
; eax - memory to allocate (bytes)
; out:  eax  - pointer to memoy block, 0 if not enough memory
freememptr	dd SYS_MALLOC_BASE

sys_malloc:
	add	eax, [freememptr]
	cmp	eax, SYS_MALLOC_MAX
	jae	@f
	push	[freememptr]
	mov	[freememptr], eax
	pop	eax
	ret
    @@:
	xor	eax, eax
	ret


; ------------------------------------------------------------------------------
; eax - pointer to memory block
; does nothing
sys_free:
	ret