;
; mgcbean.dos - tiny DOS
; really tiny (a bit more than 4k)
; vladimirfedorov.net (me@vladimirfedorov.net)
; vladimirfedorov.net/en/mgcbean#dos

	use16

include "common.inc"

	org	100h

	mov	ax, cs

	; get current dir (floppy root)
	call	fat12.read
	call	fat12.readdir
	
	; set text video mode
	call	cli.init
	
	; setup interrupts
	call	ints.setupall

	; welcome message
	mov	al, 1
	int	29h

	ccall	console.writeln, ds, hello

	;mov    ah, 9
	;mov    dx, dosstr
	;int    21h

	; command line
	jmp	cli_main
	
	;jmp    $

hello		db " mgcbean.dos 0.1",13,10,"Type '?' for commands.",0

dosstr		db "strange dos string$"

cli_commands:
cmd_cls 	db "CLS",0
cmd_dir 	db "DIR",0
cmd_date	db "DATE",0
cmd_time	db "TIME",0
cmd_ver 	db "VER",0
cmd_help	db "HELP",0
cmd_cd		db "CD",0
cmd_view	db "VIEW",0
cmd_help1	db "HELP",0
cmd_help2	db "H",0
cmd_help3	db "?",0
cmd_test	db "!",0
cmd_unknown:
cli_commands_end:

sys_cs		dw 0	; save current segment before running programms
sys_ds		dw 0
sys_es		dw 0

sys_ss		dw 0
sys_sp		dw 0

FAT_dirsize	dw 4096

prompt	db ">",0

fnspace db "           ",0

include 'console.asm'
include 'cli.asm'
include 'bytes.asm'
include 'strings.asm'
include 'ints.asm'
include 'fdd.asm'
include 'fat12.asm'

filename	rb 12
cli_prompt	rb 80
curpath 	rb 128
cli_input	rb 128

FAT_stsect	rw 1		; starting sector of FAT block

align 16
sector_buffer	rb 2048 	; file operations buffer

align 16
FAT_dir 	rb 4096 	; current directory buffer

align 16
FAT_buffer	rb 4608 	; 9*512 FAT12 sectors

align 16
App_Start:
 