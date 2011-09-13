; virtual system variables

; macro align value { rb (value-1)-($+value-1) mod value }

macro push [arg]
{
  push	arg
}

macro pop [arg]
{
  pop	arg
}

macro stdcall proc,[arg]
{
  reverse push arg
  common call proc
}

macro invoke proc,[arg]
{
  common stdcall [proc],arg
}

; public variables

virtual at SYS_VARS

; mouse
mouse_B 	db ?	; mouse buttons
mouse_xB	db ?	; extended state
mouse_X 	dw ?
mouse_Y 	dw ?
mouse_Z 	dw ?

; cursor variables
csr_oldx	dw ?
csr_oldy	dw ?
csr_old 	dd ?

; screen
screen_buff	dd ?	; video mem address - will be constant
screen_bpp	db ?	; bits per pixel
screen_shift	db ?	; shift to get offset for each line
screen_mode	dw ?	; VESA video mode
screen_width	dw ?
screen_height	dw ?
screen_lwidth	dd ?	; logical width
screen_lheight	dd ?	; logical height

; window stuctures
wnd_struc	dd ?	; start of window structure
wnd_struc_end	dd ?	; last address
wnd_last	dd ?	; last non-empty element

end virtual

; private variables