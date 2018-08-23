@echo off
break off

set bin=\COBALT\BIN
set ver=1.3

echo Chargement...
echo.
cls

:repair
%bin%\SUSCR.EXE /D " R‚paration de Cobalt %ver% " /M "Appuyer sur ENTREE pour continuer."
echo.
echo  Ce programme est con‡u pour r‚parer une installation existante de Cobalt sur
echo  votre ordinateur. Il copiera le systŠme DOS de base sur le lecteur (pour que
echo  le disque soit d‚marrable), puis remplacera les fichiers systŠmes Cobalt existants
echo  avec ceux de ce CD.
echo.
echo  Ce programme de r‚paration ne supprimera aucune donn‚e utilisateur sur votre lecteur. 
echo  Il r‚pare seulement le dossier systŠme de Cobalt.
echo.
echo.
pause >nul
%bin%\SUSCR.EXE /M "V‚rification des partitions de vos disques durs..."
%bin%\GDISK.EXE 1|%bin%\FIND.EXE "No partitions defined" > nul
if not errorlevel 1 goto error
%bin%\GDISK.EXE 1|%bin%\FIND.EXE " PRI DOS"|%bin%\FIND.EXE "DOS"|%bin%\FIND.EXE "FAT" > nul
if errorlevel 1 goto error
%bin%\GDISK.EXE 1|%bin%\FIND.EXE " PRI DOS"|%bin%\FIND.EXE "C:"|%bin%\FIND.EXE "Unformatted"|%bin%\FIND.EXE "FAT" > nul
if not errorlevel 1 goto error
goto mbr

:chkact
%bin%\SUSCR.EXE /D " R‚paration de Cobalt %ver% "
echo.
echo  Votre disque dur ‚tait vide,
echo  donc une nouvelle partition pour Cobalt a ‚t‚ cr‚‚e.
echo.
%bin%\GDISK.EXE 1|%bin%\FIND.EXE "      PRI DOS"|%bin%\FIND.EXE "C:"|%bin%\FIND.EXE "FAT" > nul
if not errorlevel 1 goto noactdc
goto mbr

:noactdc
%bin%\SUSCR.EXE /D " R‚paration de Cobalt %ver% " /M "Rendre le systŠme de fichiers actifs..."
if errorlevel 1 if not errorlevel 2 %bin%\GDISK.EXE 1 /act /p:1
goto mbr

:mbr
%bin%\SUSCR.EXE /D " R‚paration de Cobalt %ver% " /M "Voulez-vous r‚‚crire la MBR ?" /F "Y/N?"
echo.
echo  La r‚‚criture du Master Boot Record (MBR) de votre disque dur garantira
echo  le d‚marrage correct de Cobalt.
echo.
echo  Si vous utilisez un gestionnaire de d‚marrage personnalis‚ (comme GRUB) 
echo  et que vous souhaitez le conserver, veuillez ne pas r‚ecrire la MBR.
echo  Si vous ne savez pas ce qu'est une MBR ou GRUB, choisissez oui.
echo.
%bin%\CHOICE.EXE > nul
if errorlevel 2 goto mbrconfirm
if not errorlevel 2 goto verifyinstall

:mbrconfirm
%bin%\SUSCR.EXE /D " R‚paration de Cobalt %ver% " /M "R‚‚criture de la MBR..."
%bin%\GDISK.EXE 1 /mbr > nul
goto verifyinstall

:verifyinstall
%bin%\SUSCR.EXE /D " R‚paration de Cobalt %ver% " /M "Recherche du dossier systŠme de Cobalt..."
if exist C:\COBALT\BIN\SMODE.BAT goto fixinstall
if exist C:\COMMAND.COM goto notcobalt
if exist C:\MSDOS.SYS goto notcobalt
if exist C:\KERNEL.SYS goto notcobalt
goto error

:fixinstall
%bin%\SUSCR.EXE /D " R‚paration de Cobalt %ver% " /M "R‚parer Cobalt ." /F "Y/N?"
echo.
echo  L'utilitaire a d‚tect‚ une installation pr‚c‚dente de Cobalt sur ce lecteur.
echo  Elle sera r‚par‚e et mise … niveau vers la version la plus r‚cente de Cobalt
echo  si besoin. Aucune donn‚e utilisateur ne sera supprim‚e.
echo.
echo  Appuyer sur O pour continuer ou N pour annuler.
echo.
%bin%\CHOICE.EXE > nul
if errorlevel 2 goto cancel
%bin%\SUSCR.EXE /D " R‚paration de Cobalt %ver% " /M "Suppression des attributs "cach‚s" sur les fichiers systŠme (le cas ‚ch‚ant)..."
%bin%\ATTRIB.COM -H C:\AUTOEXEC.BAT
%bin%\ATTRIB.COM -H C:\CONFIG.SYS
%bin%\ATTRIB.COM -H C:\KERNEL.SYS
%bin%\SUSCR.EXE /D " R‚paration de Cobalt %ver% " /M "Installation du systŠme de base..."
%bin%\SYS.COM A: C:
%bin%\SUSCR.EXE /D " R‚paration de Cobalt %ver% " /M "Decompressing BASE.ZIP..."
%bin%\UNZIP.exe -o -q BASE.ZIP -d c:\%bin%\SUSCR.EXE /D " Cobalt %ver% Setup " /M "D‚compression de BASE.ZIP..."
%bin%\UNZIP.exe -o -q %zip%\BASE.ZIP -d c:\
%bin%\SUSCR.EXE /D " Cobalt %ver% Setup " /M "D‚compression de EN.ZIP..."
%bin%\UNZIP.exe -o -q %zip%\EN.ZIP -d c:\
if not errorlevel 0 goto error
del c:\COMMAND.COM
goto askdesktop

:askdesktop
%bin%\SUSCR.EXE /D " R‚paration de Cobalt %ver% " /M "Installer l'environment de bureau ?" /F "Y/N?"
echo.
echo  Vous pouvez ‚ventuellement installer un environnement de bureau
echo  nomm‚ OpenGEM, vous n'avez donc pas besoin d'utiliser la ligne de commande.
echo  AprŠs le d‚marrage de Cobalt, vous pouvez simplement taper "GEM" et appuyer sur ENTREE
echo  pour charger le bureau.
echo.
echo  Appuyez sur O pour installer le bureau ou sur N pour ignorer cette ‚tape.
echo.
%bin%\CHOICE.EXE > nul
if errorlevel 2 goto finishsetup
if not errorlevel 2 goto installdesktop

:installdesktop
%bin%\SUSCR.EXE /D " R‚paration de Cobalt %ver% " /M "D‚compression de DESKTOP.ZIP..."
%bin%\UNZIP.exe -u -o -q DESKTOP.ZIP -d c:\
if not errorlevel 0 goto error
goto complete

:complete
%bin%\SUSCR.EXE /D " R‚paration de Cobalt %ver% " /M "Installation termin‚e."
echo.
echo  F‚licitations, votre installation Cobalt a ‚t‚ entiŠrement r‚par‚e.
echo  Veuillez ‚jecter le disque d'installation et appuyez sur ENTREE 
echo  pour red‚marrer votre ordinateur.
echo.
pause >nul
goto reboot

:notcobalt
%bin%\SUSCR.EXE /D " R‚paration de Cobalt %ver% "
echo.
echo  Le programme de r‚paration a trouv‚ un systŠme d?exploitation DOS 
echo  sur le disque interne mais pas le dossier systŠme de Cobalt
echo.
echo  Si vous avez un systŠme d?exploitation DOS existant sur votre disque, 
echo  vous devez d'abord migrer avec le programme d'installation normal.
echo.
echo  La r‚paration ne peut pas continuer, veuillez appuyer sur ENTREE 
echo  pour red‚marrer votre ordinateur.
echo.
pause >nul
goto reboot

:error
%bin%\SUSCR.EXE /D " R‚paration de Cobalt %ver% "
echo.
echo  Le programme de r‚paration n'a pas trouv‚ d'installation de Cobalt … r‚parer.
echo.
echo  La r‚paration ne peut pas continuer, veuillez appuyer sur ENTREE 
echo  pour red‚marrer votre ordinateur.
echo.
pause >nul
goto reboot

:reboot
cls
A:\DRIVERS\FDAPM WARMBOOT
cls
