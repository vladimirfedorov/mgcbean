; setup interrupt handler
int2E.init:
	push	ax, dx
	mov	ax, 2Eh
	mov	dx, int2E.handler
	call	set_interrupt
	pop	dx, ax
	ret
	
; interrupt handler	
int2E.handler:
	sti

	push	cs
	pop	ds
	ccall	console.write, cs, int2E_unimpl
	ccall	console.writehex, ax 
	ccall	console.writech, 13
	ccall	console.writech, 10
	int	20h
	
	iret
	
int2E_unimpl	db "INT 2Eh Unimplemented function AX=",0