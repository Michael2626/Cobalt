@ECHO OFF
SET DOSDIR=C:\COBALT
SET LANG=EN
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

%DOSDIR%\DRV\SHSUCDX\SHSUCDX.COM /QQ /D3

%DOSDIR%\DRV\SHSUCDX\SHSUCDX.COM /QQ /~ /D:?SHSU-CDR,D /D:?SHSU-CDH,D /D:?FDCD0001,D /D:?FDCD0002,D /D:?FDCD0003,D

MEM /C /N

%DOSDIR%\DRV\SHSUCDX\SHSUCDX.COM /D

if exist \WINDOWS\SYSTEM\DOSX.EXE goto windowsinfo
goto end

:windowsinfo
if exist %dosdir%\WININFO.TXT goto end
cls
%dosdir%\BIN\SUSCR.EXE /D " Information about Microsoft Windows " /M "Press ENTER to exit."
echo.
echo  Cobalt has detected that you have just installed Microsoft Windows.
echo  Please note that only Microsoft Windows 3.0, 3.1, and 3.11 
echo  are supported by Cobalt.
echo  Other versions may work, but are not tested.
echo.
echo  To run Windows in Cobalt, type RUNWIN instead of WIN.
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

if exist %dosdir%\bin\fdnet.bat call fdnet.bat start
if exist %dosdir%\bin\welcome.bat call welcome.bat start
if exist %dosdir%\bin\setinv.bat call setinv.bat start