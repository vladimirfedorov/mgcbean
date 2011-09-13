; low-level disk access
;
;
; eax =     [    | ax ]
;            ^^^^ ^^^^
;   device number function number
;
; device number: 0ffxxh - virtual device
;                0ff00h - ramdrive
; 0ff00h-0ff7Fh reserved, 0ff80h-0ffffh - user devices
;
; functions:
;
; ax = 0 - reset
;
; ax = 1 - get state (returns eax=0 now)
;
; ax = 2 - get device info
;  in: edi = buffer for device info
;
; ax = 3 - read sector
;  in: edx - sector number
;      edi - buffer
;
; ax = 4 - write sector
;  in: edx - sector number
;      esi - buffer
;
; ax = 5-7 - reserved
;
; ax = 8 - lock device
;
; ax = 9 - unlock device
;
; -----
; for all functions
; out: if eax==0 - ok, else  - error code



align 4
int38:

	ror	eax, 16

; ramdrive?
	cmp	ax, 0ff00h
	jnz	@f
	ror	eax, 16
	call	dev_ramdrive
	iret

    @@:

	xor	eax, eax
	not	eax
	iret



  .init:
	mov	eax, 38h
	mov	edx, int38
	call	set_idt_int
	ret

; all includes
include 'ramdrive.asm'