; setup interrupt handler
int22.init:
	push	ax, dx
	mov	ax, 22h
	mov	dx, cli_main
	call	set_interrupt
	pop	dx, ax
	ret
	
	