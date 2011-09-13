; 16-bit string version
; !!! assumes ds is set to a string data segment

if ~ defined __STRINGS_ASM__
define __STRINGS_ASM__

; string module
; works with 1-byte character strings
; how to call functions:
; stdcall function_name, param1, param2, ...

include 'common.inc'
;include 'bytes.asm'
;include 'convert.asm'

; ------------------------------------------------------------------------------
; string.length(*str)
; returns string length (bytes) in eax
string.length:
	push	cx, di, bp
	mov	bp, sp
	add	bp, (2+2*3)

	mov	di, [bp]
	xor	ax, ax
	mov	cx, ax
	not	cx
	cld
	repnz	scasb
	not	cx	; neg ecx :)
	dec	cx	;
	mov	ax, cx

	pop	bp, di, cx
	ret

; ------------------------------------------------------------------------------
; string.format(*str, arg1, arg2, ...)
; str must have enough space for arguments
; string parameter format %i %u %x %X %s %c
; %i - signed decimal value
; %u - unsigned decimal
; %x,%X - hexadecimal (%x for 0abch, %X - 0ABCh) (maybe add mods like %b %w word (0-filled), %d, %q)
; %s - *str pushed
; %c - char pushed (1-byte)
; string.format:
; 	push	eax, ebx, edx, ecx, esi, edi, ebp
; 	lea	ebp, [esp+4+4*7]
; 	mov	esi, [ebp]
; 	add	ebp, 4		; ebp points at the first parameter
;     .l1:
;     	lodsb			; load byte
; 	cmp	al, '%'		; is special char?
; 	jne	@f
; 	; special char
; 	lodsb	
; 	call	__string_replacesc
;     @@:
; 	cmp	al, '\'
; 	jne	@f
; 	; extended char
; 	lodsb
; 	call	__string_replaceex
;     @@:
; 	or	al, al
; 	jz	.exit
;     	jmp	.l1
; 	
;     .exit:
; 	pop	ebp, edi, esi, ecx, edx, ebx, eax
; 	ret

; ------------------------------------------------------------------------------
; string.copy(*str_src, *str_dest, bytes)
; copy <bytes> bytes of a source string <str_src> to a destination string <str_dest>
; if bytes is 0, copies the whole string with 0 at the end
; str2 must have enough space for str1
string.copy:
	push	bp
	mov	bp, sp
	ccall 	bytes.move, ds, word[bp+2+2], ds, word[bp+2+4], word[bp+2+6]
	pop	bp
	ret

; ------------------------------------------------------------------------------
; string.toupper(*str)
; string to uppercase
string.toupper:
	push	ax, cx, di, si, bp
	mov	bp, sp
	add	bp, (2+2*5)
	mov	si, [bp]
	mov	di, si
	xor	cx, cx
	not	cx
	cld
  .l1:	lodsb
	or	al, al
	jz	.exit
	cmp	al, 'a'
	jb	.l2
	cmp	al, 'z'
	ja	.l2
	sub	al, ('a'-'A')
  .l2:	stosb
	loop	.l1
  .exit:
	pop	bp, si, di, cx, ax
	ret

; ------------------------------------------------------------------------------
; string.tolower(*str)
; string to lowercase
string.tolower:
	push	ax, cx, di, si, bp
	mov	bp, sp
	add	bp, (2+2*5)
	mov	si, [bp]
	mov	di, si
	xor	cx, cx
	not	cx
	cld
  .l1:	lodsb
	or	al, al
	jz	.exit
	cmp	al, 'A'
	jb	.l2
	cmp	al, 'Z'
	ja	.l2
	add	al, ('a'-'A')
  .l2:	stosb
	loop	.l1
  .exit:
	pop	bp, si, di, cx, ax
	ret

; ------------------------------------------------------------------------------
; string.trim(*str)
; trim leading and trailing spaces and non-printable characters (<32)
string.trim:
	push	ax, cx, si, di, bp
	mov	bp, sp
	add	bp, (2+2*5)
	
	mov	si, [bp]
	
	ccall	string.length, si
	mov	cx, ax
	or	cx, cx
	jz 	.exit

	add	si, cx
	dec	si

	; trim trailing sapces
    .step1:
	cmp	byte [si], 32
	ja	.trimleft
	mov	byte [si], 0
	dec	si
	loop	.step1
	
	; trim leading spaces
    .trimleft:
	xor	ax, ax    	
    	mov	si, [bp]
    	cmp	byte [si], 0
    	jz 	.exit
    	mov	di, si
    	
    .step2:	
    	cmp	byte [si], 32
    	ja	.ok
	inc	ax
	inc 	si
	loop	.step2
    .ok:
    	or	ax, ax
	jz	.exit
	inc	cx	; for last loop
	inc	cx	; for ending 0
	rep 	movsb
	
    .exit:
	pop	bp, di, si, cx, ax
	ret

; ------------------------------------------------------------------------------
; string.replace(*src, *find, *new)
; replaces all occurences of string <*find> in string <*src> with string <*new>
; string <*src> must have enough space for all replacements
; string.replace:
; 	push	eax,ebx,ecx,edx,esi,edi
; 	
; 	mov	esi, [esp+4+4*6]	; old string
; 	mov	edx, [esp+4+4*6+4]	; replace what
; 	mov	edi, [esp+4+4*6+8]	; replace with
; 	
; 	ccall	string.length, edx
; 	mov	ebx, eax		; ebx = find.length
; 	
; 	ccall	string.length, edi
; 	mov	ecx, eax		; ecx = new.length
; 	
;     .l1:
; 	ccall	string.pos, esi, edx
; 	cmp	eax, -1
; 	je	.exit	; all replacements are made
; 	ccall	string.delete, esi, eax, ebx
; 	ccall	string.insert, esi, edi, eax
; 	add	esi, eax
; 	add	esi, ecx
; 	jmp	.l1
; 	
; 	
;     .exit:	
; 	pop	edi,esi,edx,ecx,ebx,eax
; 	ret

; ------------------------------------------------------------------------------
; string.delete(*str, start, count)
; delete <count> characters from <*str> starting from <start>
; string.delete:
; 	push	esi, edi, eax, ecx, edx
; 	mov	esi, [esp+4+4*5]
; 	mov	edx, [esp+4+4*5+4]
; 	mov	ecx, [esp+4+4*5+8]
; 	ccall 	string.length, esi
; 	sub	eax, edx
; 	sub	eax, ecx
; 	;jl	.exit		; out of string boundaries
; 	
; 	mov	edi, esi
; 	add	edi, edx	; start position
; 	mov	esi, edi
; 	add	edi, ecx	; end position
; 	inc	eax		; include 0
; 	
; 	ccall	bytes.move, edi, esi, eax
;     .exit:
; 	pop	edx, ecx, eax, edi, esi
; 	ret
	
; ------------------------------------------------------------------------------
; string.insert(*str, *str1, position)
; insert <*str1> into <*str> at <position> 
; str must bhave enough space for str1  
; string.insert:
; 	push	esi, edi, eax, ecx, edx
; 	mov	esi, [esp+4+4*5]
; 	mov	edi, [esp+4+4*5+4]
; 	mov	edx, [esp+4+4*5+8]
; 	
; ; in fact, string may be shorter then position index, when a string is 0-filled buffer 
; ; 	ccall	string.length, esi
; ; 	cmp	edx, eax
; ; 	ja	.exit
; 	
; 	ccall	string.length, esi
; 	sub	eax, edx 
; 	mov	ecx, eax
; 	inc	ecx		; # of bytes to move
; 	add	esi, edx
; 	
; 	ccall	string.length, edi
; 	mov	edx, eax
; 	add	eax, esi
; 	
; 	ccall	bytes.move, esi, eax, ecx
; 	ccall	bytes.move, edi, esi, edx  
; 	
;     .exit:
; 	pop	edx, ecx, eax, edi, esi
; 	ret

; ------------------------------------------------------------------------------
; string.insert(*str, char, position, count)
; insert <*str1> into <*str> at <position> 
; str must bhave enough space for str1  
; string.insertch:
; 	push	eax, esi, edi, ecx
; 	mov	esi, [esp+4+4*4]
; 	add	esi, [esp+4+4*4+8]
; 	mov	edx, [esp+4+4*4+12]
; 		
; 	ccall	string.length, esi	
; 	mov	ecx, eax		; ecx = length of the rest of the string
; 	inc	ecx			; + 0
; 
; 	mov	edi, esi
; 	add	edi, edx
; 	ccall	bytes.move, esi, edi, ecx	; insert space for spaces
; 	mov	ecx, edx
; 	mov	al, byte [esp+4+4*4+4]
; 	mov	edi, esi
; 	cld
; 	rep	stosb				; fill with spaces
; 	
; 	pop	ecx, edi, esi, eax
; 	ret
	
; ------------------------------------------------------------------------------
; string.pos(*str, *find)
; find position of the first occurence of a string <*find> in <*src> 
; returns substring position in eax
; string.pos:
; 	push	ecx, esi, edi, edx, ebx
; 	mov	esi, [esp+4+4*5]
; 	mov	edi, [esp+4+4*5+4]
; 	ccall 	string.length, esi
; 	mov	ecx, eax
; 	ccall	string.length, edi
; 	sub 	ecx, eax	; # steps to do
; 	inc	ecx
; 	cmp	ecx, 0
; 	jl	.notfound	; exit if find.length > str.length
; 
; 	mov	ebx, ecx	; ebx will help us to get position
; 	mov	edx, eax	; edx = substring length
;     
;     .l1:
; 	ccall 	bytes.compare, esi, edi, edx
; 	je	.found
; 	inc	esi
; 	loop	.l1
; 
;     .notfound:
;     	xor	eax, eax	 
;     	dec	eax		; zf = 0, eax = -1 - string not found
;     	jmp	.exit
; 
;     .found:    
;     	mov	eax, ebx
;     	sub	eax, ecx
;     	
;     .exit:	
; 	pop	ebx, edx, edi, esi, ecx
; 	ret

; ------------------------------------------------------------------------------
; string.lastpos(*str, *find)
; find position of the last occurence of a string <*find> in <*src> 
; returns substring position in eax
; string.lastpos:
; 	push	ecx, esi, edi, edx, ebx
; 	mov	esi, [esp+4+4*5]
; 	mov	edi, [esp+4+4*5+4]
; 	ccall 	string.length, esi
; 	mov	ecx, eax
; 	ccall	string.length, edi
; 	sub 	ecx, eax	; # steps to do
; 	inc	ecx
; 	cmp	ecx, 0
; 	jl	.notfound	; exit if find.length > str.length
; 
; 	mov	ebx, ecx	; ebx will help us to get position
; 	mov	edx, eax	; edx = substring length
; 	add	esi, ecx
;     
;     .l1:
; 	ccall 	bytes.compare, esi, edi, edx
; 	je	.found
; 	dec	esi
; 	loop	.l1
; 
;     .notfound:
;     	xor	eax, eax	 
;     	dec	eax		; zf = 0, eax = -1 - string not found
;     	jmp	.exit
; 
;     .found:    
;     	mov	eax, ecx
;     	
;     .exit:	
; 	pop	ebx, edx, edi, esi, ecx
; 	ret

; ------------------------------------------------------------------------------
; string.compare(*str1, *str2)
; compare 2 strings
; return flags for j-condition
string.compare:
	push	ax, si, di, bp
	mov	bp, sp
	add	bp, (2+2*4)
	
	mov	si, [bp]
	mov	di, [bp+2]
	cld
    .l1:
    	lodsb
    	scasb
    	jne	.exit
    	or	al, al
    	jnz	.l1
    .exit:	
	pop	bp, di, si, ax
	ret

; ------------------------------------------------------------------------------
; string.split(*str, *strArray, delimeter, maxlines, length)
; split a string to a string array
; maxlines - number of elements in the string array
; length - length of an element in the string array
; string.split:
; 	push	eax,ebx,ecx,edx,edi,esi
; 	
; 	mov	esi, [esp+4+4*6]
; 	mov	edi, [esp+4+4*6+4]
; 	mov	eax, [esp+4+4*6+8]	; al = delimiter
; 
;     		
; 	
; 	pop	esi,edi,edx,ecx,ebx,eax
; 	ret

; ------------------------------------------------------------------------------
; private functions
; don't call these functions

; ------------------------------------------------------------------------------
; __string_insertsp
; insert spaces
; in: esi - position to insert
;     edx - num of spaces to insert
; __string_insertsp:
; 	
; 	push	eax, esi, edi, ecx
; 	ccall	string.length, esi	
; 	mov	ecx, eax		; ecx = length of the rest of the string
; 	inc	ecx			; + 0
; 
; 	mov	edi, esi
; 	add	edi, edx
; 	ccall	bytes.move, esi, edi, ecx	; insert space for spaces
; 	mov	ecx, edx
; 	mov	al, ' '
; 	mov	edi, esi
; 	cld
; 	rep	stosb				; fill with spaces
; 	
; 	pop	ecx, edi, esi, eax
; 	ret
	

; ------------------------------------------------------------------------------
; __string_replacesc
; replace special chars, like %i etc.  
; in: al = special char (after '%')
;     esi = pointer to the next char
;     ebp = parameter pointer
; __string_replacesc:
; 	push	eax
; 	ccall	string.length, esi	
; 	mov	ecx, eax		; ecx = length of the rest of the string
; 	inc	ecx			; + 0
; 	pop	eax
; 
; 	cmp	al, '%'
; 	jne	@f
; 	; cut one '%'
; 	lea	edi, [esi-1]
; 	ccall	bytes.move, esi, edi, ecx
; 	inc	esi		; otherwise it hangs )
; 	jmp	.exit  
;     @@:	
; 	cmp	al, 'i'		; replace with signed integer
; 	jne	@f
; 
; 	lea	edi, [esi-2]
; 	ccall	bytes.move, esi, edi, ecx
; 	ccall	string.insertch, edi, ' ', 0, 12
; 	ccall	__string_inttostr, edi, [ebp], -10, __string_numh
; 	sub	eax, 10
; 	neg	eax
; 	push	esi
; 	add	esi, eax
; 	ccall	string.length, esi
; 	inc	eax
; 	ccall	bytes.move, esi, edi, eax
; 	pop	esi
; 	add	ebp, 4		; move to the next parameter
; 	jmp	.exit
;     @@:  	
; 	cmp	al, 'u'		; replace with unsigned integer
; 	jne	@f
; 
; 	lea	edi, [esi-2]
; 	ccall	bytes.move, esi, edi, ecx
; 	ccall	string.insertch, edi, ' ', 0, 12
; 	ccall	__string_inttostr, edi, [ebp], 10, __string_numh
; 	sub	eax, 10
; 	neg	eax
; 	push	esi
; 	add	esi, eax
; 	ccall	string.length, esi
; 	inc	eax
; 	ccall	bytes.move, esi, edi, eax
; 	pop	esi
; 	add	ebp, 4		; move to the next parameter
; 	jmp	.exit
;     @@:  	
; 	cmp	al, 'x'		; replace with hex 'abch'
; 	jne	@f
; 
; 	lea	edi, [esi-2]
; 	ccall	bytes.move, esi, edi, ecx
; 	ccall	string.insertch, edi, ' ', 0, 12
; 	ccall	__string_inttostr, edi, [ebp], 16, __string_numl
; 	sub	eax, 10
; 	neg	eax
; 	push	esi
; 	add	esi, eax
; 	ccall	string.length, esi
; 	inc	eax
; 	ccall	bytes.move, esi, edi, eax
; 	pop	esi
; 	add	ebp, 4		; move to the next parameter
; 	jmp	.exit
;     @@:  	
; 	cmp	al, 'X'		; replace with hex 'ABCh'
; 	jne	@f
; 
; 	lea	edi, [esi-2]
; 	ccall	bytes.move, esi, edi, ecx
; 	ccall	string.insertch, edi, ' ', 0, 12
; 	ccall	__string_inttostr, edi, [ebp], 16, __string_numh
; 	sub	eax, 10
; 	neg	eax
; 	push	esi
; 	add	esi, eax
; 	ccall	string.length, esi
; 	inc	eax
; 	ccall	bytes.move, esi, edi, eax
; 	pop	esi
; 	add	ebp, 4		; move to the next parameter
; 	jmp	.exit
;     @@:  	
; 	cmp	al, 'c'		; replace with pushed char
; 	jne	@f
; 	lea	edi, [esi-1]
; 	ccall	bytes.move, esi, edi, ecx
; 	mov	ah, [ebp]
; 	mov	[edi-1], ah
; 	add	ebp, 4		; move to the next parameter
; 	inc	esi
; 	jmp	.exit
;     @@:  	
; 	cmp	al, 's'		; replace with string
; 	jne	@f
; 	lea	edi, [esi-2]
; 	ccall	bytes.move, esi, edi, ecx
; 	ccall	string.insert, esi, [ebp], -2
; 	push	eax
; 	ccall	string.length, [ebp]
; 	add	esi, eax
; 	pop	eax
; 	add	ebp, 4
; 	jmp	.exit
;     @@:  	
;   	
;   	
;     .exit:
;     	sub	esi, 2 	
; 	ret

; ------------------------------------------------------------------------------
; __string_replaceex
; replace special chars, like \n etc.  
; in: al = special char (after '\')
;     esi = pointer to the next char
; __string_replaceex:	
; 	push	eax
; 	ccall	string.length, esi	
; 	mov	ecx, eax		; ecx = length of the rest of the string
; 	inc	ecx			; + 0
; 	pop	eax
; 	lea	edi, [esi-1]		; edi = previous char
; 
; 	cmp	al, '\'			; backslash
; 	jne	@f
; 	jmp	.default
;     @@:	
; 	cmp	al, '"'			; "
; 	jne	@f
; 	mov	byte [edi-1], '"'
; 	jmp	.default
;     @@:	
; 	cmp	al, "'"			; '
; 	jne	@f
; 	mov	byte [edi-1], "'"
; 	jmp	.default
;     @@:	
; 	cmp	al, 'n'			; 13 CR
; 	jne	@f
; 	mov	byte [edi-1], 13
; 	jmp	.default
;     @@:	
; 	cmp	al, 'r'			; 10 LF
; 	jne	@f
; 	mov	byte [edi-1], 10
; 	jmp	.default
;     @@:	
; 	cmp	al, 'b'			; backspace
; 	jne	@f
; 	sub	edi, 2
; 	ccall	bytes.move, esi, edi, ecx
; 	sub	esi, 3
; 	jmp	.exit		
;     @@:	
; 	jmp	.exit
; 	
;     .default:
; 	ccall	bytes.move, esi, edi, ecx 
; 	dec	esi	    	
;     .exit:
; 	ret
; 	

; ------------------------------------------------------------------------------
; convert.inttostr(buffer, num, radix)
; buffer 12-byte buffer (32-bit systems, ANSI strings) for 
; num - number to convert
; radix (-10 for signed decimal)
; OUT: eax - number of characters 
; __string_inttostr:
; 	push	ebx,ecx,edx,esi,edi
; 	mov	edi, [esp+4+4*5]
; 	mov	eax, [esp+4+4*5+4]
; 	mov	ebx, [esp+4+4*5+8]
; 	
; 	xor	ecx, ecx	; clear
; 	mov	cl, 20h		; space for sign
; 	cmp	ebx, -10	; -10 for signed decimal
; 	jne	.l0
; 	neg	ebx
; 	bt	eax, 31
; 	jnc	.l0
; 	neg	eax
; 	mov	cl, '-'		; negative number
;    .l0:
; 	add	edi, 11		; move to the end of the buffer
; 	   				
;    .l1: 			; convert to string
; 	inc	ch		; digit counter
; 	xor	edx, edx	; reminder
; 	div	ebx		; radix
; 	add	edx, [esp+4+4*5+12] ;__string_numh	
; 	mov	dl, [ds:edx]
; 	mov	[edi], dl
; 	dec	edi
; 	or	eax, eax
; 	jnz	.l1
; 	
; 	cmp	cl, '-'
; 	jne	.nominus
; 	inc	ch
;     .nominus:
; 	
; 	mov	[edi], cl	; add sign if needed
; 	xor	eax, eax
; 	mov	al, ch		; number of characters output 
; 	
; 	
; 	pop	edi,esi,edx,ecx,ebx
; 	ret
; __string_numh	db "0123456789ABCDEF"
; __string_numl	db "0123456789abcdef"
	
end if	; __STRINGS_ASM__