; setup interrupt handler
int25.init:
	push	ax, dx
	mov	ax, 25h
	mov	dx, int25.handler
	call	set_interrupt
	pop	dx, ax
	ret
	
; interrupt handler	
int25.handler:
	sti

	push	cs
	pop	ds
	ccall	console.write, cs, int25_unimpl
	ccall	console.writehex, ax 
	ccall	console.writech, 13
	ccall	console.writech, 10
	int	20h
	
	iret
	
int25_unimpl	db "INT 25h Unimplemented function AX=",0