@ECHO OFF
SET DOSDIR=C:\COBALT
SET LANG=FR
SET TZ=UTC
SET PATH=%dosdir%\BIN
if exist %dosdir%\LINKS\NUL SET PATH=%path%;%dosdir%\LINKS
SET NLSPATH=%dosdir%\NLS
SET TEMP=%dosdir%\TEMP
SET TMP=%TEMP%
SET BLASTER=A220 I5 D1 H5 P330
SET DIRCMD=/P /OGN /Y
SET COPYCMD=/-Y

keyb FR

cls
SET AUTOFILE=%0
SET CFGFILE=C:\CONFIG.SYS
alias reboot=fdapm warmboot
alias reset=fdisk /reboot
alias halt=fdapm poweroff
alias shutdown=fdapm poweroff
alias cfg=edit %cfgfile%
alias auto=edit %0

set OS_NAME=COBALT
set OS_VERSION=1.3

cls
echo.

echo Bienvenue sur %OS_NAME% %OS_VERSION%.
echo You are currently in safe mode.
echo All drivers in the systems have been disabled.
echo Please restart in normal mode to re-enable all drivers.
echo.