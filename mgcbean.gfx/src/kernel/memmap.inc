; memory mapping

STACK_BASE	equ 070000h
STACK_LIM	equ 0FFFFh	; 64k kernel stack

IDT_SEG 	equ 9000h	;
IDT_BASE	equ 90000h	;
IDT_SIZE	equ 7FFh	; 2k


VESA_INFO	equ 90800h	;90800h..909FFh - vesa info, 90A00h..90AFFh - mode info
VESA_MODE	equ 90A00h

PDT_BASE	equ 91000h	; PDT base address
SYS_PDTS	equ 2

;SYSFONT_BUF     equ 94000h
;SYSFONT         equ 94010h

SYS_VARS	equ 98000h	; system variables (kernel.inc)

GDT_SEG 	equ 8000h	; 16bit segment to move data
GDT_BASE	equ 80000h	;
GDT_SIZE	equ 0FFFFh	; 64k

UMM_BASE	equ 100000h
UMM_SIZE	equ 1ffffh	; 128k = 4G
UMM_USED_SIZE	equ 8*1024/4	; 8M is used

KHEAP_PTRS_BASE equ 120000h	; pointers to system memory blocks
KHEAP_PTRS_END	equ 130000h	; pointers end
KHEAP_PTR_SIZE	equ 8		; size of one element (pointer and size)
KHEAP_PTR_SHR	equ 3		; log2(KHEAR_PTR_SIZE)

WND_STRUC	equ 130000h	; window structures
WND_STRUC_END	equ 13ffffh	;


SYS_MALLOC_BASE equ 140000h	; small amount of memory for start up allocation
SYS_MALLOC_MAX	equ 180000h	;

TASK_LIST	equ 180000h	; task list
TASK_LIST_SIZE	equ 7ffffh	; 512k - 512 tasks


; task stack and environment
TASK_STACK_SIZE equ 60*1024	; stack | env | code
TASK_ENV_SIZE	equ  4*1024	; environment (starting cwd,filename,args)



RAMDRV_BASE	equ 200000h

FREE_MEM	equ 380000h

PTE_BASE	equ 400000h	; PTE base address

VIDEO_FB	equ 0C0000000h
KHEAP_BASE	equ 0E0000000h
KHEAP_END	equ 0F7FFFFFFh


