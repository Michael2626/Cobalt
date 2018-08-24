@ECHO OFF

:: check argument
if "%1"=="" goto noarg
if "%1"=="en" (
set cobaltlang=en
) else if "%1"=="fr" (
set cobaltlang=fr
) else (
goto errorarg
)


SET NAME=Cobalt ISO
SET PUBLISHER=Atnode
SET TITLE=Cobalt Live CD
SET VER=1.3
SET DIR=%~dp0

CD %DIR%


:: check for mkisofs

if exist MKISOFS.EXE (
    echo [ OK ] Mkisofs executable found in %DIR%
) else (
    echo [EROR] Mkisofs executable not found, please make sure it's in the same folder as this compiler.
    pause
    exit
)

:: check for 7za
if exist 7ZA.EXE (
    echo [ OK ] 7-zip executable found in %DIR%
) else (
    echo [EROR] 7-Zip executable not found, please make sure it's in the same folder as this compiler.
    pause
    exit
)

:: compile base.zip
if exist CDROOT\COBALT\ZIP\BASE.ZIP (
    del CDROOT\COBALT\ZIP\BASE.ZIP
    echo [ OK ] Deleting existing BASE.ZIP file.
)
cd PKG\base
..\..\7za a ..\..\CDROOT\COBALT\ZIP\BASE.ZIP *
cd ..\..\

:: compile desktop.zip
if exist CDROOT\COBALT\ZIP\DESKTOP.ZIP (
    del CDROOT\COBALT\ZIP\DESKTOP.ZIP
    echo [ OK ] Deleting existing DESKTOP.ZIP file.
)
cd PKG\desktop
..\..\7za a ..\..\CDROOT\COBALT\ZIP\DESKTOP.ZIP *
cd ..\..\

if "%cobaltlang%"=="fr" (
goto frbuild 
) else if "%cobaltlang%"=="en" (
goto enbuild
)

:frbuild
SET FILE=Cobalt-%VER%-FR.iso
:: compile fr.zip
if exist CDROOT\COBALT\ZIP\FR.ZIP (
    del CDROOT\COBALT\ZIP\FR.ZIP
    echo [ OK ] Deleting existing FR.ZIP file.
)
cd LANG\FR\PKG
..\..\..\7za a ..\..\..\CDROOT\COBALT\ZIP\FR.ZIP *
cd ..\..\..\

:: copy the french installer files
if exist CDROOT\COBALT\SETUP.BAT (
    del CDROOT\COBALT\SETUP.BAT
    echo [ OK ] Deleting existing SETUP.BAT file.
) else if exist CDROOT\COBALT\REPAIR.BAT (
    del CDROOT\COBALT\REPAIR.BAT
    echo [ OK ] Deleting existing REPAIR.BAT file.
)

cd LANG\FR\BAT
copy *.BAT ..\..\..\CDROOT\COBALT\
cd ..\..\..\

:: copy the french bootdisk
if exist CDROOT\ISOLINUX\BTDSK.IMG (
    del CDROOT\ISOLINUX\BTDSK.IMG
    echo [ OK ] Deleting existing BTDSK.IMG file.
)

cd LANG\FR\ISOLINUX
copy *.IMG ..\..\..\CDROOT\ISOLINUX\
cd ..\..\..\
goto files

:enbuild
SET FILE=Cobalt-%VER%-EN.iso
:: compile en.zip
if exist CDROOT\COBALT\ZIP\EN.ZIP (
    del CDROOT\COBALT\ZIP\EN.ZIP
    echo [ OK ] Deleting existing EN.ZIP file.
)

cd LANG\EN\PKG
..\..\..\7za a ..\..\..\CDROOT\COBALT\ZIP\EN.ZIP *
cd ..\..\..\

:: copy the english installer files
if exist CDROOT\COBALT\SETUP.BAT (
    del CDROOT\COBALT\SETUP.BAT
    echo [ OK ] Deleting existing SETUP.BAT file.
) else if exist CDROOT\COBALT\REPAIR.BAT (
    del CDROOT\COBALT\REPAIR.BAT
    echo [ OK ] Deleting existing REPAIR.BAT file.
)

cd LANG\EN\BAT
copy *.BAT ..\..\..\CDROOT\COBALT\
cd ..\..\..\


:: copy the english bootdisk
if exist CDROOT\ISOLINUX\BTDSK.IMG (
    del CDROOT\ISOLINUX\BTDSK.IMG
    echo [ OK ] Deleting existing BTDSK.IMG file.
)

cd LANG\EN\ISOLINUX
copy *.IMG ..\..\..\CDROOT\ISOLINUX\
cd ..\..\..\
goto files

:: check for files
:files
if exist %FILE% (
    del %FILE%
    echo [ OK ] Deleting existing %FILE% file.
)

echo [ OK ] Now compiling...
mkisofs -quiet -o "%FILE%" -p "%NAME%" -publisher "%PUBLISHER%" -V "%TITLE%" -b ISOLINUX/ISOLINUX.BIN -no-emul-boot -boot-load-size 4 -boot-info-table -N -J -r -c boot.catalog -hide boot.catalog -hide-joliet boot.catalog CDROOT
echo [ OK ] Compile finished
goto end

:: if there is no argument
:noarg
echo You must specify a language as an argument. (EN, FR)
goto end

:: if the argument is incorrect
:errorarg
echo "%1" isn't a correct argument.
echo You must specify a language as an argument. (EN, FR)
goto end

:end
