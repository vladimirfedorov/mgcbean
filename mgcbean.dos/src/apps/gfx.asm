	org	100h

	mov	ah, 0
	mov	al, 12h ; 640x480
	int	10h


	mov	cx, 479
  .l1:	push	cx
	mov	dx, cx
	mov	cx, 639
  .l2:	inc	al
	mov	ah, 0ch
	int	10h
	loop	.l2
	pop	cx
	loop	.l1


	mov	ax, 0
	int	16h

	mov	ax, 4c00h
	int	21h
