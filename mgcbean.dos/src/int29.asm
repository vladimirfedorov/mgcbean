; setup interrupt handler
int29.init:
	push	ax, dx
	mov	ax, 29h
	mov	dx, int29.handler
	call	set_interrupt
	pop	dx, ax
	ret
	
; interrupt handler
int29.handler:
	sti
	mov	ah, 0eh
	int	10h
	iret