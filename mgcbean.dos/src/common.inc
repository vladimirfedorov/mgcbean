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

macro stdcall proc,[arg]		; directly call STDCALL procedure
 { common
    if ~ arg eq
   reverse
    push arg
   common
    end if
    call proc }

macro invoke proc,[arg] 		; indirectly call STDCALL procedure
 { common
    if ~ arg eq
   reverse
     push arg
   common
    end if
    call [proc] }

macro ccall proc,[arg]			; directly call CDECL procedure
 { common
    size@ccall = 0
    if ~ arg eq
   reverse
    push arg
    size@ccall = size@ccall+2
   common
    end if
    call proc
    if size@ccall
    ;add esp,size@ccall
    mov	bp, sp
    lea sp, [bp+size@ccall]
    end if }

macro cinvoke proc,[arg]		; indirectly call CDECL procedure
 { common
    size@ccall = 0
    if ~ arg eq
   reverse
    push arg
    size@ccall = size@ccall+2
   common
    end if
    call [proc]
    if size@ccall
    ;add esp,size@ccall
    mov	bp, sp
    lea sp, [bp+size@ccall]
    end if }
