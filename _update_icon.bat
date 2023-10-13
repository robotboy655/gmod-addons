@echo off

:: Must have gmad.bat and gmpublish.bat on PATH like so: gmpublish.exe %*

echo.

set p=%1
set id=%p:~-14%
set id=%id:~0,-5%

echo WORKSHOP ID IS %id%

echo.
echo Uploading Icon
call gmpublish update -icon %p% -id %id%

pause