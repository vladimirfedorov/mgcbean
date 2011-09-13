; setup interrupt handler
int2D.init:
	push	ax, dx
	mov	ax, 2Dh
	mov	dx, int2D.handler
	call	set_interrupt
	pop	dx, ax
	ret
	
; interrupt handler	
int2D.handler:
	sti

	push	cs
	pop	ds
	ccall	console.write, cs, int2D_unimpl
	ccall	console.writehex, ax 
	ccall	console.writech, 13
	ccall	console.writech, 10
	int	20h
	
	iret
	
int2D_unimpl	db "INT 2Dh Unimplemented function AX=",0