include 'memmap.inc'
include 'structs.inc'
include 'sysconst.inc'
include 'kernel.inc'

	use16
	org 10000h

	cli
	push	cs
	pop	ds		; ds = 1000h
	xor	ax, ax
	mov	es, ax		; es = 0000h

include 'code16.asm'		; ramdrive and video


; Enable A20:
	mov	al, 0d1h
	out	64h, al 	; A20 port
	mov	al, 0dfh
	out	60h, al

; Disable APIC:
	mov	ecx, 01bh	; register number
	rdmsr
	and	ah, 11110111b	; 11th bit
	wrmsr

; Mask NMI
	mov	al, 80h
	out	70h, al
	in	al, 71h

; Set new nmi #s:
	mov	al,11h
	out	0a0h,al
	jmp	$+2-$$
	out	20h, al
	jmp	$+2-$$

	mov	al,28h
	out	0a1h,al
	jmp	$+2-$$
	mov	al,20h
	out	21h,al
	jmp	$+2-$$

	mov	al,02
	out	0a1h,al
	jmp	$+2-$$
	mov	al,04
	out	21h,al
	jmp	$+2-$$

	mov	al,01
	out	0a1h,al
	jmp	$+2-$$
	out	21h,al
	jmp	$+2-$$

	mov	al,0ffh
	out	0a1h,al
	jmp	$+2-$$
	mov	al,0ffh
	out	21h,al
	jmp	$+2-$$

; enable APIC
;        mov     ecx, 1bh
;        rdmsr
;        or      ah, 1000b
;        wrmsr

; move gdt system descriptor presets to gdt
	push	GDT_SEG
	pop	es
	push	cs
	pop	ds
	xor	eax, eax
	xor	edi, edi
	push	edi
	mov	ecx, 20000h/4
	rep	stosd
	pop	edi
	mov	esi, GDT_SYS_PRESET-$$
	mov	ecx, GDT_SYS_PRESET_SIZE/4
	rep	movsd

; move interrupts
	push	IDT_SEG
	pop	es
	xor	edi,edi
	mov	esi, IDT_PRESET_BASE
	mov	ecx, IDT_PRESET_SIZE
	rep	movsd

; values for idtr and gdtr
	mov	word[gdtr-$$], GDT_SIZE
	mov	dword[gdtr+2-$$], GDT_BASE
	lgdt	fword[gdtr-$$]

	mov	word[idtr-$$], IDT_SIZE-1
	mov	dword[idtr+2-$$],IDT_BASE
	lidt	fword[idtr-$$]

; enter pm
	mov	eax, cr0
	or	al, 1
	mov	cr0, eax


	jmp	fword OSCODESEL:code32



gdtr:	dw ?
	dd ?
idtr:	dw ?
	dd ?


GDT_SYS_PRESET:
; +0  word  limit[15..0]
; +2  word  base addr[15..0]
; +4  byte  base addr[23..16]
; +5  byte  type & access
; +6  byte  flags(7..4) and lim[19..16](3..0) 
; +7  byte  base addr[31..24]
	dw 0,0,0,0

	dw -1,0 			; OS code
	db 0,code_acc,11001111b,0

	dw -1,0 			; OS data
	db 0,data_acc,11001111b,0

	dw 0fh, 0h			; OS stack   0fh*4096 = 64k system stack
	db 7,data_acc,11000000b,0	; stack address 70000h..7ffffh

maintask:
	dw 103,stss mod 10000h			  ; main
	db stss/10000h,tss_acc,0,0

task1desc:
	dw 103,utss1 mod 10000h 		  ; task1
	db utss1/10000h,tss_acc,0,0

task2desc:
	dw 103,utss2 mod 10000h 		  ; task2
	db utss2/10000h,tss_acc,0,0

timertask:
	dw 103,ttss mod 10000h			  ; timer
	db ttss/10000h,tss_acc,0,0

GDT_SYS_PRESET_SIZE = $-GDT_SYS_PRESET

; ===========================================================================
;                         32-bit code starts here
; ===========================================================================
	use32
	align 4

code32:

	mov	ax, OSSTACK
	mov	ss, ax
	mov	esi, 0ffffh
	nop
	mov	ax, OSDATASEL
	mov	ds, ax
	mov	es, ax
	mov	fs, ax
	mov	gs, ax

	call	create_umm
	call	create_pdt
	call	set_system_ptes
	mov	eax, PDT_BASE
	mov	cr3, eax
	mov	eax, cr0
	bts	eax, 31
	mov	cr0, eax
	jmp	@f
  @@:

	call	int38.init
	call	fat12io.init
	call	vmm.init


	call	cls

	mov	edi, 0b8000h
	mov	ecx, 40
	mov	eax, 17001700h
	rep	stosd

	mov	edi, 0b8000h
	mov	esi, welcome
	call	printzs

	lea	eax,[int00]
	mov	[ttss_eip],eax
	mov	[ttss_esp],dword 1F000h

	lea	eax,[tsk1]
	mov	[utss1_eip],eax
	mov	[utss1_esp],dword 1F080h

	lea	eax,[tsk2]
	mov	[utss2_eip],eax
	mov	[utss2_esp],dword 1F100h

; ------------------------------------------------------------------------------
;       TEST AREA
; ------------------------------------------------------------------------------

	mov	eax, tsk3
	call	add_task

	call	IRQ01_Init
	call	IRQ12_Init

	mov	edx, printeax
	mov	eax, 40h
	call	set_idt_int

	mov	esi, bootdir
	call	fat12_chdir

	mov	esi, fsysfont
	mov	edi, 380000h
	call	fat12_readAllFile


; ------------------------------------------------------------------------------

	mov	ax, SysTask
	ltr	ax

	and	byte [GDT_BASE+20h +5], 11111101b
	jmp	fword SysTask:0

	mov	al, 0;11111000b
	out	0x21,al

	mov	al, 0;11101111b
	out	0a1h, al


	mov	edx, 01010101h
	sti
	jmp	$


vmm_memory	dd 120000h, 120020h, 0E0000000h, 0F8000000h

file1		dd 0,0,0,0
bootdir 	db 'BOOT       '
fsysfont	db 'SYSF1251   '
testtext	db 'TEST    TXT'

;                  '12345678EXT'
filestruc	dd 0,0,0,0,0,0,0,0
str1		db 'abcdEFGH',0
str2		db 'cdEF',0
str3		db 'Lorem ipsum dolor sit amet,\n%u consectetuer \nadipiscing \nelit.',0
str4		db 'Memory seems to be allocated ;)',0
str5		db '1',0
str6		db " 0f383874666ddeb433998777h-0bhukabuka",0
svalue		db "Value: %x (%i decimal)\n",0

kbd_info	db "Keyboard info: head: %x, tail: %x\n",0
cursor_info	db "Cursor address: %x\n",0
file_cluster	db "File cluster: %i",0

buf16		dd 20202020h,20202020h,20202020h,20202020h
		db 0

prompt		db ']',0
promptch	db '%c', 0
newline 	db "\n",0
command 	dd 0,0,0,0,0,0,0,0,0,0,0
commandhist	dd 0,0,0,0,0,0,0,0,0,0,0

buf1024:
  repeat 1024
	 db 0
  end repeat

task1msg	db 'Switching to Task 1\n',0
task2msg	db 'Switching to Task 2\n',0
task3msg	db 'Switching to Task 3\n',0


int00:
	mov	al,0x20
	out	0x20,al
.mainloop:

	jmp	fword  Task1:0
	out	0x20,al
	and	byte [GDT_BASE+28h+5], 11111101b

	jmp	fword  Task2:0
	out	0x20,al
	and	byte [GDT_BASE+30h+5], 11111101b

	mov	edi, TASK_LIST+TASK_TSS_DESC
	jmp	fword [edi-4]

	out	0x20, al
	xor	ebx, ebx
	mov	bx, [edi]
	add	ebx, GDT_BASE
	and	byte [ebx+5], 11111101b


	jmp	.mainloop




; _____________________________________________________________________________
;
; Task 1 - kernel console
;
tsk1:

;;;; .code

    .mainloop:

	push	edi
	mov	edi, 0b8000h+160-12
	mov	al, [edi]
	inc	al
	stosb
	pop	edi


	stdcall kprintf, prompt
	add	esp, 4
	mov	edi, command
	call	kgets
;        stdcall kprintf, command
;        add     esp, 4

	cmp	[kprintf_col], 0
	je	@f
	mov	[kprintf_col], 0
	inc	[kprintf_row]

    @@:
	cmp	word [command], '?'	; "?",0
	jne	@f
	stdcall kprintf, sys_info
	add	esp, 4
	jmp	.mainloop
    @@:
	cmp	word [command], 'h'	; "h",0
	jne	@f
	stdcall kprintf, sys_info
	add	esp, 4
	jmp	.mainloop
    @@:
	cmp	dword [command], "help" ; "help"
	jne	@f
	stdcall kprintf, sys_info
	add	esp, 4
	jmp	.mainloop
    @@:
	cmp	word [command], '2'	; "h",0
	jne	@f
	mov	eax, 1
	mov	[tsk2_msgbuf], eax

	jmp	.mainloop
    @@:
	cmp	word [command], 'd '
	jne	@f
	stdcall memdump, command
	add	esp, 4

	jmp	.mainloop
    @@:
	cmp	word [command], '+ '
	jne	@f
	stdcall vmm_test.malloc, command
	add	esp, 4

	jmp	.mainloop
    @@:
	cmp	word [command], '- '
	jne	@f
	stdcall vmm_test.free, command
	add	esp, 4

	jmp	.mainloop
    @@:
	cmp	byte [command], 0
	jne	@f
	jmp	.mainloop
    @@:
	; unknown command
	stdcall kprintf, sys_unknown
	add	esp, 4

	jmp	.mainloop

;;;; .data
cmd_help	db 'help',0
cmd_help1	db 'h',0
cmd_help2	db '?',0
sys_info	db "System commands:\nh, help, ? - this help screen\nd address  - memory damp\n+ size     - malloc\n- address  - free\n2 - send test message to the Task 2\n",0
sys_unknown	db "Unknown command\n",0

; _____________________________________________________________________________
;
; Task 2 - test
;
; message buffer
tsk2_msgbuf	dd 0,0

tsk2:

  .mainloop:

	mov	edi, 0b8000h+160-10
	mov	al, [edi]
	inc	al
	stosb

	mov	eax, [tsk2_msgbuf]
	or	eax, eax
	jz	@f

	stdcall kprintf, tsk2_gotmsg
	add	esp, 4
	xor	eax, eax
	mov	[tsk2_msgbuf], eax
    @@:
	jmp	.mainloop

;;;; .data
tsk2_gotmsg	db "I'm task 2!\n",0

; _____________________________________________________________________________
;
; Task 3 - test
;
tsk3:
	push	gs
	pop	es
	mov	edi, 160-8
	xor	eax, eax
    @@: inc	al
	stosb
	dec	edi
	jmp	@b

; ===========================================================================

welcome 	db 'Starting...',0

; ===========================================================================

include 'sysfuncs.asm'

cls:
	pusha
	mov	ecx, 160*25/4
	mov	eax, 07000700h
	mov	edi, 0b8000h
	rep	stosd
	popa
	ret

; Printzs - print a zero-ending string using screen attributes
; IN: ds:esi - zero-ending string to print
;     es:edi - screen
printzs:
	push	eax
.write: lodsb
	or	al, al
	jz	.exit
	stosb
	inc	edi
	jmp	.write
 .exit: pop	eax
	ret


; print eax;
; IN: es:edi - screen offset
;     cl - number of bytes to print, ch - radix
;     eax - number
hexnumbers	db "0123456789ABCDEF"
printeax:
	pusha
	mov	ebx, 10h
	shl	ecx, 3
	ror	eax, cl
	ror	eax, 4
	shr	ecx, 2
   .l1: xor	edx, edx
	mov	ebp, hexnumbers
	rol	eax, 8
	div	ebx
	add	ebp, edx
	mov	dl, [ds:ebp]
	mov	[es:edi], dl
	add	edi,2
	loop	.l1
	popa
	ret



;unhnd_msg       db 'Unhandled exception',0
;unhandled:
;        cli
;        mov     ax,OSDATASEL
;        mov     ss,ax
;        mov     ds,ax
;        mov     es,ax
;;        mov     fs,ax
;        mov     esi, unhnd_msg
;        mov     edi, 0b8000h+160*5
;        call    printzs
;        jmp     $



IDT_PRESET_BASE:

	dw exc00 mod 10000h, OSCODESEL, 8E00h, exc00/10000h
	dw exc01 mod 10000h, OSCODESEL, 8E00h, exc01/10000h
	dw exc02 mod 10000h, OSCODESEL, 8E00h, exc02/10000h
	dw exc03 mod 10000h, OSCODESEL, 8E00h, exc03/10000h
	dw exc04 mod 10000h, OSCODESEL, 8E00h, exc04/10000h
	dw exc05 mod 10000h, OSCODESEL, 8E00h, exc05/10000h
	dw exc06 mod 10000h, OSCODESEL, 8E00h, exc06/10000h
	dw exc07 mod 10000h, OSCODESEL, 8E00h, exc07/10000h
	dw exc08 mod 10000h, OSCODESEL, 8E00h, exc08/10000h
	dw exc09 mod 10000h, OSCODESEL, 8E00h, exc09/10000h
	dw exc0A mod 10000h, OSCODESEL, 8E00h, exc0A/10000h
	dw exc0B mod 10000h, OSCODESEL, 8E00h, exc0B/10000h
	dw exc0C mod 10000h, OSCODESEL, 8E00h, exc0C/10000h
	dw exc0D mod 10000h, OSCODESEL, 8E00h, exc0D/10000h
	dw exc0E mod 10000h, OSCODESEL, 8E00h, exc0E/10000h
	dw exc0F mod 10000h, OSCODESEL, 8E00h, exc0F/10000h
	dw exc10 mod 10000h, OSCODESEL, 8E00h, exc10/10000h
	dw exc11 mod 10000h, OSCODESEL, 8E00h, exc11/10000h
	dw exc12 mod 10000h, OSCODESEL, 8E00h, exc12/10000h
	dw exc13 mod 10000h, OSCODESEL, 8E00h, exc13/10000h
	dw exc14 mod 10000h, OSCODESEL, 8E00h, exc14/10000h
	dw exc15 mod 10000h, OSCODESEL, 8E00h, exc15/10000h
	dw exc16 mod 10000h, OSCODESEL, 8E00h, exc16/10000h
	dw exc17 mod 10000h, OSCODESEL, 8E00h, exc17/10000h
	dw exc18 mod 10000h, OSCODESEL, 8E00h, exc18/10000h
	dw exc19 mod 10000h, OSCODESEL, 8E00h, exc19/10000h
	dw exc1A mod 10000h, OSCODESEL, 8E00h, exc1A/10000h
	dw exc1B mod 10000h, OSCODESEL, 8E00h, exc1B/10000h
	dw exc1C mod 10000h, OSCODESEL, 8E00h, exc1C/10000h
	dw exc1D mod 10000h, OSCODESEL, 8E00h, exc1D/10000h
	dw exc1E mod 10000h, OSCODESEL, 8E00h, exc1E/10000h
	dw exc1F mod 10000h, OSCODESEL, 8E00h, exc1F/10000h
; IRQ00
	dw 0, TimerTask, task_gate*256 + 0, 0			; timer
; IRQ01
	dw IRQ01 mod 10000h, OSCODESEL, 8E00h, IRQ01/10000h	; keyboard
	dw 0,0,0,0
	dw 0,0,0,0
	dw 0,0,0,0
	dw 0,0,0,0
	dw 0,0,0,0
	dw 0,0,0,0
	dw 0,0,0,0
	dw 0,0,0,0
	dw 0,0,0,0
	dw 0,0,0,0

__IRQ12:
;        dw IRQ12 mod 10000h, OSCODESEL, 8E00h, IRQ12/10000h     ; mouse


IDT_PRESET_SIZE=$-IDT_PRESET_BASE


TSS_Base:

stss:	dw 0, 0 		; back link
	dd 0			; ESP0
	dw 0, 0 		; SS0, reserved
	dd 0			; ESP1
	dw 0, 0 		; SS1, reserved
	dd 0			; ESP2
	dw 0, 0 		; SS2, reserved
	dd PDT_BASE		; CR3
stss_eip:
	dd 0, 0 		; EIP, EFLAGS
	dd 0, 0, 0, 0		; EAX, ECX, EDX, EBX
stss_esp:
	dd 0, 0, 0, 0		; ESP, EBP, ESI, EDI
	dw OSDATASEL, 0 	; ES, reserved
	dw OSCODESEL, 0 	; CS, reserved
	dw OSDATASEL, 0 	; SS, reserved
	dw OSDATASEL, 0 	; DS, reserved
	dw OSDATASEL, 0 	; FS, reserved
	dw OSDATASEL, 0 	; GS, reserved
	dw 0, 0 		; LDT, reserved
	dw 0, 0 		; debug, IO perm. bitmap

utss1:	dw 0, 0 		; back link
	dd 0			; ESP0
	dw 0, 0 		; SS0, reserved
	dd 0			; ESP1
	dw 0, 0 		; SS1, reserved
	dd 0			; ESP2
	dw 0, 0 		; SS2, reserved
	dd PDT_BASE		; CR3
utss1_eip:
	dd 0, 0x200		; EIP, EFLAGS (EFLAGS=0x200 for ints)
	dd 0, 0, 0, 0		; EAX, ECX, EDX, EBX
utss1_esp:
	dd 0, 0, 0, 0		; ESP, EBP, ESI, EDI
	dw OSDATASEL, 0 	; ES, reserved
	dw OSCODESEL, 0 	; CS, reserved
	dw OSDATASEL, 0 	; SS, reserved
	dw OSDATASEL, 0 	; DS, reserved
	dw OSDATASEL, 0 	; FS, reserved
	dw OSDATASEL, 0 	; GS, reserved
	dw 0, 0 		; LDT, reserved
	dw 0, 0 		; debug, IO perm. bitmap

utss2:	dw 0, 0 		; back link
	dd 0			; ESP0
	dw 0, 0 		; SS0, reserved
	dd 0			; ESP1
	dw 0, 0 		; SS1, reserved
	dd 0			; ESP2
	dw 0, 0 		; SS2, reserved
	dd PDT_BASE		; CR3
utss2_eip:
	dd 0, 0x200		; EIP, EFLAGS (EFLAGS=0x200 for ints)
	dd 0, 0, 0, 0		; EAX, ECX, EDX, EBX
utss2_esp:
	dd 0, 0, 0, 0		; ESP, EBP, ESI, EDI
	dw OSDATASEL, 0 	; ES, reserved
	dw OSCODESEL, 0 	; CS, reserved
	dw OSDATASEL, 0 	; SS, reserved
	dw OSDATASEL, 0 	; DS, reserved
	dw OSDATASEL, 0 	; FS, reserved
	dw OSDATASEL, 0 	; GS, reserved
	dw 0, 0 		; LDT, reserved
	dw 0, 0 		; debug, IO perm. bitmap


ttss:	dw 0, 0 		; back link
	dd 0			; ESP0
	dw 0, 0 		; SS0, reserved
	dd 0			; ESP1
	dw 0, 0 		; SS1, reserved
	dd 0			; ESP2
	dw 0, 0 		; SS2, reserved
	dd PDT_BASE		; CR3
ttss_eip:
	dd 0, 0x00		; EIP, EFLAGS (EFLAGS=0x200 for ints)
	dd 0, 0, 0, 0		; EAX, ECX, EDX, EBX
ttss_esp:
	dd 0, 0, 0, 0		; ESP, EBP, ESI, EDI
	dw OSDATASEL, 0 	; ES, reserved
	dw OSCODESEL, 0 	; CS, reserved
	dw OSDATASEL, 0 	; SS, reserved
	dw OSDATASEL, 0 	; DS, reserved
	dw OSDATASEL, 0 	; FS, reserved
	dw OSDATASEL, 0 	; GS, reserved
	dw 0, 0 		; LDT, reserved
	dw 0, 0 		; debug, IO perm. bitmap

SYSFONT_BUF:
include 'fonts/sysf1251.inc'
SYSFONT equ (SYSFONT_BUF+16)

include 'kstdio.asm'
include 'exc.asm'
include 'vmm.asm'
include 'int38.asm'
include 'fat12io.asm'
include 'keyboard.asm'
include 'mouse.asm'
include 'irq01.asm'
include 'strings.asm'
include 'gfx.asm'
include 'ptrlist.asm'



