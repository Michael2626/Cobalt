@echo off
break off

set bin=\COBALT\BIN
set zip=\COBALT\ZIP
set ver=1.3

echo Chargement...
echo.
cls

:setup
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "Appyer sur ENTREE pour continuer."
echo.
echo  Cobalt est un nouveau systŠme d'exploitation bas‚ sur FreeDOS.
echo  Contrairement … FreeDOS, Cobalt est con‡u pour ˆtre facilement utilis‚
echo  par des personnes n'ayant jamais utilis‚ un systŠme DOS.
echo.
echo  Cobalt est en d‚veloppement, donc si vous rencontrez des problŠmes,
echo  merci de rapporter les bugs … l'addresse suivante :
echo  https://github.com/Atnode/Cobalt/issues.
echo.
echo  Ce programme installera Cobalt sur le disque de votre ordinateur. Si vous
echo  avez d‚j… FreeDOS, MS-DOS, etc... sur votre ordinateur, vous pouvez
echo  mettre … jour vers Cobalt.
echo.
pause >nul
%bin%\SUSCR.EXE /M "V‚rification des partitions de vos disques durs..."
%bin%\GDISK.EXE 1|%bin%\FIND.EXE "No partitions defined" > nul
if not errorlevel 1 goto invdc
%bin%\GDISK.EXE 1|%bin%\FIND.EXE " PRI DOS"|%bin%\FIND.EXE "DOS"|%bin%\FIND.EXE "FAT" > nul
if errorlevel 1 goto nofatdc
%bin%\GDISK.EXE 1|%bin%\FIND.EXE " PRI DOS"|%bin%\FIND.EXE "C:"|%bin%\FIND.EXE "Unformatted"|%bin%\FIND.EXE "FAT" > nul
if not errorlevel 1 goto nofmtdc
goto chkact

:invdc
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "Voulez-vous formater le disque dur ?" /F "O/N?"
echo.
echo  Le lecteur principal n'est pas format‚. Voulez-vous l'utiliser avec Cobalt ?
echo.
echo  AVERTISSEMENT : cela effacera toutes les donn‚es.
echo  Assurez-vous de sauvegarder toutes les donn‚es
echo  importantes avant le formatage.
echo.
%bin%\%bin%\CHOICE.EXE > nul
if errorlevel 2 goto cancel
if not errorlevel 2 %bin%\SUSCR.EXE /M "Formatage du disque dur..."|%bin%\GDISK.EXE 1 /cre /pri /for /q /v:COBALT > nul
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% "
echo.
echo  Le formatage a ‚t‚ r‚ussi.
echo.
echo  Veuillez appuyer sur ENTREE pour red‚marrer votre ordinateur 
echo  pour que les modifications s'appliquent, puis red‚marrez 
echo  l'installateur encore une fois.
echo.
pause > nul
goto reboot

:nofatdc
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% "
echo.
echo  Il n'y a pas de systŠme de fichiers FAT primaire sur votre disque dur,
echo  ou vos disques ne sont pas d‚tect‚s.
echo.
echo  L'installation ne peut pas continuer.
echo  Merci d'appyuer sur ENTREE pour red‚marrer votre ordinateur.
echo.
goto loop

:nofmtdc
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "Voulez-vous utiliser la partition primaire avec Cobalt ?" /F "O/N?"
echo.
echo  La partition principale n'est pas format‚e. Voulez-vous l'utiliser avec Cobalt ?
echo.
%bin%\CHOICE.EXE > nul
if errorlevel 2 goto cancel
if not errorlevel 2 %bin%\SUSCR.EXE /M "Formatage du disque dur..."|%bin%\FORMAT.EXE c: /z:seriously /v:COBALT /s /y|goto ready

:chkact
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% "
echo.
echo  Votre disque dur ‚tait vide,
echo  donc une nouvelle partition pour Cobalt a ‚t‚ cr‚‚e.
echo.
%bin%\GDISK.EXE 1|%bin%\FIND.EXE "      PRI DOS"|%bin%\FIND.EXE "C:"|%bin%\FIND.EXE "FAT" > nul
if not errorlevel 1 goto noactdc
goto mbr

:noactdc
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "Rendre le systŠme de fichiers actifs..."
if errorlevel 1 if not errorlevel 2 %bin%\GDISK.EXE 1 /act /p:1
goto mbr

:mbr
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "Voulez-vous r‚‚crire la MBR ?" /F "O/N?"
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
if not errorlevel 2 goto oscheck

:mbrconfirm
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "R‚‚criture de la MBR..."
%bin%\GDISK.EXE 1 /mbr > nul
goto oscheck

:oscheck
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "V‚rification des systŠmes d'exploitation install‚s..."
if exist C:\SYSTEM\4DOS\4DOS.INI goto upgradecobalt
if exist C:\COMMAND.COM goto upgradedos
if exist C:\MSDOS.SYS goto upgradedos
if exist C:\KERNEL.SYS goto upgradedos
goto freshinstall

:upgradecobalt
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "Installer Cobalt dans le lecteur C: ?" /F "O/N?"
echo.
echo  L'installateur a d‚tect‚ une installation pr‚c‚dente d'Cobalt
echo  sur ce lecteur. Il sera mis … niveau vers la version actuelle.
echo.
echo  Le dossier Cobalt pr‚c‚dent sera supprim‚ et remplac‚ par
echo  … un nouveau dossier Cobalt.
echo.
echo  Appuyez sur O pour commencer l'installation, ou N pour annuler.
echo.
%bin%\CHOICE.EXE > nul
if errorlevel 2 goto cancel
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "Deleting previous Cobalt installation..."
%bin%\DELTREE.COM /Y /Z:SERIOUSLY C:\SYSTEM
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "Suppression des attributs "cach‚s" sur les fichiers systŠme (le cas ‚ch‚ant)..."
%bin%\ATTRIB.COM -H C:\AUTOEXEC.BAT
%bin%\ATTRIB.COM -H C:\CONFIG.SYS
%bin%\ATTRIB.COM -H C:\KERNEL.SYS
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "Installation de la base du systŠme..."
%bin%\SYS.COM A: C:
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "D‚compression de  BASE.ZIP..."
%bin%\UNZIP.exe -o -q %zip%\BASE.ZIP -d c:\
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "D‚compression de FR.ZIP..."
%bin%\UNZIP.exe -o -q %zip%\FR.ZIP -d c:\
if not errorlevel 0 goto error
del c:\COMMAND.COM
goto askdesktop

:upgradedos
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "Installer Cobalt dans le lecteur C: ?" /F "O/N?"
echo.
echo  Ce programme d'installation a d‚tect‚ une installation pr‚c‚dente d'un
echo  systŠme d'exploitation bas‚ sur DOS, tel que FreeDOS ou MS-DOS.
echo.
echo  Cobalt renomera AUTOEXEC.BAT et CONFIG.SYS
echo  en AUTOEXEC.OLD et CONFIG.OLD, respectivement.
echo  Aucun autres fichiers seront modifi‚s.
echo.
echo  Appuyez sur O pour commencer l'installation, ou N pour annuler.
echo.
%bin%\CHOICE.EXE > nul
if errorlevel 2 goto cancel
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "Renommage des fichiers DOS existants..."
%bin%\ATTRIB.COM -H C:\AUTOEXEC.BAT
%bin%\ATTRIB.COM -H C:\CONFIG.SYS
COPY C:\CONFIG.SYS C:\CONFIG.OLD
COPY C:\AUTOEXEC.BAT C:\AUTOEXEC.OLD
DEL C:\CONFIG.SYS
DEL C:\AUTOEXEC.BAT
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "Installation de la base du systŠme..."
%bin%\SYS.COM A: C:
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "D‚compression de  BASE.ZIP..."
%bin%\UNZIP.exe -o -q %zip%\BASE.ZIP -d c:\
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "D‚compression de FR.ZIP..."
%bin%\UNZIP.exe -o -q %zip%\FR.ZIP -d c:\
if not errorlevel 0 goto error
del c:\COMMAND.COM
goto askdesktop

:freshinstall
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "Installer Cobalt ?" /F "O/N?"
echo.
echo  Cobalt is now ready to install to the C: drive.
echo  THIS WILL DELETE ALL FILES ON THE C: DRIVE.
echo.
echo  Press Y to begin the install, or N to cancel.
echo.
%bin%\CHOICE.EXE > nul
if errorlevel 2 goto cancel
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "Installation de la base du systŠme..."
%bin%\FORMAT.EXE c: /z:seriously /v:COBALT /s /y
if not errorlevel 0 goto error
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "D‚compression de  BASE.ZIP..."
%bin%\UNZIP.exe -o -q %zip%\BASE.ZIP -d c:\
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "D‚compression de FR.ZIP..."
%bin%\UNZIP.exe -o -q %zip%\FR.ZIP -d c:\
if not errorlevel 0 goto error
del c:\COMMAND.COM
goto askdesktop

:askdesktop
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "Installer l'environment de bureau ?" /F "O/N?"
echo.
echo  Vous pouvez ‚ventuellement installer un environnement de bureau
echo  nomm‚ OpenGEM, vous n'avez donc pas besoin d'utiliser la ligne de commande.
echo  AprŠs le d‚marrage de Cobalt, vous pouvez simplement taper "GEM" et appuyer sur ENTREE
echo  pour charger le bureau.
echo.
echo  Appuyez sur O pour installer le bureau ou sur N pour ignorer cette ‚tape.
echo.
%bin%\CHOICE.EXE > nul
if errorlevel 2 goto complete
if not errorlevel 2 goto installdesktop

:installdesktop
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "D‚compression de DESKTOP.ZIP..."
%bin%\UNZIP.exe -o -q DESKTOP.ZIP -d c:\
if not errorlevel 0 goto error
goto complete

:complete
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% " /M "Installation termin‚e."
echo.
echo  F‚licitation ! Cobalt a ‚t‚ install‚ sur votre ordinateur.
echo  Veuillez ‚jecter le m‚dia d'installation et appuyer sur la
echo  touche ENTREE pour red‚marrer votre ordinateur.
pause >nul
goto reboot

:error
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% "
echo.
echo  Une erreur est survenue.
echo  Merci de red‚marrer votre ordinateur en appuyant sur ENTREE.
echo.
pause >nul
goto reboot

:cancel
%bin%\SUSCR.EXE /D " Installation de Cobalt %ver% "
echo.
echo  L'installation de Cobalt a ‚t‚ annul‚e.
echo  Merci d'appuyer sur ENTREE afin de red‚marrer 
echo  votre ordinateur.
echo.
pause >nul
goto reboot

:reboot
cls
A:\DRIVERS\FDAPM WARMBOOT
cls
