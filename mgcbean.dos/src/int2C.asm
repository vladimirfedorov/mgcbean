; setup interrupt handler
int2C.init:
	push	ax, dx
	mov	ax, 2Ch
	mov	dx, int2C.handler
	call	set_interrupt
	pop	dx, ax
	ret
	
; interrupt handler	
int2C.handler:
	sti

	push	cs
	pop	ds
	ccall	console.write, cs, int2C_unimpl
	ccall	console.writehex, ax 
	ccall	console.writech, 13
	ccall	console.writech, 10
	int	20h
	
	iret
	
int2C_unimpl	db "INT 2Ch Unimplemented function AX=",0