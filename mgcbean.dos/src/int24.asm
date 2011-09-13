; setup interrupt handler
int24.init:
	push	ax, dx
	mov	ax, 24h
	mov	dx, int24.handler
	call	set_interrupt
	pop	dx, ax
	ret
	
; interrupt handler	
int24.handler:
	sti

	push	cs
	pop	ds
	ccall	console.write, cs, int24_unimpl
	ccall	console.writehex, ax 
	ccall	console.writech, 13
	ccall	console.writech, 10
	int	20h
	
	iret
	
int24_unimpl	db "INT 24h Unimplemented function AX=",0