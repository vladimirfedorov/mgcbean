@echo off
for %%i in ("%cd%") do set dirname=%%~ni%%~xi
set relver=0.1
:getver
set /P relver=Version number: %=%
if "%relver%"=="" goto getver

set hour=%time:~0,2%
if "%hour:~0,1%" == " " (set hour=0%time:~1,1%)
set subver=%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%%hour%%TIME:~3,2%%TIME:~6,2%
set fullver=%subver%.v%relver%
set outdir=..\..\..\release\%dirname%\%relver%
if not exist %outdir% mkdir %outdir%
set sources=%outdir%\sources.zip
set imgfile=%outdir%\%dirname%.img.zip
pkzipc -add -dir=current -lev=9 -excl=!* -excl=*.com -excl=*.img -excl=kernel -excl=*.bin %sources% 
pkzipc -add -dir=current -lev=9 -excl=!* %imgfile% *.img
