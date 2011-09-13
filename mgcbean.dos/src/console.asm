include 'common.inc'

console.color	db 07 

; console.setcolor(color) 
console.setcolor:
	push	ax, bx, bp
	mov	ah, 0bh
	mov	bp, sp
	add	bp, (2+2*3)
	;lea	bp, [sp+2+2*3]
	mov	bx, [bp]
	mov	bh, 0
	mov	[console.color], bl
	int	10h
	pop	bp, bx, ax
	ret


; returns al = char
console.readch:
	mov	ah, 0
	int	16h
	ret

; console.readln(seg, *ptr)
console.readln:
	push	ax, bx, es, di, bp, si
	mov	bp, sp
	;lea	bp, [sp+2+2*5]
	mov	bp, sp
	add	bp, (2+2*6)
	mov	ax, [bp]	; segment
	mov 	es, ax	
	mov	di, [bp+2]
	mov	si, di		; original string pointer
    .l1:	
	mov	ah, 00h
	int	16h

	cmp	al, 13		; [Enter]?
	je	.exit

	cmp	al, 8		; backspace?
	jne	.store
	cmp	di, si
	jle	.no_output
	dec	di
	
	push	ax, cx
	ccall	console.writech, ax
	mov	ax, 0A00h
	xor	bx, bx
	mov	cx, 1
	mov	bl, [console.color]
	int	10h
	pop	cx, ax
	
	jmp	.no_output
	

    .store:
	stosb
    .output:
	ccall	console.writech, ax
    .no_output:


	jmp	.l1
	
    .exit:
	ccall	console.writech, 13	
    	ccall	console.writech, 10
	xor	ax, ax
    	stosb
    	
	pop	si, bp, di, es, bx, ax
    	ret
	

; console.writeln(seg, *ptr)
console.write:
	push	ax, ds, si, bp
	;lea	bp, [sp+2+2*4]
	mov	bp, sp
	add	bp, (2+2*4)
	mov	ax, [bp]	; segment
	mov	ds, ax
	mov	si, [bp+2]
    .l1:	
	lodsb
	or	al, al		; end of string
	jz	.exit
	ccall	console.writech, ax
	jmp 	.l1
    .exit:	
	pop	bp, si, ds, ax
	ret


; console.writeln(seg, *ptr)
console.writeln:
	push	ax, dx,  bp
	mov	bp, sp
	add	bp, (2+2*3)
	mov	ax, [bp]
	mov	dx, [bp+2]
	ccall	console.write, ax, dx
	ccall	console.writech, 13
	ccall	console.writech, 10
	pop	bp, dx, ax
	ret


; console.writech(char)
console.writech:
	push	ax, bx, cx, bp, si, di
	mov	bp, sp
	add	bp, (2+2*6)
	mov	ax, [bp]
	mov	ah, 0Eh
	xor	bx, bx
	mov	cx, bx
	mov	bl, [console.color]
	inc	cx
	int	10h
	pop	di, si, bp, cx, bx, ax
	ret
	


; console.writehex(wnum)
console.writehex:
	push	es, di, cx, ax, bp
	mov	bp, sp
	add	bp, (2+2*5)
	mov	cx, 2
	mov	ax, [bp]
	call	console_printax
	pop	bp, ax, cx, di, es
	ret


; print eax;
; IN: es:edi - screen offset
;     cl - number of bytes to print
;     eax - number
console_hexnumbers	db "0123456789ABCDEF"
console_printax:
	pusha
	and	ecx, 0ffffh
	mov	bx, 10h
	shl	ecx, 3
	ror	ax, cl
	ror	ax, 4
	shr	ecx, 2
   .l1: xor	dx, dx
	mov	bp, console_hexnumbers
	rol	ax, 8
	div	bx
	add	bp, dx
	mov	dl, [ds:bp]
; 	mov	[es:edi], dl
; 	add	edi,2
	
	ccall	console.writech, dx
	
	loop	.l1
	popa
	ret	