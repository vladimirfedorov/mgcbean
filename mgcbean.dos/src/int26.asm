; setup interrupt handler
int26.init:
	push	ax, dx
	mov	ax, 26h
	mov	dx, int26.handler
	call	set_interrupt
	pop	dx, ax
	ret
	
; interrupt handler	
int26.handler:
	sti

	push	cs
	pop	ds
	ccall	console.write, cs, int26_unimpl
	ccall	console.writehex, ax 
	ccall	console.writech, 13
	ccall	console.writech, 10
	int	20h
	
	iret
	
int26_unimpl	db "INT 26h Unimplemented function AX=",0