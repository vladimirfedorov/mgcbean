; setup interrupt handler
int28.init:
	push	ax, dx
	mov	ax, 28h
	mov	dx, int28.handler
	call	set_interrupt
	pop	dx, ax
	ret
	
; interrupt handler	
int28.handler:
	sti

	push	cs
	pop	ds
	ccall	console.write, cs, int28_unimpl
	ccall	console.writehex, ax 
	ccall	console.writech, 13
	ccall	console.writech, 10
	int	20h
	
	iret
	
int28_unimpl	db "INT 28h Unimplemented function AX=",0