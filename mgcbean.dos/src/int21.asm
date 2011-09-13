; setup interrupt handler
int21.init:
	push	ax, dx
	mov	ax, 21h
	mov	dx, int21.handler
	call	set_interrupt
	pop	dx, ax
	ret
	
; interrupt handler	
int21.handler:
	sti

	cmp	ah, 0
	je	int21_00	; terminate

	cmp	ah, 1
	je	int21_01	; read character with echo (my - kbd only!)
	
	cmp	ah, 2
	je	int21_02	; output character
	
	cmp	ah, 3
	je	int21_03	; read from STDAUX
	
	cmp	ah, 4
	je	int21_04	; write to STDAUX
	
	cmp	ah, 5
	je	int21_05	; write to printer
	
	cmp 	ah, 6
	je	int21_06	; direct console input/output
	
	cmp	ah, 7
	je	int21_07	; char input w/o echo
	
	cmp	ah, 8
	je	int21_08	; the same buth with ^C/^Break check
	
	cmp	ah, 9
	je	int21_09	; write $-terminating string

	cmp	ah, 0ah
	je	int21_0A	; buffered input
	
	cmp	ah, 0bh
	je	int21_0B	; get STDIN status

	cmp	ah, 30h
	je	int21_30	; DOS version (let's say we're 6.22 :)

	cmp	ah, 4ch
	je	int21_4C	; exit program

	push	cs
	pop	ds
	ccall	console.write, cs, int21_unimpl
	ccall	console.writehex, ax 
	ccall	console.writech, 13
	ccall	console.writech, 10
	int	20h
int21_exit:
	iret		

int21_unimpl	db "INT 21h Unimplemented function AX=",0
			
	
int21_00:			; terminate
	int	20h
	jmp	int21_exit
	
int21_01:			; read character with echo (my - kbd only!)
	call	console.readch
	jmp	int21_exit
	
int21_02:			; output character
	mov	al, dl
	ccall	console.writech, ax
	jmp	int21_exit
	
int21_03:			; read from STDAUX (COM1)
	jmp	int21_exit
	
int21_04:			; write to STDAUX (COM2)
	jmp	int21_exit
	
int21_05:			; write to printer
	push	ax, dx
	mov	ah, 0
	mov	dx, 0
	int	17h
	pop	dx, ax
	jmp	int21_exit
	
int21_06:			; direct console input/output
	cmp	dl, 0FFh	; FF=input, otherwise output dl
	je	.input
	mov	al, dl
	ccall	console.writech, ax
	jmp	.exit
    .input:
    	mov	ax, 0100h	; check for a keystroke
    	int	16h
    .exit:
	jmp	int21_exit
	
int21_07:			; char input w/o echo
	xor	ax, ax		; read keystroke 
	int	16h
	jz	.exit
	mov	ah, 1
	int	16h
    .exit:	
	jmp	int21_exit
	
int21_08:			; the same buth with ^C/^Break check
	call	console.readch
	jmp	int21_exit
	
int21_09:
	push	si
	mov	si, dx
    .l1:
	lodsb
	cmp	al, '$'
	je	.exit
	int	29h
	jmp	.l1
    .exit:
    	pop	si
	jmp	int21_exit

int21_0A:
	jmp	int21_exit

int21_0B:
	jmp	int21_exit

int21_0C:
	jmp	int21_exit

int21_0D:
	jmp	int21_exit

int21_0E:
	jmp	int21_exit

int21_0F:
	jmp	int21_exit

int21_10:
	jmp	int21_exit

int21_11:
	jmp	int21_exit

int21_12:
	jmp	int21_exit

int21_13:
	jmp	int21_exit

int21_14:
	jmp	int21_exit

int21_15:
	jmp	int21_exit

int21_16:
	jmp	int21_exit

int21_17:
	jmp	int21_exit

int21_18:			; null function
	jmp	int21_exit

int21_19:
	jmp	int21_exit

int21_1A:
	jmp	int21_exit

int21_1B:
	jmp	int21_exit

int21_1C:
	jmp	int21_exit

int21_1D:			; null function
	jmp	int21_exit

int21_1E:			; null function
	jmp	int21_exit

int21_1F:
	jmp	int21_exit

int21_20:			; null function
	jmp	int21_exit

int21_21:
	jmp	int21_exit

int21_22:
	jmp	int21_exit

int21_23:
	jmp	int21_exit

int21_24:
	jmp	int21_exit

int21_25:
	jmp	int21_exit

int21_26:
	jmp	int21_exit

int21_27:
	jmp	int21_exit

int21_28:
	jmp	int21_exit

int21_29:
	jmp	int21_exit

int21_2A:
	jmp	int21_exit

int21_2B:
	jmp	int21_exit

int21_2C:
	jmp	int21_exit

int21_2D:
	jmp	int21_exit

int21_2E:
	jmp	int21_exit

int21_2F:
	jmp	int21_exit

int21_30:
	mov	ax, 0622h
	jmp	int21_exit

int21_31:
	jmp	int21_exit

int21_32:
	jmp	int21_exit

int21_33:
	jmp	int21_exit

int21_34:
	jmp	int21_exit

int21_35:
	jmp	int21_exit

int21_36:
	jmp	int21_exit

int21_37:
	jmp	int21_exit

int21_38:
	jmp	int21_exit

int21_39:
	jmp	int21_exit

int21_3A:
	jmp	int21_exit

int21_3B:
	jmp	int21_exit

int21_3C:
	jmp	int21_exit

int21_3D:
	jmp	int21_exit

int21_3E:
	jmp	int21_exit

int21_3F:
	jmp	int21_exit























int21_4C:
	int	20h
	jmp	int21_exit	; just in case

			