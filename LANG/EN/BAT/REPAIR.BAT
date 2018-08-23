@echo off
break off

set bin=\COBALT\BIN
set ver=1.3

echo Loading setup...
echo.
cls

:repair
%bin%\SUSCR.EXE /D " Cobalt %ver% Repair " /M "Press ENTER to continue."
echo.
echo  This program is designed to repair an existing installation of Cobalt on
echo  your computer. It will copy the base DOS system to the drive (to ensure
echo  the drive is bootable), and then overwrite existing Cobalt system files
echo  with ones from this CD.
echo.
echo  This repair program will NOT erase any user data on your drive. It only
echo  repairs the Cobalt system folder.
echo.
echo.
pause >nul
%bin%\SUSCR.EXE /M "Setup is checking partitions on your hard drives..."
%bin%\GDISK.EXE 1|%bin%\FIND.EXE "No partitions defined" > nul
if not errorlevel 1 goto error
%bin%\GDISK.EXE 1|%bin%\FIND.EXE " PRI DOS"|%bin%\FIND.EXE "DOS"|%bin%\FIND.EXE "FAT" > nul
if errorlevel 1 goto error
%bin%\GDISK.EXE 1|%bin%\FIND.EXE " PRI DOS"|%bin%\FIND.EXE "C:"|%bin%\FIND.EXE "Unformatted"|%bin%\FIND.EXE "FAT" > nul
if not errorlevel 1 goto error
goto mbr

:chkact
%bin%\SUSCR.EXE /D " Cobalt %ver% Repair "
echo.
echo  Your hard drive was blank, so a new partition for Cobalt was created.
%bin%\GDISK.EXE 1|%bin%\FIND.EXE "      PRI DOS"|%bin%\FIND.EXE "C:"|%bin%\FIND.EXE "FAT" > nul
if not errorlevel 1 goto noactdc
goto mbr

:noactdc
%bin%\SUSCR.EXE /D " Cobalt %ver% Repair " /M "Making file system active..."
if errorlevel 1 if not errorlevel 2 %bin%\GDISK.EXE 1 /act /p:1
goto mbr

:mbr
%bin%\SUSCR.EXE /D " Cobalt %ver% Repair " /M "Do you want to overwrite the MBR?" /F "Y/N?"
echo.
echo  Rewriting the Master Boot Record (MBR) of your hard drive will ensure
echo  Cobalt will boot properly.
echo.
echo  If you use a custom boot manager (like GRUB) and want to keep it, DO
echo  NOT overwrite the MBR. If you have no idea what an MBR or GRUB is,
echo  just choose yes.
echo.
%bin%\CHOICE.EXE > nul
if errorlevel 2 goto mbrconfirm
if not errorlevel 2 goto verifyinstall

:mbrconfirm
%bin%\SUSCR.EXE /D " Cobalt %ver% Repair " /M "Rewriting the MBR..."
%bin%\GDISK.EXE 1 /mbr > nul
goto verifyinstall

:verifyinstall
%bin%\SUSCR.EXE /D " Cobalt %ver% Repair " /M "Checking for Cobalt system folder..."
if exist C:\SYSTEM\4DOS\4DOS.INI goto fixinstall
if exist C:\COMMAND.COM goto notcobalt
if exist C:\MSDOS.SYS goto notcobalt
if exist C:\KERNEL.SYS goto notcobalt
goto error

:fixinstall
%bin%\SUSCR.EXE /D " Cobalt %ver% Repair " /M "Repair Cobalt on C: drive?" /F "Y/N?"
echo.
echo  Repair has detected a previous installation of Cobalt on this drive.
echo  It will be repaired, and upgraded to the newest Cobalt version
echo  if needed. No user data will be deleted.
echo.
echo  Press Y to begin the repair, or N to cancel.
echo.
%bin%\CHOICE.EXE > nul
if errorlevel 2 goto cancel
%bin%\SUSCR.EXE /D " Cobalt %ver% Repair " /M "Removing hidden flags on system files..."
%bin%\ATTRIB.COM -H C:\AUTOEXEC.BAT
%bin%\ATTRIB.COM -H C:\CONFIG.SYS
%bin%\ATTRIB.COM -H C:\KERNEL.SYS
%bin%\SUSCR.EXE /D " Cobalt %ver% Repair " /M "Installing base DOS system..."
%bin%\SYS.COM A: C:
%bin%\SUSCR.EXE /D " Cobalt %ver% Repair " /M "Decompressing BASE.ZIP..."
%bin%\UNZIP.exe -o -q BASE.ZIP -d c:\%bin%\SUSCR.EXE /D " Cobalt %ver% Setup " /M "Decompressing %zip%\BASE.ZIP..."
%bin%\UNZIP.exe -o -q %zip%\BASE.ZIP -d c:\
%bin%\SUSCR.EXE /D " Cobalt %ver% Setup " /M "Decompressing %zip%\EN.ZIP..."
%bin%\UNZIP.exe -o -q %zip%\EN.ZIP -d c:\
if not errorlevel 0 goto error
del c:\COMMAND.COM
goto askdesktop

:askdesktop
%bin%\SUSCR.EXE /D " Cobalt %ver% Repair " /M "Install desktop?" /F "Y/N?"
echo.
echo  You can optionally install a desktop environment, called
echo  OpenGEM, so you don't have to use the command line. After
echo  Cobalt boots up, you can just type "GEM" and press ENTER
echo  to start the desktop.
echo.
echo  Press Y to install the desktop, or N to skip this step
echo.
%bin%\CHOICE.EXE > nul
if errorlevel 2 goto finishsetup
if not errorlevel 2 goto installdesktop

:installdesktop
%bin%\SUSCR.EXE /D " Cobalt %ver% Repair " /M "Decompressing DESKTOP.ZIP..."
%bin%\UNZIP.exe -u -o -q DESKTOP.ZIP -d c:\
if not errorlevel 0 goto error
goto complete

:complete
%bin%\SUSCR.EXE /D " Cobalt %ver% Repair " /M "Finished installation."
echo.
echo  Congratulations, your Cobalt installation has been fully repaired.
echo  Please eject the install disc and press ENTER to reboot
echo  your computer.
echo.
pause >nul
goto reboot

:notcobalt
%bin%\SUSCR.EXE /D " Cobalt %ver% Repair "
echo.
echo  The repair program found a DOS operating system on the internal drive,
echo  but no Cobalt system folder.
echo.
echo  If you have an existing DOS operating system on your drive, you need to
echo  upgrade it to Cobalt first with the normal installation program.
echo.
echo  Repair cannot continue, please press ENTER to restart your computer.
echo.
pause >nul
goto reboot

:error
%bin%\SUSCR.EXE /D " Cobalt %ver% Repair "
echo.
echo  The repair program could not find a Cobalt installation to repair.
echo.
echo  Repair cannot continue, please press ENTER to restart your computer.
echo.
pause >nul
goto reboot

:reboot
cls
A:\DRIVERS\FDAPM WARMBOOT
cls
