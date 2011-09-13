ints.setupall:

	call	int20.init	; Terminate programm
	call	int21.init	; Function calls
	call	int22.init	; return address
	call	int23.init	; ^C/^Break control
	call	int24.init	; critical error handler
	call	int25.init	; abs disk read
	call	int26.init	; abs disk write
	call	int27.init	; TSR
	call	int28.init	; DOS Idle
	call	int29.init	; Fast console output
	call	int2B.init	; reserved
	call	int2C.init	; reserved
	call	int2D.init	; reserved
	call	int2E.init	; pass command for execution 

	ret

; IN: ax = int num
;     ds = handler segment
;     dx = handler offset
set_interrupt:
	push	es, di
	push	0
	pop	es
	mov	ah, 0
	mov	di, ax
	shl	di, 2	
	mov	[es:di], dx
	mov	[es:di+2], ds	; this code segment
	pop	di, es
	ret
	
include 'int20.asm'
include 'int21.asm'
include 'int22.asm'
include 'int23.asm'
include 'int24.asm'
include 'int25.asm'
include 'int26.asm'
include 'int27.asm'
include 'int28.asm'
include 'int29.asm'
include 'int2B.asm'
include 'int2C.asm'
include 'int2D.asm'
include 'int2E.asm'
        	