			
;syet.com [command]...
;command may be one of
;       read [<Drive>:][<path>]
;       write [<Drive>:][<path>]
;       patch
;       bootdrive <Drive>:
;       bootdisk <HH>
;       biofile <filename>
;       dosfile <filename>
;       dosver  <digit>
;       force

MSGI_INVALID_DRIVE      equ 1
MSGI_RW_FAILED          equ 2
MSGI_FAT32              equ 3
MSGI_DRIVE_MISMATCH     equ 4
MSGI_FOPEN_FAILED       equ 5
MSGI_INVALID_DOSBOOTI   equ 6
MSGI_INVALID_DOSVER     equ 7
MSGI_INVALID_COMMAND    equ 8
MSGI_EXPECTED_TOKEN     equ 9
MSGI_INVALID_FNAME      equ 10
MSGI_INVALID_BUFFER     equ 11

.8086
.alpha
dgroup GROUP acode,code,zss
assume cs:dgroup
assume ds:dgroup
assume ss:dgroup
assume es:dgroup

code segment public
extrn VBR_START
code ends

COMMAND_COUNT   equ 9
DOSFILE_CMDNUM  equ 6

acode segment byte
org 100h
disk_rw_packet label byte       ; Memory optimized
start:

push ds
pop es

mov si,80h
xor bx,bx
mov bl,[si]
inc si
mov byte ptr [ds:bx+si],bh
mov word ptr [nexttok], si
next_command:
call readtok
jc lexic_failed
mov si,di
call lexic
mov dl,MSGI_INVALID_COMMAND
jc ferror1
;push si
;call outsz
;pop si
call run_command
jmp short next_command

lexic_failed:
mov ax, 4C00h
int 21h

;invalid_command:
;mov si,offset dgroup:msg_invalid_command
;jmp ferror

readtokM proc near
	call readtok
	mov dl,MSGI_EXPECTED_TOKEN
	jc ferror1 ; expected_token
	mov si,di
	ret

	;expected_token:
	;mov si,offset msg_expected_token
	;jmp ferror
readtokM endp
readtok proc near
; On entry [ds:nexttok] points to the start of the next command line token.
; On exit: carry is clear if a token was found.
; On success: SI and [ds:nexttok] points to the start of the next token and the prev token is terminated with a zero and DI points to the start of the current token, with prefix spaces eaten.
	mov si, word ptr [nexttok]
	eatspaces:
	lodsb
	test al,al
	jz endoftokens
	cmp al," "
	jz eatspaces
	dec si
	mov di,si
	nexttoklbl:
	lodsb
	test al,al
	jz nulfound
	cmp al," "
	jz tokenfound
	jmp short nexttoklbl
	tokenfound:
	mov byte ptr [si-1],0
	tokensuccess:
	mov word ptr [nexttok], si
	clc
	ret

	nulfound:
	dec si
	jmp short tokensuccess

	endoftokens:
	stc
	ret
readtok endp
outsz proc near
; On entry ds:si points to the start of a zero-terminated string
; Outputs this string.
; Trashes AX and DX.
	mov ah,02h
	outsz_loop:
	lodsb
	test al,al
	jz outsz_endloop
	mov dl,al
	int 21h
	jmp short outsz_loop
	outsz_endloop:
	ret
outsz endp

lexic proc near
; On entry ds:si points to the start of a token.
; On exit CX=lex number
; Trashes AX, preserves SI
lexRead equ 0
lexWrite equ 1
lexPatch equ 2
	mov di,offset dgroup:words
	xor cx,cx
	
	nextword:
	push si
	cmpchar:
	lodsb
	cmp al,[di]
	jnz wordfailed
	test al,al
	jz wordsuccess
	inc di
	jmp short cmpchar
	
	wordfailed:
	mov al,[di]
	inc di
	test al,al
	jnz wordfailed
	pop si
	inc cx
	cmp cx,COMMAND_COUNT
	;jz nonword
	;jmp short nextword
	jb nextword
	
	nonword:
	stc
	ret
	wordsuccess:
	clc
	pop si
	ret
lexic endp
ferror1: jmp ferror2

run_command proc near
; cx contains 0, 1 or 2. 0=read, 1=write 2=patch
	mov bx,cx
	add bx,bx
	add bx,offset dgroup:cmdtable
	jmp word ptr [bx]
run_command endp

;fopen_failed:
;mov si,offset msg_fopen
;mov dl,MSGI_FOPEN_FAILED
;jmp ferror

writeop:
	; AL=drivenum, CL=1 (write)
	mov [bufloc], offset dgroup:ckbuffer
	push ax                         ; save drivenum
	cmp [forced],0
	jnz after_mismatch_check
	call rw_first_sector            ; read
	mov si, offset dgroup:buffer   + 0Bh
	mov di, offset dgroup:ckbuffer + 0Bh

	mov cx,15h-0Bh                  ; Number of bytes of vital info
	repz cmpsb
	mov dl,MSGI_DRIVE_MISMATCH
	;jnz drive_mismatch
	jnz ferror1
	inc si                          ; jump over Media descriptor byte
	lodsw                           ; read sectors per FAT count
	cmp ax,[di+1]
	;jnz drive_mismatch
	; dl is still MSGI_DRIVE_MISMATCH
	jnz ferror1

	after_mismatch_check:
	inc [read_or_write]             ; then, write
	pop ax                          ; Restore drivenum
	jmp short rw_apply

rw_command proc near
	call readtokM
	test cx,cx
	jnz notaread
	; It's a read operation
	mov [valid_buffer],1
	notaread:
	cmp word ptr [di+1],003Ah       ; Is Drive:\0 ?
	jz drive_name
	push cx                         ; 0=read 1=write
	mov dx,di                       ; File name
	pop cx
	push cx
	xor ax,ax                       ; AL=0=sharing mode when reading
	mov ah,3Dh
	sub ah,cl                       ; AH=3Dh if reading, 3Ch if writing
	xor cx,cx                       ; No file attribute

	int 21h                         ; Create file
	mov dl,MSGI_FOPEN_FAILED
	jc ferror1 ;fopen_failed
	xchg bx,ax                      ; bx=file handle
	pop ax
	add ax,3Fh                      ; ax=3Fh if read, 40h if write
	xchg ah,al
	mov cx,200h                     ; R/W a sector
	mov dx, offset dgroup:buffer
	int 21h
	jc rw_failed
	mov ah,3Eh
	int 21h                         ; Close file handle
	ret
	;drive_mismatch:
	;mov si,offset msg_drive_mismatch
	;jmp short fatal_error
	
	drive_name:
	mov [read_or_write],0
	call letter_to_drivenum
	test cl,cl
	; at this point AL = drivenum, CL=1 if writing, 0 if reading
	jnz writeop                     ; If it's a write op
	rw_apply:
	mov [bufloc], offset dgroup:buffer

	rw_first_sector:
	; INPUT:
	; AL = zero-based drivenum
	; [read_or_write]=0 to read, 1 to write
	; [bufloc] = 16 bits offset of the buffer
	; Trashes pretty all GP registers except SP
	mov cx,1                        ; copy 1 sector
	xor dx,dx                       ; at sector 0
	mov bx,[bufloc]                 ; into buffer
	call int2526

	cmp ax,0207h
	jnz rw_ntl

	; > 32M disk
	big_rw:
	mov cx,-1
	mov di,offset dgroup:disk_rw_packet
	mov bx,di
	xor ax,ax
	stosw
	stosw                           ; sector 0
	inc ax
	stosw                           ; 1 sector to rw
	mov ax,[bufloc]
	stosw
	mov ax,ds
	stosw                           ; ds:buffer is the buffer

	xchg ax,dx                      ; restore drive number
	call int2526
	cmp ax,0207h
	jnz rw_failed
	; FAT32 partition
	;mov si, offset msg_fat32
	;jmp short fatal_error
	mov dl,MSGI_FAT32
	jmp short ferror2
	
	rw_success:
	pop ax          ; pops EIP

	ret
	rw_ntl:
	cmp ax,0408h    ; Bug of CPWIN386.CPL
	xchg ax,dx
	or  al,80h      ; Retry with high bit of drive num set
	mov cx,1
	xor dx,dx
	call int2526
	cmp ax,0207h
	jnz rw_failed
	jmp short big_rw

	rw_failed:
	;mov si,offset msg_rw_failed
	mov dl,MSGI_RW_FAILED
	jmp short ferror2
	
rw_command endp

;;;;;;;;;;;;;;;;;;;;;;;; ERROR FUNCTION ;;;;;;;;;;;;;;;;;
ferror:         ; on input DL = 1-based msg number
ferror2:
push dx
mov di, offset msgs
xor ax,ax
nextmsg:
mov cx,0FFFFh
repnz scasb
dec dl
jnz nextmsg

;fatal_error:
mov si,di
call outsz
pop ax
mov ah,4Ch
int 21h

bootdrive_command proc near
	call asserts_buffer
	call readtokM
	cmp word ptr [di+1],003Ah
	jnz invalid_drive
	call letter_to_drivenum
	cmp al,8
	jb below8
	aboveeq8:
	inc al
	below8:
	add al,0F0h                     ; A: = F0h, C: = F2h, D: = F3h, H: = F7h, F8h unused, I: = F9h J: = FAh
	mov [buffer+1FCh],al            ; RootPartition
	ret
bootdrive_command endp
int2526 proc near
	push ax
	push bx
	mov [spback],sp

	mov bp,sp               ; [es:bp+1Eh] may be trashed... So it's safe to set bp as the buffer start.
	cmp [read_or_write],0   ; Is it read op?
	jnz int26
	int 25h ; read
	jmp short notint26
	int26: int 26h
	notint26:

	mov sp,[spback]
	pop bx
	pop dx
	;test ax,ax
	;jz rw_success
	jnc rw_success
	ret
int2526 endp

bootdisk_command proc near
	call asserts_buffer
	; bootdisk must be specified as a hex BIOS drive num.
	; e.g. 80 for first hard disk. 00 for first floppy disk.
	call readtokM
	lodsb
	call ascii2hex
	xchg dx,ax
	lodsb
	call ascii2hex
	mov cl,4
	shl dx,cl
	; AL=low nibble DL=high nibble*16
	add dl,al
	lodsb
	test al,al
	jnz invalid_drive
	cmp byte ptr [buffer+26h],29h   ; extended BPB signature
	jnz invalid_DOSbootI            ; No extended BPB -> bootdisk unsupported.
	mov [buffer+24h],dl             ; BIOS boot disk

	ret
	ascii2hex:
	sub al,'0'
	cmp al,10
	jb okAscii2hex
	or al,32
	add al,'0'-'a'+10
	okAscii2hex:
	ret
bootdisk_command endp
	invalid_drive:
	;mov si,offset msg_invalid_drive
	mov dl,MSGI_INVALID_DRIVE
	jmp short ferror3

	invalid_DOSbootI:
	;mov si,offset msg_invalid_DOSbootI
	mov dl,MSGI_INVALID_DOSBOOTI
	jmp short ferror3


patch_command proc near
	call asserts_buffer
	mov si,offset dgroup:VBR_START
	mov di,offset dgroup:buffer
	cmp byte ptr [si], 0EBh         ; check DOSbootI VBR starts with a short jmp
	jnz invalid_DOSbootI
	movsb
	xor ax,ax
	lodsb                           ; rel8 of the VBR initial short jmp
	cmp al,22h
	jl invalid_DOSbootI             ; initial jmp must jump over basic BPB
	add si,ax
	stosb
	add di,ax
	mov cx,200h-2                   ; sector size - initial short jmp size
	sub cx,ax
	rep movsb
	; now si points to the start of the real code
	ret
patch_command endp

invalid_dosver:
;mov si,offset dgroup:msg_invalid_dosver
mov dl, MSGI_INVALID_DOSVER
jmp short ferror3

letter_to_drivenum proc near
	; reads drive letter from [di] and store drivenum into AL
	mov al,byte ptr [di]
	or al,32                        ; ToLowercase
	sub al,"a"
	cmp al,26
	jae invalid_drive
	ret
letter_to_drivenum endp

ferror3: jmp ferror2
msfile_command proc near
	call asserts_buffer
	call readtokM
	lea bx,[buffer+1E0h+11]
	sub cx,DOSFILE_CMDNUM                   ; -1 if biofile, 0 if dosfile
	and cx,11                               ; size of filename
	sub bx,cx
	mov di,bx
	mov cx,8
	add bx,cx                                ; file part of filename
	inc cx

	copy_name:
	lodsb
	test al,al
	jz noext
	cmp al,"."
	jz fill_to_ext
	stosb
	;jmp short copy_name
	dec cx
	jnz copy_name
	invalid_fname: mov dl,MSGI_INVALID_FNAME
	jmp short ferror3

	noext:
	dec si

	fill_to_ext:
	mov al," "
	fill_to_ext_next: cmp di,bx
	jae ext
	stosb
	jmp short fill_to_ext_next

	ext: add bx,3                   ; extension part of the filename
	mov cx,4
	ext_next:
	lodsb
	test al,al
	jz fill_ext
	stosb
	;jmp short ext_next
	dec cx
	jnz ext_next
	jmp short invalid_fname
	; WARNING: There must be at least one byte after the last extension byte

	fill_ext:
	mov al," "
	fill_ext_next: cmp di,bx
	jae end_fname
	stosb
	jmp short fill_ext_next

	end_fname:
	ret
msfile_command endp

dosver_command proc near
	call asserts_buffer
	call readtokM
	lodsb
	sub al,'0'
	cmp al,10
	jae invalid_dosver
	xchg dx,ax
	lodsb
	test al,al
	jnz invalid_dosver
	mov [buffer+1FBh],dl                    ; Set DOS version
	ret
dosver_command endp

asserts_buffer proc near
	cmp [valid_buffer],0
	mov dl,MSGI_INVALID_BUFFER
	jz ferror3
	ret
asserts_buffer endp

force_command proc near
	mov [forced],1
	ret
force_command endp


words db "read",0,"write",0,"patch",0,"bootdrive",0,"bootdisk",0,"biofile",0,"dosfile",0,"dosver",0,"force",0

cmdtable dw offset rw_command, offset rw_command
	 dw offset patch_command
	 dw offset bootdrive_command
	 dw offset bootdisk_command
	 dw offset msfile_command
	 dw offset msfile_command
	 dw offset dosver_command
	 dw offset force_command

msgs                    db 0
msg_invalid_drive       db "Invalid disk or drive name",0
msg_rw_failed           db "I/O error",0
msg_fat32               db "FAT32 is not supported by DOSbootI",0
msg_drive_mismatch      db "Drive BIOS Parameters Block mismatch",0
msg_fopen_failed        db "Couldn't open file",0
msg_invalid_DOSbootI    db "Internal error: Invalid DOSbootI VBR",0
msg_invalid_dosver      db "Invalid version number",0
msg_invalid_command     db "Unknown command",0
msg_expected_token      db "Unexpected end of parameters",0
msg_invalid_fname       db "Invalid file name",0
msg_invalid_buffer      db "Sector must be first loaded",0

bufloc          dw offset dgroup:buffer
valid_buffer    db 0
forced          db 0
acode ends

zss segment byte
nexttok dw ?
spback  dw ?
read_or_write db ?
buffer db 512 dup(?)
ckbuffer db 512 dup(?)
zss ends

end start
