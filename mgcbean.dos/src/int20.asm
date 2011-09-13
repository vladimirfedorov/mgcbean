; setup interrupt handler
int20.init:
	push	ax, dx
	mov	ax, 20h
	mov	dx, int20.handler
	call	set_interrupt
	pop	dx, ax
	ret
	
; interrupt handler	
int20.handler:
	mov	ax, 0
	mov	ds, ax
	mov	si, 22h
	shl	si, 2	; return addres
	
	mov	ax, [si+2]	; segment
	mov	ds, ax
	mov	es, ax	
	
	mov	ax, [sys_ss]
	mov	ss, ax
	mov	sp, [sys_sp] 	
	
	sti
	int	22h
	jmp	$
		