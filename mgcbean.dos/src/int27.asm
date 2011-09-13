; setup interrupt handler
int27.init:
	push	ax, dx
	mov	ax, 27h
	mov	dx, int27.handler
	call	set_interrupt
	pop	dx, ax
	ret
	
; interrupt handler	
int27.handler:
	sti

	push	cs
	pop	ds
	ccall	console.write, cs, int27_unimpl
	ccall	console.writehex, ax 
	ccall	console.writech, 13
	ccall	console.writech, 10
	int	20h
	
	iret
	
int27_unimpl	db "INT 27h Unimplemented function AX=",0