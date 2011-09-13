; 32-bit queue functions
; Fedorov Vladimir (c) 2008
; All functions use queue structure:
;       dd  queue_base
;       dd  queue_size (bytes)
;       dd  queue_size_mask (queue_size-1)
;       dd  queue_element_size (bytes)
;       dd  queue_head
;       dd  queue_tail
; Don't forget to get it properly declared.
; All sizes MUST be a power of 2. For 32-bit architecture
; for putx/getx valid element sizes are 1, 2 and 4

QUEUE_BASE	equ	0
QUEUE_SIZE	equ	4
QUEUE_SIZEMASK	equ	8
QUEUE_ESIZE	equ	12
QUEUE_HEAD	equ	16
QUEUE_TAIL	equ	20


; allocates memory and creates new queue
; returns eax - queue description structure address
queue.create:

	ret


; deletes queue and frees memory
queue.delete:

	ret


; put element into a queue
; stdcall queue.put, queue_struc, element
queue.put:

	ret


; same but value is passed via stack
; stdcall queue.putx, queue_struc, value
queue.putx:

	push	edi, edx

	mov	edi, [esp+4*2+4]	; ptr to queue structure
	mov	eax, [esp+4*2+4+4]	; value

	mov	edx, [edi+QUEUE_TAIL]
	sub	edx, [edi+QUEUE_BASE]
	add	edx, [edi+QUEUE_ESIZE]
	and	edx, [edi+QUEUE_SIZEMASK]
	add	edx, [edi+QUEUE_BASE]

	cmp	edx, [edi+QUEUE_HEAD]
	je	.exit			; no free space
	mov	[edi+QUEUE_TAIL], edx

	cmp	[edi+QUEUE_ESIZE], 4
	jne	@f
	mov	[edx], eax
	jmp	.exit
   @@:
	cmp	[edi+QUEUE_ESIZE], 2
	jne	@f
	mov	[edx], ax
	jmp	.exit

   @@:
	cmp	[edi+QUEUE_ESIZE], 1
	jne	.exit
	mov	[edx], al

  .exit:
	pop	edx, edi

	ret



; get element
; stdcall queue.get, queue_struc, element
queue.get:

	ret


; the same but value returns in eax
; stdcall queue.getx, queue_struc
queue.getx:

	ret

; get number of elements in a queue
queue.length:

	ret`

; clear queue
; stdcall queue.clear
queue.clear:
	push	eax, edi
	mov	edi, [esp+4*2+4]
	mov	eax, [edi+QUEUE_HEAD]
	mov	[edi+QUEUE_TAIL], eax
	pop	edi, eax
	ret

