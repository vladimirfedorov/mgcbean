OSCODESEL	equ  8
OSDATASEL	equ 10h
OSSTACK 	equ 18h
SysTask 	equ 20h
Task1		equ 28h
Task2		equ 30h
TimerTask	equ 38h

; for ring 0 tasks
LDT_CODE	equ  8	+100b
LDT_STACK	equ 10h +100b
LDT_DATA	equ 18h +100b
LDT_SCR 	equ 20h +100b

; system/driver tasks
DRV_CODE	equ  8 +100b
DRV_DATA	equ 10h+100b
DRV_STACK	equ 18h+100b
SYS_BLOCK	equ 20h+100b

code_acc	equ 10011000b	; PL=0
data_acc	equ 10010010b
vmem_acc	equ 11110010b
stack_acc	equ 10010110b
tss_acc 	equ 10001001b
ldt_acc 	equ 10000010b

task_gate	equ 10000101b

; GUI options and defaults

GUI_MODE	equ 4103h	; 800x600x8
GUI_MODE_WIDTH	equ 1024	; logical width
GUI_MODE_SHIFT	equ 10		; shift to get line offset