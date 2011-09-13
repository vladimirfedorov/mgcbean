cli.init:
	call	cli_checkvmode
	ret
cli_main:
	;check video mode
	call	cli_checkvmode

	; define prompt
	
	
	; check cursor position
	mov	ah, 03
	mov	bx, 0
	int	10h
	cmp	dl, 0	; leftmost column
	je	@f
	ccall	console.writech, 13
	ccall	console.writech, 10
   @@:
	; display prompt
	
	;ccall  console.write, ds, cli_prompt
	ccall	console.write, ds, prompt
	
	; read command
	;hlt
	ccall	console.readln, ds, cli_input
	ccall	string.trim, cli_input
	ccall	string.toupper, cli_input
	
	; action
	
	;ccall  console.writeln, ds, cli_input
	
;       mov     eax, dword [ds:cli_input]
;       cmp     eax, "DATE"
;       je      cli_showdate
;       
;       cmp     eax, "TIME"
;       je      cli_showtime
	
	call	cli_getcommand
	cmp	dx, cmd_cls
	je	cli_clear
	
	cmp	dx, cmd_date
	je	cli_showdate
	
	cmp	dx, cmd_date
	je	cli_showdate

	cmp	dx, cmd_time
	je	cli_showtime

	cmp	dx, cmd_ver
	je	cli_showver
	
	cmp	dx, cmd_dir
	je	cli_dir
	
	cmp	dx, cmd_cd
	je	cli_cd
	
	cmp	dx, cmd_view
	je	cli_view
	
	cmp	dx, cmd_test
	je	cli_test
	
	cmp	dx, cmd_help1
	je	cli_info
	cmp	dx, cmd_help2
	je	cli_info
	cmp	dx, cmd_help3
	je	cli_info

	cmp	byte [cli_input], 0
	je	cli_main 

	call	cli_run 	; check if we can run file
	jnc	cli_main


	ccall	console.writeln, ds, cli_unknown

	; wait for the next command
	jmp	cli_main

cli_version	db "mgcbean.dos version 0.1",0

cli_showver:
	ccall	console.writeln, ds, cli_version
	jmp	cli_main

cli_unknown	db "Bad command or file name",0


cli_cls 	db "Clearing screen error",0
cli_clear:
	; scroll window up
	mov	ax, 0600h
	mov	bh, [console.color]
	mov	cx, 0
	mov	dx, 1950h
	int	10h
	; set cursor position
	mov	ah, 2
	mov	bx, 0
	mov	dx, 0
	int	10h
	jmp	cli_main	


cli_dir:
	mov	si, FAT_dir
	
	mov	cx, 4096/32	; number of dir entries
    .l1:
	
	cmp	byte[si], 0
	je	.exit
	cmp	byte[si], 0e5h	; deleted
	je	.l11
	cmp	byte[si], 05h
	jne	@f
	add	byte[si], 0e0h
    @@:
	mov	al, [si+11]	; attr
	and	al, 0111b
	cmp	al, 7		; part of a long name?
	je	.l11


	test	byte[si+11], 00010000b	; attr=dir?
	jz	@f
	ccall	console.writech, '['
    @@: 
	call	cli_printfilename
		
	test	byte[si+11], 00010000b	; attr=dir?
	jz	@f
	ccall	console.writech, ']'
    @@: 
	ccall	console.writech, 13
	ccall	console.writech, 10
    .l11:
	
	add	si, 20h
	loop	.l1


    .exit:

	jmp	cli_main


cli_nodir	db "The system cannot find the path specified",0
cli_cd:
	mov	si, cli_input
	add	si, 2
	ccall	string.trim, si
	;ccall  console.writeln, ds, si
	
	cmp	byte [si], '\'
	jne	@f
	call	fat12.readdir
	jmp	cli_main
    @@:
	cmp	byte [si], '/'
	jne	@f
	call	fat12.readdir
	jmp	cli_main
    @@:
	
	mov	di, fnspace
	call	fat12_preparefilename
;       ccall   console.writech, "'"
;       ccall   console.write, ds, fnspace
;       ccall   console.writech, "'"
	
;       ccall   console.writech, 13
;       ccall   console.writech, 10

	cmp	byte [fnspace], " "
	je	@f

	;pusha
	ccall	fat12.cd, fnspace
	;popa
	
	cmp	ax, -1
	jne	@f
	ccall	console.writeln, ds, cli_nodir
    @@: 
	
	jmp	cli_main


cli_nofile	db "The system cannot find the file specified",0
cli_view:
	mov	si, cli_input
	add	si, 4
	ccall	string.trim, si
	
	mov	di, fnspace
	call	fat12_preparefilename

;       ccall   console.writech, "'"
;       ccall   console.write, ds, fnspace
;       ccall   console.writech, "'"
;       
;       ccall   console.writech, 13
;       ccall   console.writech, 10

	cmp	byte [fnspace], " "
	je	.exit

	mov	di, fnspace
	call	fat12_findfile
	cmp	ax, -1
	jne	@f
	ccall	console.writeln, ds, cli_nofile
	jmp	cli_main
    @@: 
	mov	dx, [si+1ch]	; file size
	cmp	dx, 2048	; file buffer is 2048 bytes only
	jbe	@f
	mov	dx, 2048
    @@:
	
	ccall	bytes.fill, ds, sector_buffer, 0, 2048
	
	;mov    bx, 0900h
	xor	ebx, ebx
	mov	bx, ds
	shl	ebx, 4
	add	bx, sector_buffer 
	shr	ebx, 4
	
	mov	cx, 4		; 512*4
	call	fat12_loadfile
	
	mov	si, sector_buffer
	mov	cx, dx		; file size
	cmp	cx, 0
	je	.exit
	
    .l1:
	lodsb
	ccall	console.writech, ax
	loop	.l1
    .exit:	
	jmp	cli_main

; IN: si - filename padded with spaces
cli_printfilename:
	push	cx, si
	mov	cx, 8
    .name:	
	lodsb
	cmp	al, ' '
	je	.ext 
	ccall	console.writech, ax
	loop	.name
	
    .ext:
	add	si, cx
	cmp	cx, 0
	je	@f
	dec	si
    @@:
	cmp	byte[si], ' '
	je	.exit		; no extension
	ccall	console.writech, '.'
	mov	cx, 3
    .ext1:
	lodsb
	cmp	al, ' '
	je	.exit
	ccall	console.writech, ax	
	loop	.ext1
	
    .exit:	
	pop	si, cx
	ret


cli_dateprompt	db "The current date is: ",0
cli_datebuf	db "dd.MM.20yy",0
cli_showdate:
	ccall	console.write, ds, cli_dateprompt
	mov	al, 07		; date
	call	cmos_readBCD
	mov	[cli_datebuf], ah
	mov	[cli_datebuf+1], al
	
	mov	al, 08		; month
	call	cmos_readBCD
	mov	[cli_datebuf+3], ah
	mov	[cli_datebuf+4], al
	
	mov	al, 09
	call	cmos_readBCD
	mov	[cli_datebuf+8], ah
	mov	[cli_datebuf+9], al
	
	ccall	console.writeln, ds, cli_datebuf
		
	jmp	cli_main

cli_timeprompt	db "The current time is: ",0
cli_timebuf	db "hh:mm:ss",0
cli_showtime:
	ccall	console.write, ds, cli_timeprompt
	mov	al, 04		; hours
	call	cmos_readBCD
	mov	[cli_timebuf], ah
	mov	[cli_timebuf+1], al
	
	mov	al, 02		; minutes
	call	cmos_readBCD
	mov	[cli_timebuf+3], ah
	mov	[cli_timebuf+4], al
	
	mov	al, 0		; seconds
	call	cmos_readBCD
	mov	[cli_timebuf+6], ah
	mov	[cli_timebuf+7], al
	
	ccall	console.writeln, ds, cli_timebuf
		
	jmp	cli_main

; IN: al=CMOS address
cmos_readBCD:
	out	70h, al
	jmp	$+2
	in	al, 71h
	mov	ah, al
	shr	ah, 4
	and	ax, 0f0fh
	or	ax, 3030h
	ret	
	
; dx=command label
; (e.g. cmp dx, cmd_cls)
cli_getcommand:
	push	si	
	mov	si, cli_input
	mov	di, cli_commands
	
    .l1:
	mov	dx, di
	call	cli_compare
	je	.exit
	cmp	di, cli_commands_end
	jae	.exit
	jmp	.l1
	
    .exit:
	pop	si
	ret
	

cli_compare:
	push	ax, si, bp
	cld
    .l1:
	lodsb
	scasb
	jne	.chksp
	or	al, al
	jnz	.l1
	jmp	.exit
	
    .chksp:
	cmp	al, 20h
	jne	.exit
	cmp	byte[di-1], 0
	
    .exit:	
	pop	bp, si, ax
	ret

cli_checkvmode:
	push	ax, bx
	mov	ah, 0fh
	int	10h
	cmp	al, 03	; text mode?
	je	.exit
	mov	ax, 0003h
	int	10h
    .exit:
	pop	bx, ax
	ret

 
cli_info_text:
	db "Commands:",13,10
	db "?,h,help        - this help screen",13,10
	db "cls             - clear screen",13,10
	db "cd <name>       - change current directory",13,10
	db "date            - display current date",13,10
	db "dir             - display files and directories",13,10
	db "time            - display current time",13,10
	db "ver             - TinyDOS version",13,10
	db "view <filename> - display file contents (first 2048 bytes)",13,10,0
cli_info: 
	ccall	console.writeln, ds, cli_version
	ccall	console.writeln, ds, cli_info_text
	jmp	cli_main
 
 
; OUT: cf set if error
cli_run_test	db "bzzz :)",0
cli_run:
	pusha
	
	mov	ax, ss
	mov	[sys_ss], ax
	mov	[sys_sp], sp
	
	mov	si, cli_input
	ccall	string.trim, si
	
	mov	di, fnspace
	call	fat12_preparefilename

	cmp	byte [fnspace], " "
	je	.exit

	cmp	dword [fnspace+8], ("COM"+0)
	jne	.cantrun 

	mov	di, fnspace
	call	fat12_findfile
	cmp	ax, -1
	je	.cantrun	; file not found

	mov	dx, [si+1ch]	; file size
	
	xor	ebx, ebx
	mov	bx, ds
	shl	ebx, 4
	add	bx, (App_Start+100h)
	shr	ebx, 4
	
	mov	cx, 0		; whole file
	call	fat12_loadfile
	
	;ccall  console.writeln, ds, cli_run_test
	
	mov	ax, 20cdh	; int 20h
	mov	[App_Start+10h], ax

	pusha
	mov	cx, 79h
	mov	si, cli_input
	mov	di, App_Start+81h
	rep	movsb
	popa
	
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, App_Start
	shr	eax, 4		; app start segment
	
	xor	si, si
	mov	di, si
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, si

	push	10h	; int 20
	
	push	ds
	push	0100h
	retf	 
	
	
    .exit:	
	popa
	clc
	ret
 
     .cantrun:
	popa
	stc
	ret
 
 
 ; DEBUG
 cli_test:
	;ccall  fdd.readsect, 19, 1, ds, sector_buffer
	pusha
	mov	cx, 1024
	mov	si, sector_buffer
    .l1:
	lodsb
	ccall	console.writech, ax
	loop	.l1
	
	popa
	
	jmp	cli_main		