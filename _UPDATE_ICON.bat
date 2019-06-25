@echo off

echo.

set p=%1
set id=%p:~-14%
set id=%id:~0,-5%

echo WORKSHOP ID IS %id%

echo.
echo Uploading Icon
"E:\Games_Steam\steamapps\common\GarrysMod\bin\gmpublish.exe" update -icon %p% -id %id%

pause