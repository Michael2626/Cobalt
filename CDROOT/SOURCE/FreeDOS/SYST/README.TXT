===============SYNOPSIS===============

syet.com [command]...
command may be one of
       read [<Drive>:][<path>]
       write [<Drive>:][<path>]
       force
       patch
       bootdrive <Drive>:
       bootdisk	<HH>
       biofile <filename>
       dosfile <filename>
       dosver <digit>

===============EXAMPLES===============
C:\> syet.com read C: patch write C:
Is very similar to
C:\> sys.com C:
But doesn't store IO.SYS, MSDOS.SYS and COMMAND.COM on C:.

C:\> syet.com read D: write C:\VBR_D.BAK patch bootdrive D: write D:\DOSbootI.VBR write D:

Would backup the D: volume boot record in a 512 bytes file C:\VBR_D.BAK, and then, overwrite it with a DOSbootI patched volume boot record (with MediaType=F3h=D: passed to IO.SYS; useful if it's IO.SYS AD) and save a copy of the patched VBR as D:\DOSbootI.VBR which may be useful to be used with GRUB.

===============COMMANDS================
=======================================
	read [<Drive>:][<path>]
		It may be used in two ways.
		read <Drive>:
			Reads the first 512 bytes sector of the specified drive and stores it in the buffer that may be subsequently used in write or patch commands.
		read [<Drive>:]<path>
			Reads the first 512 bytes of the specified file on disk and stores it in the buffer.
=======================================
	write [<Drive>:][<path>]
		Similar to read but writes the buffer, rather than reading it, to either the first sector of a drive or the first 512 bytes of a regular file.
		To avoid accidental shooting in one's foot, the write command fails if the buffer contains a highly incompatible BIOS parameters block. Disk geometry (heads and sectors count) and boot info (e.g. hidden sectors count) may be destroyed but vital information (e.g. size of FAT, size of clusters, etc.) cannot be modified.
		e.g.
		syet.com read C: patch write D:
		Is usually an error.
=======================================
	force
		Makes subsequent write operations ignore BIOS parameters block mismatches.
		This is very dangerous and should be used only if you know what you are doing.
		Basically, this should be used to restore the BPB of a corrupted partition that cannot be mounted anymore.
=======================================
	patch
		Patches the VBR contained in the buffer with DOSbootI code. Fails if buffer has not been loaded.
		bootdrive defaults to C:. bootdisk defaults to 80. dosver defaults to 3
=======================================
	bootdrive <Drive>:
		Patches the VBR contained in the buffer at byte 1FCh to make it boot on another drive.
		e.g.
			boodrive C:
			Sets byte 1FCh to F2h
=======================================
	bootdisk <HH>
		HH must be two hex digits. It's a BIOS int 13 disk number.
		00 = First floppy disk drive
		01 = Second floppy disk drive
		...
		80 = First hard disk drive
		81 = Second hard disk drive
		82 = Third hard disk drive
		...
		Both bootdisk and bootdrive must be properly set in order to allow DOSbootI to properly boot.
		This is stored at byte 24h
=======================================
	biofile|dosfile <filename>
		Patches the buffer with alternate IO.SYS or MSDOS.SYS names.
		Accepts a 8.3 upper-case short file name that has to be copied to the root directory of the boot drive.
		Note: It must be all-upper-case.
		It patches the buffer at byte 1E0h->1EBh for biofile and 1EBh->1F6h for dosfile.
=======================================
	dosver <decimal-digit>
		Indicates that DOSbootI should use the boot convention of this version of IO.SYS.
		Currently, "dosver 2" is compatible with PC-DOS 2 only while "dosver 3" is compatible with PC/MS-DOS 3->7.10.
		It patches the buffer at byte 1FBh
