@ECHO OFF
if not exist \WINDOWS\SYSTEM\DOSX.EXE goto error
else
CD \WINDOWS
SYSTEM\DOSX.EXE
CD \
goto end

:error
echo Hum, c'est embarrassant...
echo Microsoft Windows n'est pas install‚.

:end