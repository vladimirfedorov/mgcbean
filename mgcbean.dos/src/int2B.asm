; setup interrupt handler
int2B.init:
	push	ax, dx
	mov	ax, 2Bh
	mov	dx, int2B.handler
	call	set_interrupt
	pop	dx, ax
	ret
	
; interrupt handler	
int2B.handler:
	sti

	push	cs
	pop	ds
	ccall	console.write, cs, int2B_unimpl
	ccall	console.writehex, ax 
	ccall	console.writech, 13
	ccall	console.writech, 10
	int	20h
	
	iret
	
int2B_unimpl	db "INT 2Bh Unimplemented function AX=",0