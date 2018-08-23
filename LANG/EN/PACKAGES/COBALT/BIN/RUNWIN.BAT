@ECHO OFF
if not exist \WINDOWS\SYSTEM\DOSX.EXE goto error
else
CD \WINDOWS
SYSTEM\DOSX.EXE
CD \
goto end

:error
echo Um, it's embarrassing...
echo Microsoft Windows is not installed.

:end