exc00:
	push	excm00
	push	0
	jmp	exchandler
exc01:
	push	excm01
	push	1
	jmp	exchandler
exc02:
	push	excm02
	push	2
	jmp	exchandler
exc03:
	push	excm03
	push	3
	jmp	exchandler
exc04:
	push	excm04
	push	4
	jmp	exchandler
exc05:
	push	excm05
	push	5
	jmp	exchandler
exc06:
	push	excm06
	push	6
	jmp	exchandler
exc07:
	push	excm07
	push	7
	jmp	exchandler
exc08:
	push	excm08
	push	8
	jmp	exchandler
exc09:
	push	excm09
	push	9
	jmp	exchandler
exc0A:
	push	excm0A
	push	10
	jmp	exchandler
exc0B:
	push	excm0B
	push	11
	jmp	exchandler
exc0C:
	push	excm0C
	push	12
	jmp	exchandler
exc0D:
	push	excm0D
	push	13
	jmp	exchandler
exc0E:
	push	excm0E
	push	14
	jmp	exchandler
exc0F:
	push	excm0F
	push	15
	jmp	exchandler
exc10:
	push	excm10
	push	16
	jmp	exchandler
exc11:
	push	excm11
	push	17
	jmp	exchandler
exc12:
	push	excm12
	push	18
	jmp	exchandler
exc13:
	push	excm13
	push	19
	jmp	exchandler
exc14:
	push	excm14
	push	20
	jmp	exchandler
exc15:
	push	excm15
	push	21
	jmp	exchandler
exc16:
	push	excm16
	push	22
	jmp	exchandler
exc17:
	push	excm17
	push	23
	jmp	exchandler
exc18:
	push	excm18
	push	24
	jmp	exchandler
exc19:
	push	excm19
	push	25
	jmp	exchandler
exc1A:
	push	excm1A
	push	26
	jmp	exchandler
exc1B:
	push	excm1B
	push	27
	jmp	exchandler
exc1C:
	push	excm1C
	push	28
	jmp	exchandler
exc1D:
	push	excm1D
	push	29
	jmp	exchandler
exc1E:
	push	excm1E
	push	30
	jmp	exchandler
exc1F:
	push	excm1F
	push	31

exchandler:
	mov	edi, 0b8000h
	mov	eax, 4f004f00h
	mov	ecx, 40
	rep	stosd

	mov	edi, 0b8000h+4
	mov	esi, excmsg
	call	printzs

	pop	eax
	mov	ecx, 1
	mov	edi, 0b8000h+4+24
	call	printeax

	pop	esi
	mov	edi, 0b8000h+36
	call	printzs

	cmp	eax, 0eh
	jne	@f

	mov	edi, 0b8000h+60
	mov	eax, cr2
	mov	ecx, 4
	call	printeax


    @@:

	jmp	$

excmsg		db ' Exception #__:',0
excm00		db 'Divide Error',0
excm01		db 'Debug',0
excm02		db 'NMI Interrupt',0
excm03		db 'Breakpoint',0
excm04		db 'Overflow',0
excm05		db 'BOUND Range Exceeded',0
excm06		db 'Invalid Opcode (Undefined Opcode)',0
excm07		db 'Device Not Available (No Math Coprocessor)',0
excm08		db 'Double Fault',0
excm09		db 'CoProcessor Segment Overrun (reserved)',0
excm0A		db 'Invalid TSS',0
excm0B		db 'Segment Not Present',0
excm0C		db 'Stack Segment Fault',0
excm0D		db 'General Protection',0
excm0E		db 'Page Fault',0
excm0F		db '(Intel reserved)',0
excm10		db 'Floating-Point Error (Math Fault)',0
excm11		db 'Alignment Check',0
excm12		db 'Machine Check',0
excm13		db 'Streaming SIMD Extensions',0
excm14		db '(Intel reserved)',0
excm15		db '(Intel reserved)',0
excm16		db '(Intel reserved)',0
excm17		db '(Intel reserved)',0
excm18		db '(Intel reserved)',0
excm19		db '(Intel reserved)',0
excm1A		db '(Intel reserved)',0
excm1B		db '(Intel reserved)',0
excm1C		db '(Intel reserved)',0
excm1D		db '(Intel reserved)',0
excm1E		db '(Intel reserved)',0
excm1F		db '(Intel reserved)',0
