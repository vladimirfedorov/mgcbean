; setup interrupt handler
int23.init:
	push	ax, dx
	mov	ax, 23h
	mov	dx, int23.handler
	call	set_interrupt
	pop	dx, ax
	ret
	
; interrupt handler	
int23.handler:
	sti
	int	20h
	iret