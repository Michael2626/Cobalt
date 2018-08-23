
.8086
.alpha
dgroup GROUP code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;; CONSTANTS ;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BR_LOAD_ADDR		equ 7C00h
DIR_LOAD_ADDR		equ 700h
DPT_BACKUP_LOCATION	equ DIR_LOAD_ADDR-4
DPT_INT_LOC		equ 1Eh*4
DIR_COMM_ADDR		equ 500h
IOSYS_LOAD_ADDR		equ 700h
SECSIZE			equ 200h
DIRENT_SIZE		equ 20h
DIRENT_FILESIZE 	equ 1Ah ; offset of the file size word in a dirent
FDP_SETTLE_TIMEOFF 	equ 09h ; Offset of the head settle time in the diskette parameters table
FDP_SETTLE_TIMEVAL 	equ 15  ; New value of the settle time

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;      Variables relative to bp=BR_LOAD_ADDR     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ClustAreaLowOff		equ (-4)
ClustAreaHighOff	equ (-2)

cBytesInSectorOff	equ 0Bh
cSectorsInClusterOff	equ 0Dh
cReservedSectorsOff	equ 0Eh
cFATsOff		equ 10h
cRootDirEntriesOff	equ 11h
cSectorsInFATOff	equ 16h
cSectorsInTrackOff	equ 18h
cHeadsOff		equ 1Ah
cHiddenSectorsOff	equ 1Ch
BiosBootDriveOff	equ 24h
TmpHeadOff		equ 25h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;; SEGMENT DECLARATION ;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
secdata segment at 0
        org 0
        zero label word
        org 7DFBh
        IOSYSVersion  db ? ;3
        RootPartition db ? ;80h
        db ? ; 0
        db ?,? ;055h, 0AAh
secdata ends

code segment byte
assume cs:code


;org BR_LOAD_ADDR

public VBR_START
VBR_START:

SectorStart:
	jmp short CodeStart
	nop

; Begin of Bios parameter block for a typical 1440K floppy disk

			db	"MSDOS5.0"
cBytesInSector		dw	SECSIZE
cSectorsInCluster	db	1
cReservedSectors	dw	1
cFATs			db	2
cRootDirEntries		dw	0E0h
cFsSectors16		dw	2880
MediaType		db	0F0h
cSectorsInFAT		dw	9
cSectorsInTrack		dw	18
cHeads			dw	2
cHiddenSectors		dd	1
cFsSectors32		dd	0
BiosBootDrive		db	00h	; 00h for floppy, 80h for Hdd
TmpHead			db	0
ExHeaderMagic		db	29h
SerialNumber		dd	0
DriveLabel		db	"NO NAME    "
FsIdentifier		db	"FAT12   "

;;;;;;;;;;;;;;;;;;; START OF CODE ;;;;;;;;;;;;;;;;;
;; INT 19 ensures that:
;; dl=drivenum
;; CS:IP = 0:7C00
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CodeStart:
	cli ; set up stack
	xor ax,ax
	mov ss,ax
	mov es,ax
        assume ss:secdata
        assume es:secdata
	assume ds:nothing

	; Set up stack just below the boot record code
	; Invariant: bp points at top of stack until the final JMP FAR to IO.SYS
	; Positive offsets relative to bp are used to address BPB data
	; And negative offsets can address known stack data
	
	mov sp,DPT_BACKUP_LOCATION+4
	mov bp,BR_LOAD_ADDR
	
;;;;;;;;;;;;;;;;;; SETUP DISKETTE PARAMETERS ;;;;;;;;;;;;;;;;;;;
;; On entry: SP=700h BP=BR_LOAD_ADDR
;; Abbreviation: DPT = diskette parameters table
;; 4 ms head settle time -> 15 ms
;; Avoids I/O error due to slow head
;;
;; Stores the following words at 700h-4
;; [old DPT offset	] word
;; [old DPT segment	] word
;; 
;; This is to make it easy to restore the old DPT on fatal error
;; On exit CX=0, BP=SP=BR_LOAD_ADDR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov bx,DPT_INT_LOC	; Address of floppy disk parameters block
	lds si,[bx]
	push si
	push bx
	mov di,(offset CodeStart)-(offset SectorStart)+BR_LOAD_ADDR
	mov [bx],ax		; ax=0
	mov [bx+2],di
	mov cx,0Eh
	mov sp,bp
	cld
	rep movsb		; Copy floppy disk parameters to the boot record code area (7C3Eh)
	; Now, cx is zero
	
	; Set "head settle time" to 15 milliseconds.
	
	mov byte ptr [bp+(offset CodeStart)-(offset SectorStart)+FDP_SETTLE_TIMEOFF], FDP_SETTLE_TIMEVAL
	sti			; We can safely restore interruptions
	; ah=0 and dl=drive num
	int 13h			; Reset floppy disk (needed after changing diskette parameters).
	
;;;;;;;;;;;;;;;;; COMPUTE SECTOR NUMBERS ;;;;;;;;;;;;;;;;;;
;; On fixed disk, sector numbers are absolute.
;; i.e. sector #0 = MBR
;;
;; On entry:
;; CX = 0
;; SP = BR_LOAD_ADDR
;; BH = 0
;;
;; On exit:
;; CX = Number of sectors in root dir
;; AX:DX = First sector of root dir
;; SI:DI = First sector of clusters area. That is: First sector after root dir
;; 8 bytes are pushed on the stack.
;; SI:DI (cluster data area first sector) is pushed twice.
;; Once to leave it to MS-DOS 7.x and once to pop it in BX:AX for MS-DOS 3.x-6.x
;; SP = BR_LOAD_ADDR-8
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	push es
	pop ds
        assume ds:secdata
;;;;;;;;;;;;;;;;;;;;; SEGMENT REGISTERS ;;;;;;;;;;;;;;;;;;;;
;; CS=DS=ES=SS=0 until end of boot record
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	xchg ax,bx	; -> bx=0 and ah is kept equal to zero.
	mov al,[bp+cFATsOff]	; Determine sector dir starts on
	mul word ptr [bp+cSectorsInFATOff]
	add ax,[bp+cHiddenSectorsOff]
	adc dx,[bp+cHiddenSectorsOff+2]
	add ax,[bp+cReservedSectorsOff]
	adc dx,cx ; cx=0
	; AX:DX = First sector of root dir
	
	mov si,[bp+cRootDirEntriesOff]
	add si,0Fh
	mov cl,4	; 16 dir entries per sector
	shr si,cl
	mov cx,si	; number of sectors of the root directory
	add si,ax
	mov di,dx
	adc di,bx ; bx=0
	; SI:DI = First sector of cluster data area
	
	push di		; = [bp+ClustAreaHighOff]
	push si		; = [bp+ClustAreaLowOff]
	push di
	push si

;;;;;;;;;;;;;;;;;;;;;; SEARCH DIRECTORY ENTRIES ;;;;;;;;;;;;;;;;;;;;;;
;; On entry:
;; SP = BR_LOAD_ADDR-8
;; CX = number of sectors in root directory
;; On exit, 4 bytes are pushed:
;; [IO.SYS first cluster	] word
;; [MSDOS.SYS first cluster	] word
;; If MSDOS.SYS is not found, 0000h is pushed on the stack
;; If IO.SYS is not found, we jmp to FatalError
;; SP = BR_LOAD_ADDR-12
;;
;; Basic algorithm:
;; Load first directory sector at DIR_LOAD_ADDR
;; Search for IO.SYS in each dir entry up to DIR_LOAD_ADDR+SECSIZE
;; Stop loading dir sectors if found
;; Else, load next directory sector at DIR_LOAD_ADDR.
;; If IO.SYS is not found (all dir sectors have been read), go to FatalError
;; If IO.SYS is found, pushes its first sector on stack
;; Start again (loading again the directory) with MSDOS.SYS
;; But, that time, failure is not fatal (zero is pushed).
;;
;; Algorithm details:
;; ;;;;Register SI;;;;
;; At (almost) any time, SI = address of the 11-bytes file name string (near end of boot record)
;; i.e. DS:SI may point to "IO      SYS" or "MSDOS   SYS".
;; NB: These two strings are contiguous, without nul byte in between.
;; First, the algorithm is ran for IO.SYS
;; And then, SI is incremented by 11 bytes (automatically by repz cmpsb)
;; And the algorithm is ran again for MSDOS.SYS
;;
;; ;;;; Register BX;;;;
;; BX points to the current directory entry DIR_LOAD_ADDR + n * DIRENT_SIZE
;; ;;;; Register DI;;;;
;; DI points to the file name in the dirent (used for comparison to DS:SI)
;; ;;;; Register CX;;;;
;; Temporarily used for the string comparison with repz cmpsb on 11 bytes
;; Second use: Decrementing counter of dir sectors to load
;; For that, cx is pushed on stack, and popped only before looping with 'loop'
;; Moreover, cx is backed up on the stack to be restored when MSDOS.SYS has to be searched
;; ;;;; Registers AX:DX ;;;;
;; Current sector number of the root directory.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        mov si,BR_LOAD_ADDR+offset IOsys
	
TryNextSysFile:
	push cx
	push dx
	push ax
TryDirSector:
	push cx
	mov bx,DIR_LOAD_ADDR
	
	call LoadSector ; Load sector AX:DX to 0:BX and increments AX:DX
	jc FatalError
	
TryDirEntry:
	mov di,bx
	mov cx,11
	push si
	repz cmpsb
	jz short EntryFound
	pop si
	
	add bx, DIRENT_SIZE
	cmp bh,(DIR_LOAD_ADDR+SECSIZE)/100h	; Assume it's multiple of 100h
	jb TryDirEntry
	pop cx
	loop TryDirSector
	inc si		; Needed to discriminate cases in PostEntryFound
	xor di,di
	jmp short PostEntryFound

EntryFound:
	pop cx ; discards old si
	pop cx
	mov di, word ptr [bx+DIRENT_FILESIZE]
PostEntryFound:
	pop ax
	pop dx
	pop cx
	push di ; pushes cluster of IO.SYS and then MSDOS.SYS
        cmp si,BR_LOAD_ADDR+offset IOsys+11
		;22 EntryFound, 12 EntryNotFound -> EndDirectoryScan
		;11 EntryFound -> TryNextSysFile
		;1 EntryNotFound -> FatalError
	ja EndDirectoryScan
	jz TryNextSysFile


;;;;;;;;;;;;;;;;;; FATAL ERROR ;;;;;;;;;;;;
;; 1) Display error message
;; 2) Wait for keypress
;; 3) Restore diskette parameters table
;; 4) Fast reboot with int 19h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FatalError:
        mov si, BR_LOAD_ADDR+offset ErrorMessage
	lodsb
PrintNextChar:
	mov ah,0Eh
	mov bx,7
	int 10h		; Write out char
	lodsb
	test al,al
	jnz PrintNextChar
	
	xor ah,ah
	int 16h		; Wait keypress
	mov si,DPT_BACKUP_LOCATION
	mov di,DPT_INT_LOC
	movsw
	movsw
	int 19h		; Fast reboot

;;;;;;;;;;;;;;;;;;; LOAD FIRST SECTORS OF IO.SYS  ;;;;;;;;;;;;;;;;
;; On entry:
;; SP = BR_LOAD_ADDR-12
;; Stack layout is:
;; [ClustAreaHighSectorNum		] word
;; [ClustAreaLowSectorNum		] word
;; [ClustAreaHighSectorNum		] word
;; [ClustAreaLowSectorNum		] word
;; [First cluster of IO.SYS		] word
;; [First cluster of MSDOS.SYS or zero	] word
;; We are going to:
;; 1) Compute the first sector absolute number of IO.SYS in AX:DX
;; 2) Load 26 KB of contiguous sectors of IO.SYS
;; This is because 3 or 4 sectors are needed for MS-DOS 4+
;; but MS-DOS 3.3 requires a whole cluster (which may be up to 8 KB)
;; and PC-DOS 2.x requires the whole IBMBIO.COM to be loaded at once
;; On exit:
;; SP = BR_LOAD_ADDR-8
;; SI = first cluster of MSDOS.SYS or zero if it had not been found
;; DI = first cluster of IO.SYS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
EndDirectoryScan:
	mov bx,IOSYS_LOAD_ADDR
	pop si
	mov [zero+DIR_COMM_ADDR+DIRENT_SIZE+DIRENT_FILESIZE], si	; first cluster of MSDOS.SYS
	pop ax
	mov [zero+DIR_COMM_ADDR+DIRENT_FILESIZE], ax			; first cluster of IO.SYS
	mov di,ax
	dec ax
	dec ax		; cluster #2 is actually the first cluster
	xor cx,cx
	mov cl,[bp+cSectorsInClusterOff]
	mul cx
	; AX:DX = First sector of IO.SYS, relatively to clusters data area.
	
	add ax,[bp+ClustAreaLowOff]
	adc dx,[bp+ClustAreaHighOff]
	
	; AX:DX = First sector of IO.SYS
LoadIOsys:
	call LoadSector
	jc IOsysLoaded
	add bx,[bp+cBytesInSectorOff]
	cmp bh,70h
	jbe LoadIOsys

;;;;;;;;;;;;;;;;;;;; SET UP ENVIRONMENT ;;;;;;;;;;;;;;;;;;;;;
;; 
;; Check which MS-DOS/PC-DOS we are going to load in order to
;; properly initialize registers and jump to the right address
;;
;; 1Eh*4 points to a temporary diskette parameters table.
;; MS-DOS will copy these parameters to a safe area and set up
;; The DPT pointer to point to the new table.
;;
;; DR-DOS assumes it's at 7C3Eh
;;
;; PC-DOS 2.11 requirements
;; All BPB info located at 7C00h
;; IBMBIO.COM must be entirely loaded at 0070:0000
;; Must MSDOS.SYS first cluster be stored at 53Ah ?
;; CS:IP = 0070:0000
;; BX = First sector of cluster data area
;; CX = Number of floppy disk drives (>= 2 since MS-DOS emulates a second floppy if there's none)
;; AX = Logical DOS drive number of the boot partition.
;; That is: AX=2 when booting on C: and AX=0 when booting on A:
;; Typically CX=2/AX=0 when booting on floppy and CX=2/AX=2 when booting on hard drive.
;; Other registers are probably ignored.
;;
;; MS-DOS 3.3 requirements:
;; All BPB info located at 7C00h
;; The entire first cluster (may be up to 8 kilobytes) of IO.SYS must be loaded at 0070:0000
;; IO.SYS and MSDOS.SYS exist and their first clusters must be stored at 51Ah and 53Ah
;; IO.SYS and MSDOS.SYS clusters may be at any position, and not necessarily contiguous
;; BX = First sector of cluster data area (absolute)
;; AX, SI, DI, SP, BP, SS, DS, ES, FLAGS are ignored.
;; CS:IP = 0070:0000
;; DL = Boot drive (80h or 00h)
;; CH = Media byte (F0h for 1440 K floppy, F8h for fixed disk)
;; 
;; MS-DOS 4.01 requirements:
;; Same as 3.3, but:
;; Requires only the first 3 sectors of IO.SYS to be loaded
;; Requires the first cluster of IO.SYS to be cluster #2
;; Subsequent clusters may be at any position, not necessarily contiguous
;; AX = High word of the first sector of cluster data area
;; i.e. BX:AX is a 32 bits sector number
;;
;; MS-DOS 5.0 and 6.x requirements:
;; Same as 4.01, but IO.SYS first cluster may be at any position.
;;
;; MS-DOS 7.x requirements:
;; All BPB info located at 7C00h
;; IO.SYS is loaded at 0070:0000
;; DI = First cluster of IO.SYS
;; CS:IP = 0070:0200
;; SS:BP = 0000:7C00
;; dword [BP-4] = First sector of the cluster data area (32 bits)
;; AX, BX, SI, DI, SP, FLAGS ignored.
;; IO.SYS must exist but MSDOS.SYS is optional.
;; DL = Ignored?
;; CH = 0/media byte/ignored ?
;; NB: The two first bytes of IO.SYS of MS-DOS 7.x are "MZ"
;; This is used to detect MS-DOS 7.x
;;
;; MS-DOS 6.22 improved:
;; Same as MS-DOS 6.22 but stores the boot drive logical number
;; in CH-0F0h so that CH=0F0h means A: and CH=0F3h means D:
;; That's why the [RootPartition] byte is loaded in CH rather
;; than MediaByte
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IOsysLoaded:
	mov dl,[bp+BiosBootDriveOff]
	pop bx		; ClustAreaHigh
	pop ax		; ClustAreaLow
        mov ch, [ds:RootPartition]
	cmp word ptr [zero+IOSYS_LOAD_ADDR], 5A4Dh ; "MZ"
	jz msdos7ormore
        cmp byte ptr [ds:IOSYSVersion], 2
	ja msdos3orMore
		
msdos2:
	; PC-DOS 2.x
	; If ch=F2 then cx=2 and ax=2
	; If ch=F0 then cx=2 and ax=0
	xor ah,ah	; Theoritically useless as AX=[BiosHigh]=0 with PC-DOS 2.x
	mov al,ch
	sub al,0F0h
	mov cx,2
	
msdos3orMore:
	test si, si
	jz FatalError	; Error if MSDOS.SYS had not been found.
	db 0EAh		; jmp far
	dw 0, IOSYS_LOAD_ADDR/10h
	
msdos7ormore:
	; Entry conditions of IO.SYS
	; DI = First cluster of IO.SYS
	; BP = 7C00h
	; [BP-4] = 32 bits absolute (including hidden sectors) sector number of the first cluster (after directory)
	db 0EAh		; jmp far
	dw 200h, IOSYS_LOAD_ADDR/10h

;;;;;;;;;;;;;;;;;;;;;; LOAD ONE SECTOR ;;;;;;;;;;;;;;;;;;;;;
;; This is a procedure
;; On entry:
;; BP = 7C00h
;; AX:DX = Sector number to load
;; ES=0 and ES:BX is a buffer ready to accept one sector
;;
;; On exit:
;; Carry set on error
;; On success:
;; Carry clear
;; AX:DX is incremented
;; BX, SI, DI, BP, BX are kept unchanged.
;; CX is trashed
;; Use int 13h/AH=42h extended read if possible.
;; Falls back to int 13h/AH=02h
;; See RBIL for details
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LoadSector:
	push si ; Saves si
	; Top of BIOS extended read block
	xor cx,cx
	push es
	push es
	push dx
	push ax		; Starting absolute block number above
	push es
	push bx		; Address of buffer
	inc cx
	push cx		; Number of sectors to copy
	mov cx,10h
	push cx		; Size of BIOS extended read block
	
	mov si,sp	; SI points to the BIOS extended read block
	
	push dx
	push ax
	
	mov ah, 42h
	mov dl,[bp+BiosBootDriveOff]
	int 13h
	jnc ExtendedReadSuccess
	
	; Extended read doesn't exist or failed.
	
	mov al, byte ptr [bp+cHeadsOff]
	mul byte ptr [bp+cSectorsInTrackOff]
	xchg cx, ax
	
	pop ax
	pop dx
	push dx
	push ax
	
	div cx
	push ax		; ax=CurTrk
	xchg ax, dx
	xor dx, dx
	div word ptr [bp+cSectorsInTrackOff]
	mov byte ptr [bp+TmpHeadOff], al
	inc dl		; dl=CurSec
	;mov al,dl	; al=CurSec
	xchg ax,dx	; al=CurSec ah=trash
	
	pop dx ; dx=CurTrk
	
	mov cl,6
	shl dh,cl
	or dh,al	;al=CurSec
	mov ch,dl
	mov cl,dh
	mov dx, [bp+BiosBootDriveOff] ; BootDrv and CurrentHead are two contiguous bytes
	mov ax, 0201h	; Copy AL=1 sector and AH=ROM_DISKRD
	int 13h

ExtendedReadSuccess:
	lahf
	pop si
	pop dx
	
	add sp,10h
	
	inc si
	adc dx,0
	
	sahf
	xchg ax,si
	
	
	pop si
	ret



;;;;;;;;;;;;;;;;;; STRING DATA ;;;;;;;;;;;;;;;;;;;;

db 0,0
ErrorMessage:
db 0Dh, 0Ah, "Disque non-systäme/erreur disque"
db 0Dh, 0Ah, "Remplacez et pressez touche", 0Dh, 0Ah, 0
;IOsys	DB	"IBMBIO  COM"
;DOSsys	DB	"IBMDOS  COM"
IOsys	DB	"IO      SYS"
DOSsys	DB	"MSDOS   SYS"

db 0,0,0,0, 0

;;;;;;;;;;;;;;;;; EXTRA PARAMETERS ;;;;;;;;;;;
cccIOSYSVersion db 3
cccRootPartition db 0F2h
db 0
Signature db 055h, 0AAh

code ends
end
