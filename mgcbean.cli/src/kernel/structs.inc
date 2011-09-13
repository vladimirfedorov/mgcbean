; TSS  structure
TSS_ESP0	equ 4
TSS_SS0 	equ 8
TSS_ESP1	equ 0ch
TSS_SS1 	equ 10h
TSS_ESP2	equ 14h
TSS_SS2 	equ 18h
TSS_CR3 	equ 1ch
TSS_EIP 	equ 20h
TSS_EFLAGS	equ 24h
TSS_ESP 	equ 38h
TSS_ES		equ 48h
TSS_CS		equ 4ch
TSS_SS		equ 50h
TSS_DS		equ 54h
TSS_FS		equ 58h
TSS_GS		equ 5ch
TSS_LDTR	equ 60h
TSS_TRACE	equ 64h

; task record (1024 bytes):
TASK_PID	equ 00h 	; +00h  w   PID
TASK_UID	equ 02h 	; +02h  w   UID
TASK_EMASK	equ 04h 	; +04h  d   event mask
TASK_PROPS	equ 10h 	; +10h  d   properties
TASK_HWND	equ 14h 	; +14h  d   task main window handler
				; +18h  d   reserved
				; +1Ch  d   reserved
TASK_NAME	equ 20h 	; +20h  64  name
TASK_TSS	equ 100h	; +100h 104 TSS
TASK_TSS_DESC	equ 170h	; +170h w   TSS descriptor
TASK_LDT_DESC	equ 172h	; +172h w   LDT descriptor
TASK_LDT	equ 180h	; +180h 128 LDT (1+15 descriptors)
TASK_MMXBUF	equ 200h	; +200h 512 fpu regs buffer
TASK_RECSIZE	equ 1024	; task record

; Window element structure
WND_HANDLER	equ 00h 	; +00h  w  hWnd
WND_PARENT	equ 02h 	; +02h  w  parent hWnd
WND_TOP 	equ 04h 	; +04h  w  window top corner -32768..+32767
WND_LEFT	equ 06h 	; +06h  w  left corner       -32768..+32767
WND_HEIGHT	equ 08h 	; +08h  w  window height
WND_WIDTH	equ 0Ah 	; +0Ah  w  window width
WND_Z		equ 0Ch 	; +0Ch  w  z
WND_PROPS	equ 0Eh 	; +0Eh  w  properties
WND_BOTTOM	equ 10h 	; +10h  w  top+height
WND_RIGHT	equ 12h 	; +12h  w  left+width
WND_RECSIZE	equ 14h 	; window record size

