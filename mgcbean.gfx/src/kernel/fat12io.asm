fat12ptr	dd 0
dirptr		dd 0
buf512ptr	dd 0
nextfileid	dd 0

; file structure
FILE_id 	equ 0	; +00h file id
FILE_mode	equ 4	; +04h mode (r/w etc)
FILE_cl0	equ 8	; +08h 1st cluster
FILE_cl1	equ 12	; +0Ch current cluster
FILE_pos	equ 16	; +10h position to read/write
FILE_size	equ 20	; +14h file size


; there is one table for opened files
; file table structure
; always use these constant names, never values

FT_Handler	equ  0	; file handler
FT_FileName	equ  4	; lptr file name (full file name)
FT_Access	equ  8	; file open mode and rights
FT_UID		equ 12	; user ID
FT_PID		equ 16	; programm ID
FT_Cl0		equ 20	; 1st cluster of file
FT_Cl1		equ 24	; current cluster
FT_Pos		equ 28	; current read|write position
FT_Size 	equ 32	; file size
FT_ModDate	equ 36	; original modification date and time (to prevent overwriting of files, modified with another program)
FT_FATEntry	equ 44	; FAT file entry
			; -------- reserved --------
FT_RecordSize	equ 64	  ; file table record size
FT_MaxFiles	equ 1024  ; max files opened in the OS

; ------------------------------------------------------------------------------
fat12io:
 .init:

	mov	eax, 9*512	; fat12 size
	call	sys_malloc
	or	eax, eax
	jz	.error
	mov	[fat12ptr], eax

	mov	eax, 4096*2	; directory
	call	sys_malloc
	or	eax, eax
	jz	.error
	mov	[dirptr], eax

	mov	eax, 512
	call	sys_malloc
	or	eax, eax
	jz	.error
	mov	[buf512ptr], eax

	mov	eax, 0ff000003h
	mov	edi, [fat12ptr]
	mov	edx, 1
	mov	ecx, 9		; 9 sect/fat12
    @@: int	38h
	inc	edx
	loop	@b

	mov	edx, 19
	mov	ecx, 0Eh	; E0h root entries * 20h /200h
	mov	edi, [dirptr]
    @@: int	38h
	inc	edx
	loop	@b

	ret

 .error:
	jmp	$


; ------------------------------------------------------------------------------
; esi - folder name
fat12_chdir:
	pusha
	call	fat12_finddir

	cmp	eax, -1
	je	.notfound

	mov	edx, eax
	mov	ecx, 4096*2/512
	mov	eax, 0ff000003h
	mov	edi, [dirptr]
	add	edx, 31

    @@:
	int	38h
	push	eax
	mov	eax, edx
	sub	eax, 31
	call	fat12_getnextcluster
	cmp	ax, 0ff8h
	pop	eax
	jae	.exit
	loop	@b

  .exit:
	popa
	clc
	ret

  .notfound:
	popa
	stc
	ret

; ------------------------------------------------------------------------------
; esi - file name
; edx - FILE structure

fat12_openfile:
	push	eax
	push	ebx
	push	ecx


	call	fat12_findfile
	cmp	eax, -1
	je	.notfound

	mov	ecx, [edi+1Ch]
	mov	edi, edx
	mov	ebx, [nextfileid]
	inc	ebx
	mov	[nextfileid], ebx
	mov	[edi], ebx
	mov	[edi+FILE_cl0], eax
	mov	[edi+FILE_cl1],  eax
	mov	[edi+FILE_size], ecx
	xor	eax, eax
	mov	[edi+FILE_pos], eax
	clc
	jmp	.exit
  .notfound:
	stc
  .exit:
	pop	ecx
	pop	ebx
	pop	eax
	ret


; ------------------------------------------------------------------------------
; esi - FILE structure !!!! change this to file descriptor
; edi - buffer
; ecx - bytes to read
fat12_readfile:
	pusha
	push	edi
	mov	eax, 0ff000003h
	mov	edi, [buf512ptr]
	mov	edx, [esi+FILE_cl1]
	add	edx, 31
	int	38h

	mov	edx, [esi+FILE_pos]
	mov	ebp, esi		; ebp = &FILE
	push	edx
	mov	esi, [buf512ptr]
	and	edx, 1ffh
	add	esi, edx
	pop	edx
	pop	edi	; edi = buffer again

   .rd: movsb

	inc	edx			; unoptimized :(
	cmp	edx, [ds:ebp+FILE_size]
	jae	.exit
	test	edx, 1ffh
	jz	.lnb

	loop	.rd

  .exit:
	mov	esi, ebp
	mov	[esi+FILE_pos], edx
	popa
	ret

  .lnb:
	push	edi			; edi=&buffer
	push	edx

	mov	eax, [ds:ebp+FILE_cl1]
	call	fat12_getnextcluster
	cmp	ax, 0ff8h
	jb	@f

	pop	edx
	pop	edi			; eof
	jmp	.exit

    @@: mov	[ds:ebp+FILE_cl1], eax
	mov	edx, eax
	mov	edi, [buf512ptr]
	mov	eax, 0ff000003h
	add	edx, 31 		; sector -> cluster
	int	38h

	pop	edx
	pop	edi

	mov	esi, [buf512ptr]
	dec	ecx			; this cycle
	jmp	.rd


; ------------------------------------------------------------------------------
; read all file content into memory
; IN: esi - File name
;     edi - buffer to write to
fat12_readAllFile:
	push	eax, edx
	push	edi
	call	fat12_findfile	; out: eax - 1st cluster, edi - file entry
	cmp	eax, -1
	je	.exit
	pop	edi
  .readsect:
	mov	edx, eax
	add	edx, 31
	call	dev_ramdrive_readsect	; edi incremented
	call	fat12_getnextcluster
	cmp	eax, 0ff0h
	jb	.readsect
  .exit:
	pop	edx, eax
	ret

; ------------------------------------------------------------------------------
; find dir
; IN:  esi - dir name
; OUT: eax = 1st cluster or eax=-1 if file not found
;      edi - file entry

fat12_finddir:
	push	ecx
	mov	edi, [dirptr]
	mov	ecx, 4096*2/32	  ; page contains 2*4096/32 files
 .scan: push	edi
	push	esi
	push	ecx
	mov	ecx, 11
	repe	cmpsb
	pop	ecx
	pop	esi
	pop	edi

	je	.found

   .l1: add	edi, 20h
	cmp	byte[edi], 0
	je	.notfound
	loop	.scan
       ;here: load next page if not end of dir
 .notfound:
	mov	eax, -1
	jmp	.exit

 .found:
	test	byte[edi+0Bh], 10h	; it may be a subdir. w the same name
	jz	.l1
	movzx	eax, word[edi+1Ah]

 .exit:
	pop	ecx
	ret

; ------------------------------------------------------------------------------
; find file
; IN:  esi - file name
; OUT: eax = 1st cluster or eax=-1 if file not found
;      edi - file entry
fat12_findfile:
	push	ecx
	mov	edi, [dirptr]
	mov	ecx, 4096*2/32	  ; page contains 2*4096/32 files

 .scan: push	edi
	push	esi
	push	ecx
	mov	ecx, 11
	repe	cmpsb
	pop	ecx
	pop	esi
	pop	edi

	je	.found

   .l1: add	edi, 20h
	cmp	byte[edi], 0
	je	.notfound
	loop	.scan
       ;here: load next page if not end of dir
 .notfound:
	xor	eax, eax
	not	eax
	jmp	.exit

 .found:
	test	byte[edi+0Bh], 10h	; it may be a subdir. with the same name
	jnz	 .l1
	movzx	eax, word[edi+1Ah]

 .exit:
	pop	ecx
	ret



; ------------------------------------------------------------------------------
; returns next file cluster or 0fffh in ax if EOF
; IN: eax - 1st cluster of a file
; OUT: eax - next file cluster, or  0fffh if EOF

fat12_getnextcluster:
	push	ebx
	push	edx
	push	esi

	;xor     edx, edx
	;mov     ebx, 3
	;mul     ebx
	;shr     eax, 1

	xor	dx, dx
	mov	bx, 2
	div	bx
	mov	bx, 3
	mul	bl

	mov	esi, eax
	add	esi, [fat12ptr]
	lodsw
	ror	eax, 16
	lodsb
	rol	eax, 16
	or	edx, edx
	jz	.exit

	shr	eax, 12
 .exit: and	eax, 00000fffh

	pop	esi
	pop	edx
	pop	ebx
	ret


