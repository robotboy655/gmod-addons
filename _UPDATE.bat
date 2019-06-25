@echo off

echo.

set p=%1
set id=%p:~-9%

echo WORKSHOP ID IS %id%

echo.
echo Creating GMA
"E:\Games_Steam\steamapps\common\GarrysMod\bin\gmad.exe" create -folder %1 -out %id%.gma

echo.
echo Uploading GMA
"E:\Games_Steam\steamapps\common\GarrysMod\bin\gmpublish.exe" update -addon %id%.gma -id %id%

echo.
echo Deleting GMA
del %id%.gma

pause