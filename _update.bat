@echo off

:: Must have gmad.bat and gmpublish.bat on PATH like so: gmpublish.exe %*

echo.

set p=%1
set id=%p:~-9%

echo WORKSHOP ID IS %id%

echo.
echo Creating GMA
call gmad create -folder %cd% -out %id%.gma -quiet

echo.
echo Uploading GMA
call gmpublish update -addon %id%.gma -id %id%

echo.
echo Deleting GMA
del %id%.gma

pause