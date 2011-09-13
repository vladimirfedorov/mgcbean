; 16-bit version of bytes.asm

if ~ defined __BYTES_ASM__
define __BYTES_ASM_

include 'common.inc'

; ------------------------------------------------------------------------------
; bytes.move(seg1, *ptr1, seg2, *ptr2, count)
; move memory block <count> bytes from <ptr1> to <ptr2>
bytes.move:
	push	ax, cx, di, si, ds, es, bp
	
	mov	bp, sp
	add	bp, (2+2*7)

	mov	ax, [bp]
	mov	ds, ax
	mov	si, [bp+2]	; ptr1
	mov	ax, [bp+4]
	mov	es, ax
	mov	di, [bp+6]	; ptr2
	mov	cx, [bp+8]	; number of bytes
	
	cmp	cx, 0
	jz	.exit
	
	cmp	si, di
	je	.exit
	jb	.copy_reverse

	cld
	rep	movsb
	jmp	.exit
    
    .copy_reverse:
    	dec	cx
	add	si, cx
	add	di, cx
	inc	cx
		
	std
	rep	movsb
	cld
		
    .exit:
	pop	bp, es, ds, si, di, cx, ax
	ret

; ------------------------------------------------------------------------------
; bytes.compare(seg1, *ptr1, seg2, *ptr2, count)
; return zf set if byte chains are equal 
bytes.compare:
	push	cx, si, di, ax, ds, es, bp
	
	mov 	bp, sp
	add	bp, (2+2*7)
	mov	ax, [bp]
	mov	ds, ax	
	mov	si, [bp+2]	; ptr1

	mov	ax, [bp+4]
	mov	es, ax	
	mov	di, [bp+6]	; ptr2
	
	mov	cx, [bp+8]	; number of bytes

	cld
    .l1:
    	lodsb
	scasb
	jne	.exit
	loop	.l1
	xor	ax, ax	; zf=1		
    .exit:
	pop	bp, es, ds, ax, di, si, cx
	ret

; ------------------------------------------------------------------------------
; bytes.fill(seg, *ptr, ch, count)
; fill memory region <count> bytes from <ptr> with <ch> chars 
bytes.fill:
	push	di, cx, ax, bp, es
	mov	bp, sp
	add	bp, (2+2*5)
	mov	ax, [bp]
	mov	es, ax
	mov	di, [bp+2]
	mov	ax, [bp+4]
	mov	cx, [bp+6]
	rep	stosb
	pop	es, bp, ax, cx, di
	ret

end if ; __BYTES_ASM__