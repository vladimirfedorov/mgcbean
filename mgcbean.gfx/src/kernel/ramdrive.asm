

dev_ramdrive:

	cmp	ax, 3
	je	dev_ramdrive_readsect

	cmp	ax, 4
	je	dev_ramdrive_writesect

;dev_ramdrive_default:
	xor	eax, eax
	not	eax
	ret

; in: edx - sector #
;     edi - buffer
dev_ramdrive_readsect:
	push	ecx
	push	esi
	mov	ecx, 512/4
	mov	esi, edx
	shl	esi, 9
	add	esi, RAMDRV_BASE
	rep	movsd
	pop	esi
	pop	ecx
	ret

; in: edx - sector #
;     esi - buffer
dev_ramdrive_writesect:
	push	ecx
	push	edi
	mov	ecx, 512/4
	mov	edi, edx
	shl	edi, 9
	add	edi, RAMDRV_BASE
	rep	movsd
	pop	edi
	pop	ecx
	ret


