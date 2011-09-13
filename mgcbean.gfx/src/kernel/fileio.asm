; There is 1 table in the system for opened files, with
; 512 kb reading buffer for each
; Each record requires 64b for description + 512 for buffer

; MAX_FILES defines how many files can be opened
FT_MAX_FILES	equ 256

FT_BUFFER_SIZE	equ 512

FT_Handler	equ  0	; file handler
FT_FileName	equ  4	; lptr file name (full file name)
FT_Access	equ  8	; file open mode and rights
FT_UID		equ 12	; user ID
FT_PID		equ 16	; programm ID
FT_DEVID	equ 20	; device id
FT_FNOPEN	equ 24	; function to open file
FT_FNRDBUF	equ 28	; function to read from device to buffer
FT_FNWRBUF	equ 32	; function to write from buffer to device
			; -- below depends on file system --
FT_Cl0		equ 36	; 1st cluster of file
FT_Cl1		equ 40	; current cluster
FT_Pos		equ 44	; current read/write position
FT_Size 	equ 48	; file size
FT_ModDate	equ 52	; original modification date and time (to prevent overwriting of files, modified with another program)
FT_FATEntry	equ 56	; FAT file entry
			; -- reserved --
FT_BUF_START	equ 64	; here starts r/w buffer
FT_RECORD_SIZE	equ(64 + FT_BUFFER_SIZE)       ; file table record size

; DATA


fileio_next_handler	dd  1	; new file handler
fileio_file_table	dd  0	; ptr to file table

; "public" functions

; system functions for reading/writing files
; always use these never special (fat12_xxxx, fat32_xxxx, etc)

; open file
; IN: esi - zstring (/path/to/file.txt)
fileio_open:

	call	fileio_getfreeentry
	or	edi, edi
	jz	.err_noentry

	mov	eax, [fileio_next_handler]
	mov	[edi], eax
	inc	eax
	mov	[fileio_next_handler], eax



	ret

 .err_noentry
	ret

; read data from file
fileio_read:

	ret

; read 1 line from a text file (to CR or CR/LF)
fileio_readln:

	ret

; read line to specified symbol
fileio_readto:

	ret

; write to file
fileio_write:

	ret

; close file - remove record (handler = 0)
; IN: eax - handler
fileio_close:
	push	edi
	call	fileio_gethandleraddr
	or	edi, edi
	jz	.notfound

	xor	eax, eax
	stosd

	pop	edi
	ret

 .notfound:
	; there must be error message call
	pop	edi
	ret

; "private" functions

; Initialize file table
; modifies eax
fileio_init:

	mov	eax, (FT_RECORD_SIZE * FT_MAX_FILES)
	call	sys_malloc
	or	eax, eax
	jz	$	; not enough system memory

	mov	[fileio_file_table], eax
	ret

; Get record address by handler
; IN:  eax - handler
; OUT: edi - addr, 0 if not found

fileio_gethandleraddr:
	push	ecx
	mov	edi, [fileio_file_table]
	mov	ecx, FT_MAX_FILES

    @@:
	cmp	[edi], eax
	je	.found
	add	edi, (FT_RECORD_SIZE)
	loop	@b

	xor	edi, edi
 .found:
	pop	ecx
	ret

; Get free address in file table
; IN:  -
; OUT: edi - address, 0 if not found

fileio_getfreeentry:

	push	ecx
	mov	edi, [fileio_file_table]
	mov	ecx, FT_MAX_FILES
    @@:
	cmp	[edi], 0
	je	.found
	add	edi, (FT_RECORD_SIZE)
	loop	@b

	xor	edi, edi
 .found:
	pop	ecx
	ret

; Get device code and functions to find file, read sector and write sector
; IN:  edi - file record in File Table

fileio_getdevicefn:
	mov	[edi+FT_DEVID], 0ff00h
	mov	eax, fat12_findfile
	mov	[edi+FT_FNOPEN], eax

	ret


