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

DEVLOAD /H /Q %dosdir%\BIN\UDVD2.SYS /D:FDCD0001

LH FDAPM APMDOS
LH SHARE
IF EXIST %DOSDIR%\DRV\DOSLFN\DOSLFN.COM LH DOSLFN

%DOSDIR%\DRV\CTMOUSE\CTMOUSE.EXE

keyb FR

%DOSDIR%\DRV\SHSUCDX\SHSUCDX.COM /QQ /D3

%DOSDIR%\DRV\SHSUCDX\SHSUCDX.COM /QQ /~ /D:?SHSU-CDR,D /D:?SHSU-CDH,D /D:?FDCD0001,D /D:?FDCD0002,D /D:?FDCD0003,D

MEM /C /N
%DOSDIR%\DRV\SHSUCDX\SHSUCDX.COM /D

if exist \WINDOWS\SYSTEM\DOSX.EXE goto windowsinfo
goto end

:windowsinfo
if exist %dosdir%\WININFO.TXT goto end
cls
%dosdir%\BIN\SUSCR.EXE /D " Information sur Microsoft Windows " /M "Appuyez sur ENTREE pour quitter."
echo.
echo  Cobalt a d‚tect‚ que vous venez d'installer Microsoft Windows.
echo  Seuls Microsoft Windows 3.0, 3.1 et 3.11 sont pris en charge par COBALT.
echo  Les autres versions peuvent peut-ˆtre fonctionnelles,
echo  mais elles n'ont pas ‚t‚ test‚es.
echo.
echo  Pour ex‚cuter Windows dans COBALT, tapez RUNWIN au lieu de WIN.
echo.
echo.
pause >nul
echo A > %dosdir%\WININFO.TXT
goto end

:END
cls
SET AUTOFILE=%0
SET CFGFILE=C:\CONFIG.SYS
alias reboot=fdapm warmboot
alias reset=fdisk /reboot
alias halt=fdapm poweroff
alias shutdown=fdapm poweroff
alias cfg=edit %cfgfile%
alias auto=edit %0

set OS_VERSION=1.3

if exist %dosdir%\bin\fdnet.bat call %dosdir%\bin\fdnet.bat start

cls
echo.

echo Bienvenue sur Cobalt %OS_VERSION%.
echo Tapez HELP pour voir toutes les commandes.
if exist \GEM.BAT echo Tapez GEM pour ouvrir OpenGEM.
if exist \BIN\DOSSHELL.COM echo Tapez DOSSHELL pour ouvrir le Shell.
if exist \WINDOWS\SYSTEM\DOSX.EXE echo Tapez RUNWIN pour ex‚cuter Microsoft Windows.
echo.