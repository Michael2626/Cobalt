
;--- MOVEXBDA moves XBDA to low memory. If the XBDA is already moved
;--- or if it is too large, nothing is done.
;--- MOVEXBDA hooks interrupt 19h and will restore the XBDA to its
;--- previous location if this interrupt is called.
;--- MOVEXBDA is Public Domain.

	.286

MAXXBDA equ 3	;max size of XBDA in KB
XBDAADR equ 000Eh	;address of XBDA segment in BIOS data region
MEMSIZE equ 0013h	;size of memory in kB in BIOS data region

MCB struct
sig   db ?
psp   dw ?
_size dw ?
MCB ends

XBDA struct
_size db ? ;size of XBDA in KB
XBDA ends

IODAT   struct
cmdlen	db ?
unit	db ?
cmd 	db ?
status	dw ?
		db 8 dup (?)
media	db ?
trans	dd ?
count	dw ?	;+ 12 init:offset parameter line
start	dw ?	;+ 14 init:segment parameter line
drive	db ?
IODAT   ends

_TEXT segment para 'CODE'

	dw -1
	dw -1
	dw 8000h				  ;attribute
	dw offset devstrat		  ;device strategy
intproc dw offset devintfirst	  ;device interrupt
devname db 'MOVXBDA#'

cmdptr  dd 1 dup (?)
oldint19 dd ?

devstrat proc far
	mov cs:word ptr[cmdptr],bx
	mov cs:word ptr[cmdptr+2],es
	ret
devstrat endp

devint proc far
	push bx
	push ds
	lds bx,cs:[cmdptr]
	mov word ptr [bx.IODAT.status],8103h
	pop ds
	pop bx
	ret
devint endp

;--- restore XBDA to above low mem

myint19 proc
	push ds
	mov si, offset buffer
	push 40h
	pop ds
	mov di,ds:[MEMSIZE]
	shl di,6    ;convert KB to PARA
	mov cl,cs:[si].XBDA._size
	mov ch,0
	sub ds:[MEMSIZE],cx
	push cx
	shl cx,6    ;convert KB to PARAs
	sub di,cx
	mov ds:[XBDAADR],di
	mov es,di
	pop cx
	push cs
	pop ds
	xor di,di
	shl cx,9	;convert KB to WORDs
	rep movsw
	mov ds,cx   ;ds=0000
	.386
	mov eax, cs:[oldint19]
	mov ds:[19h*4],eax
	pop ds
	push eax
	.286
	retf
myint19 endp

	align 16

buffer db MAXXBDA * 1024 dup (0)	;location for new XBDA

devintfirst proc far
	pusha
	push ds
	push es
	lds bx,cs:[cmdptr]
	mov al,[bx.IODAT.cmd]
	mov word ptr [bx.IODAT.status],100h
	cmp al,00			;init call?
	jnz exit

	mov word ptr [bx.IODAT.trans+0],0000
	mov word ptr [bx.IODAT.trans+2],cs
	mov cs:[intproc], offset devint
	push 40h
	pop es
	mov ax,es:[XBDAADR]	;check if XBDA is just above low memory
	mov dx,es:[MEMSIZE]
	shl dx,6    ;convert KB to PARA
	cmp ax,dx
	jnz exit	;if no, do nothing
	mov es,ax
	mov al,es:[XBDA._size]
	cmp al,MAXXBDA
	ja exit		;exit if XBDA is too large
	mov ds,dx
	push cs
	pop es

;--- move contents of XBDA

	mov si,0
	mov di,offset buffer
	mov cl,al
	mov ch,0
	shl cx,9	;convert KB to WORD
	rep movsw

;--- adjust BIOS variables 040Eh and 0413h

	push 40h
	pop es
	mov dx,cs
	mov cx,offset buffer
	shr cx,4
	add dx,cx
	mov ah,0
	mov es:[XBDAADR],dx
	add word ptr es:[MEMSIZE],ax
	mov di,ax

;--- increase the last DOS MCB

	mov ah,52h
	int 21h
	mov si,es:[bx-2]
nextitem:
	mov es, si
	mov dx, es:[MCB._size]	;get size of MCB
	inc dx
	add dx, si		;dx = next block
	cmp byte ptr es:[MCB.sig], 'M'
	jnz @F
	mov si, dx
	jmp nextitem
@@:
	mov ax,di
	shl ax,6
	add es:[MCB._size],ax

;--- tell DOS the amount of driver's memory to keep resident

	shl ax,4
	add ax,offset buffer
	lds bx,cs:[cmdptr]
	mov word ptr [bx.IODAT.trans+0],ax

;--- hook int 19h

	push 0
	pop ds
	.386
	mov eax,ds:[19h*4]
	mov cs:[oldint19],eax
	.286
	mov ds:[19h*4+0], offset myint19
	mov ds:[19h*4+2], cs

exit:
	pop es
	pop ds
	popa
	ret
devintfirst endp

str1 db "MOVEXBDA moves XBDA to low memory. Must be run before the EMM in CONFIG.SYS",13,10
	db "Usage: DEVICE=MOVEXBDA.EXE",13,10
	db '$'

main:
	mov dx,offset str1
	push cs
	pop ds
	mov ah,9
	int 21h
	mov ax,4C00h
	int 21h

_TEXT ends

STACK segment stack 'STACK'
	db 400h dup (?)
STACK ends

	END main
