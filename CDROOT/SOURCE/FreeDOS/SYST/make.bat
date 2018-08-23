tasm boot.asm
tasm syst.asm
@tlink /t syst.obj boot.obj
@tlink /t syst.obj boot.obj
@dir syst.com
